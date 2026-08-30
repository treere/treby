# Guida introduttiva

## Requisiti

- **Elixir 1.19+ / Erlang 28+** (versioni indicate in `.tool-versions`)
- **PostgreSQL 14+**
- **Storage compatibile S3** — in sviluppo viene fornito da `docker-compose.yml` (RustFS), in produzione qualsiasi provider S3
- **Node.js 18+** (solo se vuoi compilare gli asset o la documentazione)

## Installazione rapida

```bash
# Clona il repository
git clone git@github.com:treere/treby.git
cd treby

# Installa le dipendenze, crea il database e carica i dati di esempio
mix setup

# Avvia il server
mix phx.server
```

Apri [`http://localhost:4000`](http://localhost:4000) nel browser.

## Dati di esempio

Il comando di setup carica dati demo per l'azienda **Acme Corp** (`acme`):

| Email | Password | Ruolo |
|---|---|---|
| `admin@acme.com` | `password123` | Admin |
| `member@acme.com` | `password123` | Membro |

Contenuti precaricati:

- 3 posizioni — Senior Elixir Developer, Product Designer, DevOps Engineer
- 10 candidati con candidature distribuite nelle varie fasi
- 6 profili duplicati aggiuntivi (stessa persona con email/telefono leggermente diversi) per provare la funzione di unione
- 7 fasi di pipeline — Nuovo → Screening → Phone Screen → Colloquio → Offerta → Assunto → Rifiutato
- Pagina carriere pubblicata su `http://localhost:4000/acme/careers`
- Alcuni messaggi programmati di esempio per la coda

## Sviluppo con Docker

Il file `docker-compose.yml` avvia PostgreSQL e lo storage S3 locale:

```bash
docker compose up -d
mix setup
mix phx.server
```

La console dello storage è su `http://localhost:9001` (credenziali in `.env.example` — `treby` / `treby_password`).

## Variabili d'ambiente

Treby legge la configurazione dalle variabili d'ambiente. Il file `.env.example` elenca tutte le variabili con valori adatti allo sviluppo; il file `.env` (ignorato da git) contiene i tuoi valori reali:

```bash
cp .env.example .env   # poi modifica i valori
```

Variabili principali:

| Variabile | Richiesta in produzione | Descrizione |
|---|---|---|
| `SECRET_KEY_BASE` | sì | Chiave segreta — generabile con `mix phx.gen.secret` |
| `DATABASE_URL` | sì | URL del database, es. `ecto://USER:PASS@HOST/DATABASE` |
| `PHX_HOST` | sì | Host pubblico, es. `treby.example.com` |
| `CLOAK_KEY` | consigliata | Chiave per la cifratura dei token Google; ha un valore di default per lo sviluppo |
| `S3_*` | — | `S3_SCHEME`, `S3_HOST`, `S3_PORT`, `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY` |
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | se usi Google Calendar | Credenziali OAuth da https://console.cloud.google.com — callback `http(s)://HOST/auth/google/callback` |
| `MAILGUN_API_KEY` / `MAILGUN_DOMAIN` | se usi email in produzione | Provider SMTP |

Come iniettare le variabili (export shell, gestore di processi, ecc.) dipende dal tuo ambiente.

## Comandi utili

| Comando | Cosa fa |
|---|---|
| `mix setup` | Installa dipendenze, crea/migra il database, carica i dati di esempio e compila gli asset |
| `mix ecto.setup` | Crea e migra il database + carica i dati di esempio |
| `mix ecto.reset` | Ricrea il database da zero |
| `mix phx.server` | Avvia l'applicazione su http://localhost:4000 |
| `mix precommit` | Controlli di qualità (formattazione, analisi statica, test) |

## Sito della documentazione

Questa documentazione è un sito VitePress in `site/`:

```bash
cd site && npm install && npm run dev   # http://localhost:5173/treby/
cd site && npm run build                # genera il sito statico
```

Per rigenerare gli screenshot usati nelle pagine delle funzionalità (richiede l'app avviata con dati di esempio):

```bash
node scripts/screenshots.mjs            # salva in site/public/screenshots/
```

Il sito viene pubblicato automaticamente su GitHub Pages ad ogni push su `main`.
