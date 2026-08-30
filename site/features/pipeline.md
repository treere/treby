# Pipeline Kanban

La pipeline è il cuore di Treby: una bacheca dove sposti i candidati tra le fasi di selezione.

![Pipeline Kanban](/screenshots/07-pipeline-kanban.png)

## Pagina della posizione

La pagina di dettaglio di una posizione è lo spazio di lavoro quotidiano: i candidati sono **raggruppati per fase** in colonne, così vedi a colpo d'occhio chi è dove.

- **Cambio fase rapido** — ogni scheda ha un menu "Sposta in…" per cambiare fase senza uscire dalla pagina
- **Stato di lettura** — segna le candidature come lette (badge NUOVO) direttamente dalla scheda
- **Rifiuto** — rifiuta con motivazione direttamente dalla pagina
- **Schede contestuali** — badge DUPLICATO e "Anche in N altre posizioni", chip per i prossimi colloqui e link al CV
- **Ricerca** — filtra i candidati della posizione per nome o email
- **Profili** — clic sul nome apre il profilo, con ritorno alla posizione di partenza

### Panoramica pipeline

La sezione pipeline nella pagina della posizione è in sola lettura di default: mostra le fasi in ordine con colore, tipo, numero di candidati e nomi di esaminatori, revisori e avanzatori assegnati. Gli admin possono aprire l'editor con il pulsante **Gestisci pipeline**.

## Come funziona

- **Fasi** configurabili: aggiungi, rimuovi, riordina e colora
- **Schede** con nome, email e indicatori di contesto
- **Drag & drop** per spostare i candidati tra fasi
- **Sincronizzazione in tempo reale**: tutti i membri vedono gli spostamenti subito
- **Contatori** nell'intestazione di ogni colonna

## Indicatori sulle schede

- **"Anche in N altre posizioni"** — quando un candidato ha candidature in altre posizioni
- **Badge DUPLICATO** — quando lo stesso candidato ha due candidature per la stessa posizione
- **Badge NUOVO** — finché la candidatura non è stata segnata come letta
- **Blocchi operativi** — nelle fasi di colloquio vedi cosa manca per avanzare, con i nomi degli esaminatori in attesa ("Manca valutazione: Caio") o colloquio non ancora completato
- **Pronto ad avanzare** — indicatore verde quando colloquio completato e valutazioni ricevute

## Permessi per fase

Ogni fase può avere tre assegnazioni:

| Ruolo | Chi è | Cosa può fare |
|---|---|---|
| **Esaminatore** | Chi conduce i colloqui | Svolge colloqui e compila valutazioni |
| **Revisore** | Chi revisiona le candidature | Revisiona e lascia feedback |
| **Avanzatore** | Chi decide | Fa avanzare o rifiuta candidati in quella fase |

Solo gli avanzatori possono far avanzare o rifiutare. Gli altri vedono la pipeline ma non possono decidere l'avanzamento.

### Blocco avanzamento

Nelle fasi di colloquio l'avanzamento richiede sia il colloquio segnato come **completato** sia tutte le valutazioni inviate:

- Il pulsante **Avanzare** è visibile solo agli avanzatori
- **Segna come completato** sulla scheda richiede conferma
- Il pulsante resta disattivato finché manca una valutazione o il colloquio non è completato
- Anche il drag & drop verso la fase successiva richiede di essere avanzatore

Gli esaminatori possono aprire il modulo di valutazione direttamente dalla scheda del candidato.

### Rifiuto

Gli avanzatori possono rifiutare dalla bacheca:

1. Clic su **Rifiuta** sulla scheda
2. Inserisci una motivazione (obbligatoria)
3. Il candidato passa alla fase "Rifiutato"

Usa il filtro **Rifiutati** per vedere solo i candidati rifiutati.

## Fasi predefinite

La pipeline predefinita ha 7 fasi:

| Fase | Colore | Scopo |
|---|---|---|
| Nuovo | verde | Nuove candidature da pagina carriere, inserimento manuale o import CSV |
| Screening | blu | Prima scrematura dei requisiti |
| Phone Screen | viola | Primo contatto telefonico |
| Colloquio | arancio | Colloqui approfonditi — con valutazioni e blocco avanzamento |
| Offerta | rosa | Negoziazione offerta |
| Assunto | verde chiaro | Assunzione completata — usata per i tempi medi |
| Rifiutato | rosso | Candidati non selezionati (richiede motivazione) |

Puoi personalizzarle in **Impostazioni → Pipeline** / **Impostazioni → Fasi pipeline**: nomi, colori, ordine, tipo di fase, numero minimo di esaminatori e modello di valutazione collegato, oltre a gestire più pipeline per azienda.

## Modelli di pipeline

Crea configurazioni riutilizzabili per non ripetere la stessa impostazione per posizioni simili.

- **Crea modelli** da zero in **Impostazioni → Modelli pipeline**
- **Salva come modello** da una pipeline esistente (copia fasi e assegnazioni)
- **Usa un modello** quando crei una nuova posizione
- I modelli copiano assegnazioni, numero minimo di esaminatori e modelli di valutazione

## Come usarla al meglio

1. Apri una posizione dalla pagina **Posizioni** — la pagina di dettaglio è il tuo workspace con candidati raggruppati, spostamenti rapidi, lettura e rifiuti
2. Clic su **Vedi pipeline** per la bacheca avanzata con drag & drop, azioni massive, programmazione e valutazioni
3. Trascina una scheda in un'altra colonna (o usa il pulsante Avanzare nelle fasi di colloquio)
4. Tutti i membri vedono l'aggiornamento in tempo reale
5. Clic sul nome del candidato per aprire il profilo completo
