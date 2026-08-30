# Schede di valutazione

Valutazioni strutturate per i colloqui: modelli con criteri, compilazione per esaminatore e blocco dell'avanzamento finché mancano valutazioni.

## Modelli

Gli admin configurano i modelli in **Impostazioni → Valutazioni**:

- Ogni modello ha una lista ordinata di **criteri** (es. "Profondità tecnica", "Comunicazione", "Affinità culturale") con descrizione opzionale
- Le fasi di tipo "colloquio" possono essere collegate a un modello

## Compilazione

- Solo gli esaminatori assegnati alla fase possono compilare la valutazione per quel colloquio
- Ogni colloquio ha una valutazione per esaminatore
- Lo stesso modulo è disponibile in più punti: scheda del candidato nella pipeline, pannello del profilo, pulsante **Compila valutazione** nella dashboard e nella pagina colloqui
- Una valutazione già inviata può essere modificata dallo stesso esaminatore

## Blocco avanzamento

Nelle fasi di colloquio l'avanzamento richiede entrambe le condizioni:

1. il colloquio segnato come **completato** (con conferma), e
2. **tutte** le valutazioni degli esaminatori inviate

Finché manca qualcosa:

- la scheda mostra blocchi operativi ("Manca valutazione: Caio", "Colloquio non ancora completato")
- il pulsante **Avanzare** (e il drag & drop verso la fase successiva) resta disattivato per chi non è avanzatore o se le valutazioni sono incomplete

Vedi anche [Pipeline Kanban](/features/pipeline) per il flusso completo di avanzamento e rifiuto.

## Collegamento con la dashboard

- **Le mie azioni → Valutazioni da compilare** elenca i colloqui dove sei esaminatore con pulsante diretto per compilare
- **In attesa di altri** mostra le candidature bloccate perché mancano valutazioni di altri esaminatori
