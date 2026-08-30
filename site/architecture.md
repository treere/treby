# Come funziona Treby

## Panoramica

Treby è un'applicazione web dove ogni azienda (tenant) ha i propri dati completamente isolati. Un'azienda vede solo le proprie posizioni, candidati e pipeline.

```
┌───────────────────────────────────────────────────────┐
│                     Browser                            │
│                  (il tuo computer)                     │
├───────────────────────────────────────────────────────┤
│                 Applicazione Treby                     │
│         pagine interattive + aggiornamenti             │
│                in tempo reale                          │
├───────────────────────────────────────────────────────┤
│                  Logica di Treby                       │
│   Utenti │ Pipeline │ Colloqui │ Valutazioni │ Portale │
│   Offerte│ Candidati│ Calendari│ Messaggi    │ Sorgenti│
├────────────────────────────────────────────────────────┤
│                     Database                           │
│         (un unico database, dati separati              │
│          per azienda)                                  │
├────────────────────────────────────────────────────────┤
│              Servizi esterni                            │
│  Storage file (CV, loghi) │ Calendari │ Email          │
└────────────────────────────────────────────────────────┘
```

Tutte le pagine sono interattive e si aggiornano senza ricaricare il browser. Quando qualcuno sposta un candidato nella pipeline, tutti i colleghi vedono lo spostamento in tempo reale.

## Concetti chiave

### Aziende isolate (multi-tenant)

Ogni azienda registrata ha uno spazio separato. I dati di Acme non sono mai visibili a un'altra azienda e viceversa. L'isolamento avviene a livello di database.

È possibile creare più pipeline per la stessa azienda: ogni posizione può usare la pipeline predefinita o una pipeline dedicata con fasi diverse.

### Pipeline e fasi

Una pipeline è la sequenza di fasi che un candidato attraversa (es. Nuovo → Screening → Colloquio → Offerta → Assunto → Rifiutato). Ogni fase ha un colore, un ordine e può avere un tipo (es. fase di colloquio) che attiva regole particolari come le valutazioni.

Le pipeline sono configurabili: puoi rinominare le fasi, cambiare colori, riordinarle o crearne di nuove. Puoi anche salvare una pipeline come modello per riutilizzarla su altre posizioni.

### Ruoli sulle fasi

Ogni fase può avere tre tipi di assegnazione:

- **Esaminatori** — chi conduce i colloqui e compila le valutazioni
- **Revisori** — chi revisiona le candidature
- **Avanzatori** — chi può spostare o rifiutare candidati in quella fase

Solo gli avanzatori possono far avanzare o rifiutare candidati. Questa distinzione permette a un team di collaborare senza che tutti possano prendere decisioni finali.

### Autenticazione

- **Team interno** (admin e membri): accesso con email e password. Gli admin gestiscono impostazioni, pipeline e inviti; i membri usano la pipeline e i colloqui secondo i permessi assegnati.
- **Candidati**: nessun account con password. Il candidato inserisce la propria email, riceve un codice a 6 cifre via email valido 10 minuti e usa quel codice per entrare nel portale. La sessione dura poche ore e può essere chiusa esplicitamente.

### Portale candidati

Il portale è l'unico posto dove vivono i contenuti reali: messaggi, aggiornamenti di fase, dettagli del colloquio. L'email invia solo un avviso breve ("hai un nuovo messaggio, vai nel portale") con un link, mai il contenuto.

### File e calendari

- CV e loghi sono salvati su uno storage compatibile S3 (in sviluppo un servizio locale, in produzione qualsiasi provider S3).
- Ogni membro imposta le proprie fasce di disponibilità settimanale. Se colleghi Google Calendar, Treby incrocia le tue fasce interne con i tuoi impegni reali per proporre solo slot liberi.
- I link per i colloqui vengono creati automaticamente: Google Meet se almeno un esaminatore ha Google collegato, altrimenti Jitsi.

### Messaggi programmati

Puoi inviare un messaggio subito o programmarlo per dopo. I messaggi programmati hanno una coda dedicata, supportano un margine casuale (jitter) e ritentativi automatici in caso di errore.

## Cosa usa Treby (panoramica tecnica, non necessaria per l'uso quotidiano)

Treby è costruito con Phoenix LiveView, database PostgreSQL, storage S3, email via Swoosh, aggiornamenti in tempo reale e lavori in background per i messaggi programmati. Il dettaglio implementativo non è necessario per utilizzare l'applicazione: ti basta sapere che è un'applicazione web standard che gira nel browser e conserva i dati in un database.

## Modello dei dati (semplificato)

```
Aziende
  ├── Utenti (admin / membri)
  │   ├── Connessioni calendario
  │   └── Disponibilità settimanale
  ├── Pipeline (predefinita + modelli)
  │   └── Fasi (ordine, colore, tipo, valutazioni)
  │       └── Candidature (posizione, candidato, fase, stato lettura, sorgente)
  │           ├── Note e feedback con stelle
  │           └── Colloqui (data, stato, link meeting)
  │               └── Valutazioni (una per esaminatore)
  ├── Posizioni aperte
  ├── Candidati (anagrafica condivisa tra più posizioni)
  │   └── Conversazioni e messaggi del portale
  ├── Sorgenti candidato
  ├── Campi personalizzati
  ├── Pagine carriere (titolo, descrizione, colore, logo)
  ├── Modelli di messaggio per fase
  └── Modelli di valutazione
```

## Flusso di navigazione

1. Pagine pubbliche: home, carriere (`/careers` e `/:azienda/careers`), login e registrazione.
2. Area riservata team (`/app/*`): dashboard, posizioni, candidati, pipeline, analytics, colloqui — richiede login.
3. Impostazioni (`/app/settings/*`): riservate agli admin per pipeline, branding, team, campi, sorgenti, modelli.
4. Portale candidati (`/:azienda/portal/*`): login con codice via email, poi messaggi, programmazione colloqui e impostazioni notifiche. Separato dall'autenticazione del team.
