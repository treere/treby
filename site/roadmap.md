# Roadmap

> **Stella polare**: semplicità alla Notion, ma pensata per le assunzioni.
> Per piccole aziende e startup (5–50 persone, 1–10 posizioni aperte alla volta).

## Stato attuale

Treby è completo come sostituto di un ATS per una singola azienda. Le funzionalità principali sono già disponibili; ciò che resta è rifinitura, non capacità di base.

| Funzionalità | Stato |
|---|---|
| Architettura multi-azienda | ✅ Completa |
| Pipeline multiple per azienda + modelli | ✅ Completa |
| Pipeline Kanban (drag & drop, tempo reale) | ✅ Completa |
| Pagina carriere pubblica con branding | ✅ Completa |
| Auto-prenotazione colloqui nel portale + link meeting (Google Meet / Jitsi) | ✅ Completa |
| Integrazione Google Calendar (opzionale; calendario interno sempre attivo) | ✅ Completa |
| Regole di disponibilità + sovrapposizione multi-esaminatore | ✅ Completa |
| Campi personalizzati per candidato/posizione/candidatura | ✅ Completa |
| Note con valutazioni a stelle | ✅ Completa |
| Upload CV e loghi su S3 | ✅ Completa |
| Email (solo codici OTP e avvisi brevi) | ✅ Completa |
| Inviti team e permessi per ruolo | ✅ Completa |
| Traduzioni (inglese/italiano) | ✅ Completa |
| Landing page | ✅ Completa |
| Dashboard con "Le mie azioni", candidature ferme, prossimi colloqui, attività | ✅ Completa |
| Ricerca e filtri candidati | ✅ Completa |
| Modifica candidati | ✅ Completa |
| Stato di lettura candidature (badge NUOVO) | ✅ Completa |
| Timeline attività | ✅ Completa |
| Controllo accessi per ruolo (admin/membro + esaminatore/revisore/avanzatore) | ✅ Completa |
| Schede di valutazione + blocco avanzamento | ✅ Completa |
| Modelli di messaggio per fase | ✅ Completa |
| Selettore pipeline in Analytics | ✅ Completa |
| Metriche di permanenza per fase | ✅ Completa |
| Tracciamento sorgenti | ✅ Completa |
| Importazione CSV | ✅ Completa |
| Operazioni massive (bulk) | ✅ Completa |
| Confronto candidati (2–3 affiancati) | ✅ Completa |
| Comunicazioni portal-first (OTP, conversazioni, avvisi) | ✅ Completa |
| Programmazione messaggi (jitter, ritentativi, coda) | ✅ Completa |
| Rilevamento duplicati e unione | ✅ Completa |
| Tema scuro (chiaro/scuro/sistema) | ✅ Completa |

## Cosa resta (rifinitura)

- Rigenerazione screenshot per le nuove pagine
- Possibili migliorie future: export analytics, notifiche più granulari, filtri salvati, gestione lettere di offerta

Sono volutamente rimandate — vedi "Cosa non costruiremo" sotto.

## Piano originale in fasi (già realizzato)

### Fase 1: "Posso usarlo ogni giorno" — ✅ completata

- Dashboard con azioni da fare, prossimi colloqui, candidature ferme
- Ricerca per nome/email e filtri per posizione/fase
- Modifica diretta dei dati candidato
- Stato letto/non letto con badge
- Cronologia attività

### Fase 2: "Anche il mio team vuole usarlo" — ✅ completata

- Permessi admin vs membro + ruoli per fase (esaminatore/revisore/avanzatore)
- Schede di valutazione strutturate
- Modelli di messaggio per fase nel portale
- Selettore pipeline in Analytics
- Tempo medio di permanenza per fase

### Fase 3: "Sostituisce il vecchio ATS" — ✅ completata

- Importazione CSV con mappatura colonne
- Operazioni massive su più candidature
- Confronto affiancato tra candidati
- Tracciamento sorgenti con breakdown in Analytics
- Comunicazioni portal-first (contenuti nel portale, email solo come avviso)

## Cosa non costruiremo

- Valutazione candidati con AI
- Video-colloqui proprietari (usiamo link automatici Google Meet o Jitsi)
- Gestione lettere di offerta
- Workflow di onboarding
- Catene di approvazione complesse
- SSO/SAML
- App mobile (l'app web è già responsive)
- Integrazioni con job board esterne (costose e poco utili all'inizio)
