## Context

Treby è un ATS multi-tenant Phoenix/LiveView. Oggi le comunicazioni col candidato sono divise: un portal in-app (conversazioni/messaggi) e un canale email pieno (magic link, ping di notifica, dettagli colloquio, template stage, thread compose/reply con webhook inbound, email queue con scheduling Oban). L'accesso al portal avviene via magic link (`/:tenant_slug/portal/c/:token`, tabella `candidate_tokens`, 15 min, single-use) e la sessione è un cookie Phoenix senza scadenza dedicata e senza logout candidato.

L'obiettivo è convergere su un unico canale: il portal. L'email resta solo per (1) il login OTP e (2) ping di notifica opzionali con link al pannello. Nessuna retrocompatibilità: il portal è l'unico canale.

## Goals / Non-Goals

**Goals:**
- Login OTP via email (richiesta → codice → verifica) con protezione da enumeration e brute force.
- Sessione candidato a durata limitata (configurabile, default poche ore) e logout esplicito.
- Tutto il contenuto comunicativo vive nelle conversazioni del portal (inclusi template stage e dettagli colloquio).
- Self-scheduling dentro il portal autenticato.
- Scheduling di messaggi del portal (in sostituzione dello scheduling email).
- Notifiche al team solo in-app.
- Rimozione pulita di email bidirezionale, booking link, email queue.

