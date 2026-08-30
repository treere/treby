# Importazione CSV

Migra candidati da un foglio di calcolo in tre passi: carica, mappa, importa.

## Procedura

Trovi la funzione in **Importa** dal menu principale.

1. **Carica** — trascina un file `.csv` (max 10 MB). Il sistema legge intestazioni e righe.
2. **Mappa** — Treby riconosce automaticamente le colonne più comuni:

   | Intestazione nel CSV | Campo in Treby |
   |---|---|
   | `name` / `full_name` / `candidate_name` | Nome |
   | `email` / `e-mail` / `email_address` | Email |
   | `phone` / `mobile` / `phone_number` | Telefono |
   | `linkedin` / `linkedin_url` | Profilo LinkedIn |

   Puoi correggere la mappatura, scegliere la **posizione** e la **fase** di destinazione e indicare una **sorgente** opzionale.
3. **Importa** — il sistema crea o riusa i profili (cercando per email all'interno della tua azienda), crea una candidatura per ogni riga nella fase scelta e mostra un riepilogo con conteggi ed eventuali errori per riga.

L'interfaccia è una procedura guidata in 4 passi (Carica → Mappa → Anteprima → Risultato) con validazione e segnalazione errori.

## Duplicati

Se un'email esiste già, il profilo esistente viene riutilizzato invece di crearne uno nuovo; la candidatura viene comunque creata e contrassegnata come duplicata se lo stesso candidato aveva già una candidatura per quella posizione.

## Sorgenti

Se indichi una sorgente durante l'importazione, tutte le candidature create porteranno quel valore, che poi ritrovi nel breakdown per sorgente in **Analytics** e come etichetta sulla candidatura.
