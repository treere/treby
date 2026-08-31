# Portale candidati

I candidati hanno un portale personale dove seguono la propria candidatura senza bisogno di password: basta un codice a 6 cifre.

![Portal Login](/screenshots/26-portal-login.png)

## Accesso con codice

- Il candidato inserisce la propria email nella pagina di login del portale
- Riceve via email un **codice a 6 cifre** valido 10 minuti, utilizzabile una sola volta
- Inserisce il codice e accede al portale per qualche ora, poi può uscire esplicitamente

Non viene mai creata una password per i candidati; l'accesso del team e quello dei candidati sono completamente separati.

## Cosa può fare il candidato

| Pagina | Cosa vede |
|---|---|
| **Panoramica** | Stato della candidatura, fase attuale e prossimi passi |
| **Messaggi** | Conversazioni per ogni candidatura (botta e risposta con i recruiter) |
| **Colloqui** | Scelta dello slot per il colloquio tra quelli disponibili (vedi [Colloqui](/features/interview-scheduling)) |
| **Impostazioni** | Preferenze di notifica — quali avvisi generano un'email e filtro "solo importanti" |

Ogni nuova candidatura crea automaticamente una conversazione di benvenuto. Spostamenti di fase, messaggi, aggiornamenti sui colloqui e rifiuti vengono pubblicati nella stessa conversazione e, se previsto, generano un breve avviso via email con link al portale.

## Messaggi nel portale

- Ogni candidatura ha la propria conversazione
- I recruiter scrivono dalla scheda della pipeline, dal profilo candidato o dalla coda messaggi; i candidati rispondono dai **Messaggi** del portale
- I messaggi possono essere inviati subito o programmati (vedi [Programmazione messaggi](/features/message-scheduler))
- I modelli di messaggio supportano variabili come nome candidato, titolo posizione, nome azienda e nome fase

## Privacy e notifiche

- Tutti i contenuti reali vivono nel portale: l'email contiene solo un avviso breve con link, mai il testo del messaggio
- Il candidato decide dalle **Impostazioni** del portale quali eventi generano avvisi
- La sessione del portale è legata alla singola azienda e scade dopo poche ore
- Ogni candidato vede solo le proprie candidature: anche provando a indovinare un link, il portale mostra solo i dati del proprio profilo e, se l'indirizzo dell'azienda nell'URL non corrisponde, reindirizza automaticamente al proprio portale
