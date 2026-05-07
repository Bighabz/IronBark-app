# IronBark Security Solutions — Website

**IST 4910 Capstone · Spring 2026 · DOGPARK Group · CSUSB**
Habib Jahshan · Liam Pearson · Brandon Deane · Danny Hernandez

---

## What this is

The production website for IronBark Security Solutions (your fictional
cybersecurity firm). Built to satisfy every requirement on the capstone rubric:

- ✅ Real, functional company website (not a placeholder)
- ✅ Hosted on Windows Server IIS (Web Server VM, `10.0.1.100`)
- ✅ Connected to the Database VM (`10.0.1.200`) — products & engagements come from the DB, not hardcoded HTML
- ✅ Smart Product Catalog (filter, search, AI "Explain for my use case")
- ✅ AI-Powered Customer Service chatbot (ClaWD, on every page)
- ✅ Order / Engagement Status lookup with AI-generated summaries
- ✅ All AI calls routed through the CSUSB University AI API
- ✅ Bearer token lives in `.env` — never hardcoded, never sent to the browser
- ✅ Red Team hardening (CSP, CSRF, rate limiting, parameterized SQL, blocked file extensions, hidden segments)

---

## Repository layout

```
ironbark/
├── app.py                      # Flask application (all routes + AI proxy)
├── web.config                  # IIS configuration (deploy to site root)
├── requirements.txt            # Python dependencies
├── .env.example                # Template — copy to .env and fill in
├── .gitignore
├── database/
│   ├── __init__.py
│   ├── db.py                   # Pluggable DB layer (MySQL or MSSQL)
│   ├── schema_mysql.sql        # Run on the Database VM (MySQL)
│   └── schema_mssql.sql        # Run on the Database VM (MSSQL)
├── docs/
│   └── PRD.md                  # Product Requirements Document (rubric req.)
├── static/
│   ├── css/main.css            # Full design system
│   └── js/
│       ├── main.js             # Shared utilities + CSRF helper
│       ├── chat.js             # AI chatbot widget
│       ├── catalog.js          # Smart catalog + AI recommend
│       ├── contact.js          # Contact form
│       └── status.js           # Engagement lookup
└── templates/
    ├── base.html               # Shell (nav, footer, chat widget)
    ├── index.html              # Homepage
    ├── catalog.html            # Services / Products / Full catalog
    ├── about.html              # About + team
    ├── contact.html            # Contact form
    ├── status.html             # Engagement status portal
    └── error.html              # 404 / 500 / 429
```

---

## Local development (get it running fast)

```bash
# From the project root
python -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install -r requirements.txt
pip install PyMySQL               # or pyodbc if you're on MSSQL

cp .env.example .env
# Edit .env — put in your real DB creds, AI API URL, AI API key, etc.

# Seed the database (run against the Database VM):
mysql -h 10.0.1.200 -u root -p ironbark < database/schema_mysql.sql
#   ...or for MSSQL:
# sqlcmd -S 10.0.1.200 -U sa -P <pw> -i database/schema_mssql.sql

# Run it
export FLASK_ENV=development     # Windows: set FLASK_ENV=development
python app.py
# -> http://127.0.0.1:8000
```

Demo engagement codes (for the `/status` page):

| Code | Email |
|---|---|
| `IB-2026-0042` | `cto@northridge-mfg.example` |
| `IB-2026-0051` | `security@ridgelineaero.example` |
| `IB-2026-0063` | `it@canyonhealthgroup.example` |

---

## Database VM setup (10.0.1.200)

### MySQL / MariaDB

```bash
# On the DB VM:
mysql -u root -p < database/schema_mysql.sql

# Create a least-privilege app user (edit host/password in the SQL):
mysql -u root -p -e "
CREATE USER 'ironbark_app'@'10.0.1.100' IDENTIFIED BY 'YOUR_STRONG_PASSWORD';
GRANT SELECT, INSERT, UPDATE ON ironbark.* TO 'ironbark_app'@'10.0.1.100';
FLUSH PRIVILEGES;"
```

Make sure the Database VM's firewall allows **only** the Web Server VM
(`10.0.1.100`) to connect on port 3306. The Red Team should not be able to
reach the DB directly.

