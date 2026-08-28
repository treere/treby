## 1. OTP Auth

- [x] 1.1 Migrazione: creare tabella `candidate_otps` (code hash, candidate_id, tenant_id, expires_at, attempts, used_at)
- [x] 1.2 `Treby.CandidatePortal`: funzioni `generate_otp/1`, `verify_otp/3`, invalidazione OTP candidate, cooldown/rate limit sulla richiesta (60s)
- [x] 1.3 Email builder OTP (`otp_email`) con codice, scadenza 10 min e link alla pagina di verifica
- [x] 1.4 Pagina di verifica `/:tenant_slug/portal/verify` (LiveView con form a 6 cifre, resend, errori generici)
- [x] 1.5 Aggiornare il POST `/portal/login` per generare/inviare OTP (al posto del magic link); rimuovere `MagicLinkController` e rotta `GET /portal/c/:token`
- [x] 1.6 Sessione: scrivere `candidate_expires_at` al login (default 4h, configurabile); verifica scadenza nel plug `CandidateAuth`
- [x] 1.7 Logout: rotta `DELETE /:tenant_slug/portal/logout`, bottone nel layout `candidate_portal`, pulizia sessione
- [x] 1.8 Test: flusso OTP completo (richiesta, verifica, scadenza, tentativi esauriti, enumeration, logout, sessione scaduta)

## 2. Template messaggi e colloqui nel portal

- [x] 2.1 Rinomare/adattare `EmailTemplate` in template di messaggio (body come messaggio, subject come subject conversazione); UI settings aggiornata
- [x] 2.2 Flusso stage move: dialog con anteprima template e opzioni Send now / Schedule / Skip; messaggio postato nella conversazione dell'applicazione
- [x] 2.3 Dettagli colloquio come messaggio del portal (data, ora, intervistatore, meet link) in `interviews.ex`; rimozione email candidate/examiner
- [x] 2.4 Self-scheduling nel portal: pagina `/:tenant_slug/portal/schedule` (slot da disponibilità, conferma, aggiornamento evento/pipeline); rimozione rotte e token pubblici

## 3. Messaggi programmati

- [x] 3.1 Migrazione: tabella `scheduled_messages` (campi messaggio + send_at + status + conversation_id)
- [x] 3.2 Context `Treby.ScheduledMessages` + worker Oban `SendScheduledMessage` (stesso ciclo retry/backoff di SendScheduledEmail)
- [x] 3.3 Pagina `/app/messages-queue` (da `/app/email-queue`) con tab Posted/Failed/Cancelled, edit, cancel, force-send, retry, bulk
- [x] 3.4 Messaggi bulk: composer bulk → messaggi/conversazioni per ogni candidato selezionato (immediato o programmato, con jitter)

## 4. Rimozione canale email candidato

- [x] 4.1 Rimuovere email builder: `magic_link_email`, `booking_link_candidate`, `interview_scheduled_candidate/interviewer`, `new_application_*` (team), `new_application_confirmation`; unificare i ping in `notification_ping` (link al login portal)
- [x] 4.2 Rimuovere `EmailThreads`, `EmailQueue`/`ScheduledEmail`, worker `SendScheduledEmail`, `EmailWebhookController` e rotta `/webhooks/inbound`
- [x] 4.3 Rimuovere UI: tab Email nei profili candidato, composer/reply email, pagina email queue, rotta `EmailQueueLive`
- [x] 4.4 Migrazione: drop tabelle `email_threads`, `email_messages`, `scheduled_emails`, `candidate_tokens`, `booking_tokens`
- [x] 4.5 Notifiche team in-app: eventi activity log per nuova applicazione e intervista schedulata; feed MVP nel dashboard

## 5. Ping email candidato

- [x] 5.1 Standardizzare `notification_ping`: testo breve + bottone "Vedi nel pannello" verso `/:tenant_slug/portal`, rispetta preferenze candidato
- [x] 5.2 Attivare ping su: nuova applicazione (welcome), stage change, nuovo messaggio, aggiornamento colloquio; logging activity per invio/fallimento

## 6. Pulizia e verifica

- [x] 6.1 Aggiornare spec/funzionalità documentate nel sito (`site/features/`) e rigenerare screenshot se necessario
- [x] 6.2 Test completi per: auth OTP, conversazioni con template e programmazione, self-scheduling, rimozioni (nessun riferimento a moduli email rimossi)
- [x] 6.3 `mix precommit` senza errori e aggiornare la documentazione del sito