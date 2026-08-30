# Message Scheduler

Schedule portal messages for a future time — from stage moves or bulk sends — and manage everything from a dedicated queue page.

![Message Queue](/screenshots/23-message-queue.png)

## Schedule any portal message

Every portal message flow can be sent immediately or scheduled for later:

| Flow | Where |
|---|---|
| **Stage move** | Moving a candidate with a message template: send now, schedule, or skip |
| **Bulk send** | In the candidates list, choose a date and time for the bulk message |

The schedule picker offers presets — **Tomorrow 9:00**, **Tomorrow 14:00**, **Next Monday** — plus a full date/time picker. A jitter option spreads scheduled messages across a time window.

## Message Queue

The **Message Queue** page (in the top navigation) lists every pending, posted, failed, and cancelled message in one place, organized into tabs.

For each queued message you can:

- **Edit** — change the body or the schedule time
- **Post Now** — deliver immediately, skipping the schedule
- **Cancel** — stop a pending message before it goes out

Se annulli un messaggio, non verrà più inviato anche se la consegna era già stata programmata.

## Affidabilità

- Se l'invio fallisce, Treby ritenta automaticamente con attese crescenti (circa 1, 4, 15 e 60 minuti)
- Dopo 5 tentativi falliti il messaggio viene segnato come **non riuscito** con il motivo dell'errore e puoi ritentare manualmente
- Finché è in attesa, il messaggio resta modificabile o annullabile

## Dettagli utili

- Negli invii massivi ogni candidato riceve un messaggio programmato indipendente — puoi modificarne uno senza toccare gli altri
- L'orario effettivo di invio tiene conto dell'eventuale margine casuale scelto