### Microsoft SQL Server

```cmd
sqlcmd -S localhost -U sa -P <password> -i database/schema_mssql.sql
```

Create the app login via SSMS or `CREATE LOGIN` / `CREATE USER` with
`SELECT, INSERT, UPDATE` on the `ironbark` database only.

---

## Production deployment on IIS (Web Server VM, 10.0.1.100)

### 1. Install prerequisites on the Web Server VM

1. **Python 3.11+** — install to `C:\Python311`, check "Add to PATH"
2. **IIS with CGI role** — Server Manager → Add Roles → Web Server (IIS) → CGI
3. **HttpPlatformHandler** — https://www.iis.net/downloads/microsoft/httpplatformhandler
4. **ODBC Driver 17 for SQL Server** (only if using MSSQL)

### 2. Deploy the code

```powershell
# Create site directory
New-Item -ItemType Directory -Path C:\inetpub\ironbark
New-Item -ItemType Directory -Path C:\inetpub\ironbark\logs

# Copy the entire project to C:\inetpub\ironbark\
# (use RDP file copy, Git, or a shared folder — just get the files there)

# Create the venv and install packages
cd C:\inetpub\ironbark
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt
pip install PyMySQL              # or pyodbc
```

### 3. Configure `.env`

```powershell
Copy-Item .env.example .env
notepad .env
```

Fill in:
- `FLASK_SECRET_KEY` → generate with `python -c "import secrets; print(secrets.token_hex(32))"`
- `DB_*` → point to `10.0.1.200` with the `ironbark_app` credentials
- `UNIVERSITY_AI_API_URL` + `UNIVERSITY_AI_API_KEY` → from your instructor
- `ADMIN_BASIC_PASS` → a strong password

### 4. Create the IIS site

1. Open IIS Manager
2. Right-click **Sites** → **Add Website**
3. Site name: `IronBark`
4. Physical path: `C:\inetpub\ironbark`
5. Binding: `http`, port `80`, IP `All Unassigned` (or specifically `10.0.1.100`)
6. Click OK

### 5. Permissions (important)

The app pool identity (`IIS AppPool\IronBark`) needs:
- **Read** on `C:\inetpub\ironbark`
- **Write** on `C:\inetpub\ironbark\logs` (only)
- **No Write** access anywhere else — especially not to `.env` or `app.py`

```powershell
icacls C:\inetpub\ironbark /grant "IIS AppPool\IronBark:(OI)(CI)R"
icacls C:\inetpub\ironbark\logs /grant "IIS AppPool\IronBark:(OI)(CI)M"
```

### 6. Verify

Browse to `http://10.0.1.100/` from inside the VM network. You should see the
homepage. If not, check `C:\inetpub\ironbark\logs\stdout*.log` for Python
errors.

### 7. DMZ / internet exposure

Your course setup should already route external traffic through the DMZ
firewall to `10.0.1.100:80`. From the public side, only HTTP (and/or HTTPS)
should be exposed. Nothing else.

---

## Security checklist (Red Team will test these)

- [x] `.env` is readable by the app pool user only, never served by IIS (blocked via `hiddenSegments` + `fileExtensions` in `web.config`)
- [x] `.py`, `.sql`, `.md`, `.log`, `.config` files return 404 via request filtering
- [x] All user input is length-capped and sanitized before hitting the DB or AI API
- [x] Parameterized SQL queries everywhere (no string concatenation)
- [x] CSRF tokens on every POST endpoint
- [x] Rate limiting: 20/min on chat, 10/min on AI recommend, 5/min on contact, 15/min on status
- [x] Session cookies are `HttpOnly`, `Secure`, `SameSite=Lax`
- [x] Content-Security-Policy restricts scripts to `'self'`
- [x] `X-Frame-Options: DENY` blocks clickjacking
- [x] AI bearer token never reaches the browser (all AI calls proxy through `/api/*`)
- [x] Error pages never leak stack traces
- [x] DB user has `SELECT, INSERT, UPDATE` only (no DROP, no DDL)
- [x] `X-Powered-By` header removed