**Non-Goals:**
- Nessuna email a contenuto pieno verso candidati o team (escluso l'OTP, che per natura contiene il codice).
- Nessun fallback email per tenant senza portal: il portal è sempre attivo.
- Niente password candidato (il fallback "Accedi con la password" di IKEA non è previsto).
- Fuori scope: notifiche push, real-time team feed oltre un MVP su activity log.

## Decisions

### D1 — OTP: nuova tabella `candidate_otps`, hash SHA-256, single-use
Tabella dedicata (`candidate_otps`): `code` (hash), `candidate_id`, `tenant_id`, `expires_at`, `attempts`, `used_at`. Codice numerico a 6 cifre da `:crypto` (`Enum.random`/`:rand` su range 100000–999999), hashato con SHA-256 prima dello store, mai loggato. Scadenza 10 min, single-use (`used_at`), max 5 tentativi di verifica (oltre: codice invalidato, richiesta nuovo). Alla verifica riuscita, tutti gli OTP del candidato vengono invalidati.
*Alternativa considerata*: riusare `candidate_tokens` con un campo `purpose`. Scartata perché la tabella è mono-scopo (magic link) e verrà rimossa; una tabella OTP dedicata è più chiara e isolata.

### D2 — Sessione a durata limitata via timestamp nel cookie, verificato dal plug
Il cookie Phoenix è condiviso tra admin e candidato (`_treby_key`): un `max_age` globale colpirebbe le sessioni admin. Scelta: al login OTP si scrive nel cookie `candidate_id`, `candidate_tenant_id` e `candidate_expires_at = now + durata`. Il plug `CandidateAuth` verifica il timestamp a ogni richiesta; se scaduto, pulisce la sessione e redirige al login. Durata configurabile (env/app), default 4 ore.
*Alternativa considerata*: sessione server-side revocabile (tabella `candidate_sessions`). Più robusta (revoca immediata, "logout all devices") ma più complessa; la scadenza nel cookie soddisfa il requisito "qualche ora" con scadenza verificata server-side.

### D3 — Logout candidato: rotta `DELETE` + bottone nel layout
Rotta `DELETE /:tenant_slug/portal/logout` che rimuove `candidate_id`/`candidate_tenant_id`/`candidate_expires_at` dalla sessione e redirige al login portal. Bottone nel layout `candidate_portal` accanto al nome candidato.

### D4 — Email = solo OTP e ping candidato
Due soli costruttori email restano: `otp_email` (codice + link alla pagina di verifica) e `notification_ping` (testo breve "qualcosa è successo" + bottone "Vedi nel pannello" che punta al login portal, mai a contenuto diretto). Tutti gli altri costruttori (`magic_link_email`, `new_application_confirmation`, `new_application_team_alert`, `interview_scheduled_*`, `booking_link_candidate`, template stage, thread compose/reply) vengono rimossi. Il ping rispetta le preferenze candidato esistenti (`new_message`, `status_change`, `interview_update`, `important_only`).

### D5 — Contenuto colloquio e self-scheduling nel portal
I dettagli colloquio (data, ora, intervistatore, meet link) diventano un messaggio di sistema/conversazione nel portal. Il self-scheduling diventa una pagina del portal autenticato (`/:tenant_slug/portal/schedule`): il candidato vede le disponibilità per la propria applicazione e prenota. `booking_tokens`, la rotta pubblica `/schedule/:token` e `candidate-booking-email` spariscono.

### D6 — Template stage → template di messaggi, con scheduling
`EmailTemplate` viene riutilizzato/rinominato come template di messaggio: le stesse variabili (`{candidate_name}`, `{job_title}`, ecc.) vengono renderizzate come corpo di un messaggio inviato in una conversazione esistente (o creata). Nuova tabella `scheduled_messages` per la consegna programmata (stesso pattern di `scheduled_email` ma verso una conversazione): campi messaggio + `send_at` + `status` (scheduled/sent/cancelled) + worker Oban `SendScheduledMessage` che inserisce il `Message` e aggiorna la conversazione. La pagina `/app/email-queue` diventa `/app/messages-queue` (stesse interazioni: send now, edit, cancel, retry, bulk).

### D7 — Notifiche team in-app sull'activity log
L'activity log esiste già (`Activities.log_event`, tenant-scoped). Le notifiche oggi via email (nuova applicazione per admin/owner, intervista per examiner) vengono loggate come eventi e mostrate in una superficie in-app MVP (feed nel dashboard / sezione dedicata). Nessuna tabella nuova per il team al momento.

### D8 — Rimozione email bidirezionale
Rimozione completa: `EmailThreads`, `EmailQueue`/`ScheduledEmail`, `EmailWebhookController` e rotta `/webhooks/inbound`, tab `Email` nei profili candidato, feature compose/reply. Migrazione: eliminazione tabelle `email_threads`, `email_messages`, `scheduled_emails` (non retrocompatibile, ok).

## Risks / Trade-offs

- **OTP è più friction del magic link** (due passaggi, digitare il codice) → Mitigazione: login in 2 schermate semplici come IKEA, auto-focus sul primo digit, resend con rate limit.
- **Enumeration/brute force su OTP** → Mitigazione: messaggio generico a prescindere dall'esistenza dell'email; tentativi limitati (5); rate limit sulla richiesta (cooldown ~60s per email/candidato); codice hashato.
- **Email non consegnata = candidato bloccato** → Mitigazione: resend; messaggio di errore generico con possibilità di riprovare; OTP scaduto ricrea flusso.
- **Self-scheduling nel portal richiede login** → Candidati senza email o che non leggono l'email non prenotano → Mitigazione: il ping email spiega come accedere; il recruiter può comunque programmare manualmente.
- **Scheduling messaggi = nuovo worker/UI** → Mitigazione: riuso del pattern Oban esistente di `SendScheduledEmail` (stesso ciclo retry/backoff), quindi rischio contenuto.
- **Notifiche team in-app possono perdersi** (nessuna email) → Mitigazione: MVP sul dashboard; valutare un feed notifiche dedicato in un secondo momento (fuori scope).
- **Perdita dati con rimozione tabelle email** → Mitigazione: accettato (non retrocompatibile); i thread email non vengono migrati nelle conversazioni del portal.

## Open Questions

- Durata esatta sessione candidato (default 4h? configurabile per tenant?).
- Il ping email per i dettagli colloquio: si include il meet link nel ping o solo "hai un aggiornamento"? (La filosofia "email=notifica" suggerisce solo notifica, ma il meet link è operativo.)
- Il feed notifiche team: MVP su dashboard vs sezione dedicata.