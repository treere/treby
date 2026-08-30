# Job Analytics — Visite Annuncio

Capisci quante persone vedono ogni annuncio e da dove arrivano, per ottimizzare visibilità e conversione.

![Job Analytics](/screenshots/12-job-analytics.png)

## Dove si trova

- **Lista offerte** (`Offerte`): ogni riga mostra un riepilogo sintetico — totale visite e visite ultimi 7 giorni — o “Nessuna visita” se l’annuncio è nuovo.
- **Dettaglio offerta** (`Offerte → Dettaglio`): sopra il titolo trovi un badge con lo stesso riepilogo; nelle azioni in alto a destra c’è il pulsante **Analytics** (icona grafico) che apre la pagina dedicata.
- **Pagina analytics per offerta** (`Offerte → Dettaglio → Analytics`): raggiungibile solo da membri del tuo team. Se provi ad aprire un annuncio di un’altra azienda, vedrai una pagina “Non trovato”.

## Cosa mostra la pagina Analytics

- **Indicatori (KPI)** in alto:
  - *Totale visite* e *Visite uniche* (stessa persona contata una volta)
  - *Ultimi 7 / 30 giorni* e *Media giornaliera*
  - *Conversione* — % di visite che diventano candidature, con numero totale candidature e media aziendale a confronto
- **Grafico giornaliero** — barre per gli ultimi 7, 30 o 90 giorni (selettore periodo in alto). I giorni senza visite restano a 0.
- **Mensile** — barre per gli ultimi 12 mesi (dal primo del mese).
- **Sorgenti traffico** — da dove arrivano le visite: `utm_source` se presente (es. LinkedIn, Indeed), altrimenti dominio del referrer, altrimenti “Direct”. Percentuale e conteggio.
- **Funnel Visita → Candidatura** — totale visite vs totale candidature e tasso di conversione; utile per capire se un annuncio è visto ma poco attrattivo.

Se l’annuncio è **chiuso**, la pagina resta accessibile con i dati storici ma non registra nuove visite. Se non ci sono ancora visite, vedrai “Nessuna visita” e i grafici vuoti con messaggio esplicativo.

## Come usarla — passo per passo

1. Apri `Offerte` e individua l’annuncio da analizzare.
2. Entra nel dettaglio e clicca **Analytics** in alto a destra.
3. Controlla i KPI: molte visite ma poche candidature → rivedi titolo/descrizione; poche visite → promuovi di più il link pubblico.
4. Scegli il periodo (7/30/90 giorni) per vedere picchi dopo condivisioni su LinkedIn o newsletter.
5. Leggi le sorgenti: se “Direct” domina, aggiungi `?utm_source=linkedin` quando condividi l’annuncio per tracciare meglio.
6. Confronta la conversione con la media aziendale sotto il funnel per priorizzare le posizioni.

## Privacy

Non viene salvato l’indirizzo IP in chiaro né dati personali del visitatore — solo un identificativo anonimo di sessione, dominio del referrer e `utm_source`. Le visite del tuo stesso team (mentre sei autenticato) non vengono conteggiate, così come i bot più comuni.

## Dettagli utili

- Le visite ripetute dalla stessa persona entro circa un’ora contano come una sola (anti-refresh).
- I link pubblici diretti (`/:azienda/careers/:id`) vengono conteggiati anche se l’annuncio è “Privato” ma aperto; gli annunci chiusi non incrementano più il contatore.