### What you still need to do yourself

- [ ] Put a strong password on the `ironbark_app` DB user
- [ ] Put a strong `FLASK_SECRET_KEY` and `ADMIN_BASIC_PASS` in `.env`
- [ ] Lock down the Database VM firewall to accept only `10.0.1.100`
- [ ] Consider adding HTTPS (self-signed is fine for the lab; the instructor may require it)
- [ ] Change `ADMIN_BASIC_USER` away from `admin`

---

## How the AI integration works

The course requires AI-powered features that go through the university AI API.
Here's the data flow:

```
Browser  →  POST /api/chat  (with CSRF token, no API keys)
          Flask looks up bearer token from .env
          Flask calls CSUSB AI API with Authorization: Bearer <token>
          Flask returns just the reply text to the browser
```

The browser **never** sees:
- The AI API URL
- The Bearer token
- The model name
- The system prompt

If the Red Team pops open DevTools, they'll see `/api/chat` calls with a user
message and a CSRF token — that's it. Everything sensitive stays server-side.

### The 3 AI features (all proxied through Flask)

| Feature | Endpoint | What it does |
|---|---|---|
| Chatbot | `POST /api/chat` | Customer service agent trained to answer questions about IronBark services/products |
| Smart catalog | `POST /api/ai/recommend` | "Is this product a fit for my company?" — given a slug + free-text context, AI writes a fit analysis |
| Engagement status | `POST /api/status` | After DB lookup, AI writes a plain-English summary of scan findings and remediation progress |

---

## Testing checklist

Before you present:

- [ ] Homepage loads, terminal animation runs, hero reveals stagger in
- [ ] Services page lists all 3 services from the DB (delete one and confirm it disappears — proves it's live)
- [ ] Products page lists all 3 products from the DB
- [ ] Catalog filter (All / Services / Products) works
- [ ] Catalog search (⌘K or Ctrl+K shortcut) filters in real time
- [ ] "Explain for my use case" on a catalog card calls the AI and shows a recommendation
- [ ] Chat widget opens, accepts messages, returns AI responses
- [ ] Chat bot stays on-topic for IronBark (try asking unrelated questions)
- [ ] Contact form submits and writes to `contact_submissions` table
- [ ] Status page looks up `IB-2026-0042 / cto@northridge-mfg.example` and shows AI summary
- [ ] Status page rejects wrong code or wrong email with generic error (no info leak)
- [ ] Try `/` in incognito — no session carries over
- [ ] Try `curl http://10.0.1.100/.env` — returns 404
- [ ] Try `curl http://10.0.1.100/app.py` — returns 404
- [ ] Try `curl http://10.0.1.100/database/schema_mysql.sql` — returns 404
- [ ] DevTools → Network → no API keys visible anywhere
- [ ] Mobile layout: nav collapses, hero stacks, chat widget works

---

## What's in the PRD

`docs/PRD.md` contains the full Product Requirements Document that the rubric
requires. It covers target audience, feature list, technical stack, UI/UX
guidelines, security requirements, and the complete database schema. Hand it
to Cursor/Antigravity with *"build this"* and you should get a working
skeleton — which is exactly what your course's "good PRD test" wants.

---

## Quick troubleshooting

| Symptom | Fix |
|---|---|
| `No module named 'pymysql'` | `pip install PyMySQL` (or `pyodbc`) |
| `Access denied for user 'ironbark_app'` | DB user not created, wrong host in GRANT, or wrong password in `.env` |
| 500 errors, blank page | Check `C:\inetpub\ironbark\logs\stdout*.log` |
| AI chat returns 503 | `UNIVERSITY_AI_API_URL` or `_KEY` is wrong in `.env`, or the API is down |
| `Invalid session token` on form submit | Clear cookies, CSRF expired; refresh the page |
| Catalog is empty | DB schema not seeded; rerun `schema_mysql.sql` |
| `.env` is accessible via browser | You forgot to copy `web.config` to site root |

---

## License

Built as coursework for IST 4910, CSUSB, Spring 2026. All code MIT-licensed
for the DOGPARK Group to use, extend, and present.
