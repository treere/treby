# Cambio Spazio di Lavoro

Un'unica email e password per tutte le tue aziende. Ogni azienda è uno spazio separato con le sue posizioni, candidati e impostazioni — puoi essere Admin in una e Membro in un'altra.

![Scegli spazio di lavoro](/screenshots/27-workspace-picker.png)

*Scegli spazio di lavoro — dopo il login chi ha più aziende vede l'elenco con ruolo. Sotto, **Crea nuova azienda**.*

![Menu cambio spazio nell'header](/screenshots/28-header-switcher.png)

*Menu nell'header (visibile con più di uno spazio) — mostra l'azienda attuale con spunta e ruolo, più **Crea nuova azienda**.*

## Dove si trova

* **Al login** — dopo email e password, se appartieni a più aziende vedi **Scegli spazio di lavoro**. Scegli l'azienda e prosegui.
* **Nell'header** — quando hai più di uno spazio, accanto al logo Treby c'è un menu con il nome dell'azienda attuale. Aprilo per cambiare al volo.
* **Crea nuova azienda** — nel selettore o nel menu dell'header scegli **Crea nuova azienda**, inserisci il nome e diventi Admin del nuovo spazio.

## Come si usa

1. **Accedi** con email e password.
   * Un solo spazio → vai direttamente a `tua-azienda/app`.
   * Più spazi → atterri su **Scegli spazio di lavoro** con l'elenco delle aziende e il tuo ruolo (Admin / Membro).

2. **Scegli lo spazio** — clic sull'azienda. Tutto l'app si carica in quel contesto: posizioni, candidati, pipeline e analytics sono solo di quell'azienda.

3. **Cambia al volo** — apri il menu dell'azienda nell'header e seleziona un'altra azienda. L'indirizzo diventa `altra-azienda/app` e l'app si ricarica. I preferiti mantengono lo spazio (`azienda/app/posizioni/123`).

4. **Crea un'altra azienda** — dal selettore o dal menu, **Crea nuova azienda** → inserisci il nome → vieni reindirizzato al nuovo spazio come Admin. Non serve una nuova password: la stessa vale ovunque.

5. **Compatibilità** — i vecchi preferiti come `/app/posizioni` continuano a funzionare e ti portano al primo spazio o al selettore se ne hai più d'uno.

## Ruoli per spazio

Il ruolo è **per azienda**, non globale.

| Tu sei | In quell'azienda puoi |
|---|---|
| **Admin** | Gestire **Impostazioni → Pipeline**, **Team**, **Campi**, **Sorgenti**, branding, inviti |
| **Membro** | Usare posizioni, candidati, candidature, note, colloqui e valutazioni secondo i permessi delle fasi |

Vedi solo gli spazi in cui sei stato invitato.

## Inviti

* **Admin → Impostazioni → Team → Invita** — invita per email nello spazio attuale. L'invitato riceve un link.
* **Se l'email esiste già** — Treby non crea un duplicato: aggiunge la persona allo spazio con la password che già usa.
  * Non sei entrato → vedi **Accedi come nome@email per accettare l'invito**.
  * Sei già entrato con la stessa email → **Unisciti a Nome Azienda** (un clic, senza nuova registrazione).
  * Sei entrato con un'altra email → **Sei entrato come altro@azienda.com ma l'invito è per nome@email — Esci e continua come nome@email**.

L'invito scade dopo 7 giorni.

## Consigli

* Il menu di cambio spazio è nascosto se hai un solo spazio.
* L'indirizzo dell'azienda deriva dal nome (es. `acme-corp`) e non cambia dopo la creazione.
* **Reimposta password** è globale: la nuova password vale per tutti i tuoi spazi.
