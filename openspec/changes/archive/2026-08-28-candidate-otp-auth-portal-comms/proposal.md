## Why

Le comunicazioni oggi sono divise tra il portal in-app e email a contenuto pieno (dettagli colloquio, template stage, compose/reply, webhook inbound). L'accesso al portal usa un magic link con token nell'URL. Vogliamo che tutte le comunicazioni vivano nel portal, con l'email usata solo per il login OTP e per ping di notifica che rimandano al pannello. L'accesso passa da magic link a un flusso OTP via email, con sessione a durata limitata e logout esplicito.

## What Changes

- **BREAKING** Login candidato sostituito da flusso OTP: richiesta email → invio OTP via email → verifica codice → sessione di qualche ora.
- **BREAKING** Rimosso il meccanismo magic link (rotta `/:tenant_slug/portal/c/:token`, tabella `candidate_tokens`).
- La sessione candidato ha durata limitata (qualche ora) e il portal offre logout esplicito.
- **BREAKING** Tutte le comunicazioni col candidato si spostano in-app (conversazioni/messaggi del portal). L'email diventa solo notifica: ping breve "è successo qualcosa" + link per accedere al pannello.
- **BREAKING** Colloqui: le email candidate/examiner spariscono; il candidato riceve un ping + i dettagli nel portal, il team riceve notifiche in-app.
- **BREAKING** Il self-scheduling si sposta dentro il portal autenticato; rimosso il booking link pubblico `/:tenant_slug/schedule/:token`.
- **BREAKING** Le email stage (template) diventano template di messaggi del portal; il contenuto viaggia in una conversazione.
- **BREAKING** Rimossa l'email bidirezionale (webhook inbound, thread compose/reply, pagina email queue).
- **BREAKING** Lo scheduling email diventa scheduling di messaggi del portal (invio programmato).
- **BREAKING** Le email bulk verso candidati diventano messaggi bulk del portal.
- **BREAKING** Le email al team (nuova applicazione, interviewer) vengono rimosse; le notifiche al team vivono in-app (activity log/UI interna).
- Nessuna retrocompatibilità: il portal è l'unico canale di comunicazione col candidato; niente fallback email per tenant senza portal.

## Capabilities

### New Capabilities
- `candidate-otp-auth`: Login passwordless OTP per il portal candidato (richiesta via email, generazione/invio OTP, verifica con protezione da enumeration e brute force), sessione a durata limitata, e logout.

### Modified Capabilities
- `candidate-magic-link`: rimosso, sostituito da `candidate-otp-auth`. **BREAKING**
- `email-notifications`: le email di notifica candidato diventano ping brevi con link al pannello; le email di alert al team sono rimosse (in-app). **BREAKING**
- `career-page`: l'email di conferma applicazione diventa un ping; la welcome conversation + accesso OTP sostituiscono l'email magic link.
- `interview-scheduling`: le email candidate/examiner sono sostituite da notifiche in-app; il candidato riceve un ping con link al portal.
- `candidate-self-scheduling`: la prenotazione avviene nel portal autenticato; rimossi token e pagina pubblici. **BREAKING**
- `candidate-booking-email`: rimossa (superseded da self-scheduling in-app). **BREAKING**
- `bidirectional-email`: rimossa (webhook inbound, thread compose/reply rimossi). **BREAKING**
- `stage-email-templates`: diventano template di messaggi consegnati via conversazioni del portal. **BREAKING**
- `email-scheduler`: programma messaggi del portal anziché email. **BREAKING**
- `candidate-conversations`: acquisisce invio di messaggi con template e consegna programmata.
- `bulk-operations`: le email bulk diventano messaggi bulk del portal. **BREAKING**

## Impact

- **Auth**: `Treby.CandidatePortal`, `CandidateToken`, `MagicLinkController`, `Plugs.CandidateAuth`, `CandidatePortalLive.RequestLink`, rotte router.
- **Email**: `Notifications.Email`, `SchedulingEmail`, `EmailTemplates`, `EmailThreads`/`EmailQueue`, `EmailWebhookController`, webhook route.
- **DB**: nuove tabelle/migrazioni per codici OTP e messaggi programmati; rimozione/deprecazione di `candidate_tokens` e `booking_tokens`.
- **UI portal**: schermata di verifica OTP, bottone logout, prenotazione colloquio in-app, visualizzazione messaggi con template.
- **UI team**: rimozione tab Email dai profili candidato, pagina email queue, composer email; aggiunta notifiche in-app al team (sopra l'activity log esistente).
- **Notifiche team**: nuova superficie in-app per alert a recruiter/admin basata sull'activity log esistente.