# IronBark Security Solutions — Product Requirements Document (PRD)

**Project:** IronBark corporate website
**Course:** IST 4910, Spring 2026 — DOGPARK Group
**Team:** Habib Jahshan, Liam Pearson, Brandon Deane, Danny Hernandez
**Target deployment:** Windows Server IIS on Web Server VM `10.0.1.100`
**Backend data source:** Database VM `10.0.1.200`
**External AI service:** CSUSB University AI API (Bearer token auth)

---

## 1. Purpose

Build the public-facing website for IronBark Security Solutions, a fictional managed cybersecurity firm specializing in AI-driven penetration testing, compliance auditing, and hardened infrastructure deployment. The site must function as a real marketing + client portal: it should let visitors browse the service catalog, review products, submit contact requests, check the status of an engagement, and chat with an AI support agent — all backed by a live database and the university AI API.

## 2. Target Audience

**Primary:**
- Small-to-medium business IT decision makers (CTO, IT Director, security lead) evaluating managed security providers.
- Compliance officers at defense-adjacent contractors (NIST 800-171, CMMC 2.0 Level 2, DoD).

**Secondary:**
- Existing IronBark customers checking engagement status or scan reports.
- The IST 4910 Red Team, who will actively attempt to break, exfiltrate secrets from, and deface this site. The site must be hardened accordingly.
- The course instructor grading the business-concept integration.

## 3. Feature List

### 3.1 Public pages
- **Home** — hero statement, value proposition, quick service overview, call-to-action.
- **Services** — full detail on the 3 managed services (Managed Penetration Testing, Compliance Auditing & Risk Assessment, Secure Infrastructure Deployment).
- **Products** — full detail on the 3 products (ClaWD Autonomous Red Team Agent, SecurePack SMB Network Appliance, IronBark Compliance Dashboard).
- **About** — team, mission, methodology.
- **Contact** — form that writes to the database.

### 3.2 Smart Product Catalog
- Products and services loaded dynamically from the database, not hardcoded in HTML.
- Client-side filter (All / Services / Products) and search.
- Each item has tags, short description, long description, and pricing tier.
- AI-enhanced "Explain this for my use case" button on each product — POSTs the product ID and a free-text user context to `/api/ai/recommend`, which asks the university AI whether the product fits.

### 3.3 AI-Powered Customer Service Chatbot
- Floating chat widget on every page.
- Proxies user messages to the CSUSB AI API via `/api/chat`.
- Bearer token loaded from `.env` server-side and **never** exposed to the browser.
- System prompt is scoped to IronBark's products, services, and general cybersecurity questions.
- Chat history is kept per session (server-side) and logged to the database for later review.

### 3.4 Order / Engagement Status Lookup
- Customer enters an engagement ID and email at `/status`.
- Server validates against the `engagements` table on the Database VM.
- AI summarizes the engagement status in plain English ("Your pen-test scan 2025-11-04 found 3 high-severity issues; remediation is 67% complete").
- Also shows raw status, last scan date, scheduled next scan.

### 3.5 Contact form
- Writes to `contact_submissions` on the Database VM.
- Server-side validation, CSRF token, rate limiting.

### 3.6 Admin visibility (stretch)
- Read-only endpoint `/api/admin/submissions` behind HTTP basic auth for demo.

## 4. Technical Stack

| Layer | Technology | Notes |
|---|---|---|
| Frontend | HTML5, CSS3, vanilla JavaScript (ES2020) | No framework — keeps IIS deployment simple and Red Team surface area small. |
| Backend | Python 3.11+, Flask 3.x | Served via `wfastcgi` or `HttpPlatformHandler` under IIS. |
| Database driver | `pyodbc` (MSSQL) or `PyMySQL` (MySQL/MariaDB) — configurable | Chosen at runtime from `DB_ENGINE` env var. |
| Database host | `10.0.1.200` | Credentials in `.env`. |
| AI integration | CSUSB University AI API | Bearer token in `.env` as `UNIVERSITY_AI_API_KEY`. All AI calls proxied through Flask — the browser never sees the key. |
| Secret management | `.env` file outside the webroot, loaded via `python-dotenv` | Added to `.gitignore` and IIS request filtering denies `.env` explicitly. |
| Session | Flask built-in, signed cookies, `HttpOnly` + `Secure` + `SameSite=Lax` | Secret in `.env`. |

### 4.1 Required environment variables (`.env`)

```
FLASK_SECRET_KEY=<random 64 hex chars>
DB_ENGINE=mysql            # or "mssql"
DB_HOST=10.0.1.200
DB_PORT=3306
DB_NAME=ironbark
DB_USER=ironbark_app
DB_PASSWORD=<strong password>
UNIVERSITY_AI_API_URL=https://<csusb ai endpoint>/v1/chat/completions
UNIVERSITY_AI_API_KEY=<bearer token from instructor>
UNIVERSITY_AI_MODEL=<model name provided by course>
ADMIN_BASIC_USER=admin
ADMIN_BASIC_PASS=<strong password>
```

## 5. UI / UX Guidelines

### 5.1 Aesthetic direction
Dark "security operations console." Near-black background (`#0a0d0c`), terminal green primary (`#5ef38c`), amber warning accent (`#f5b544`), desaturated cyan link color. Grid-line background texture. Scanline effect on hero. This is a cybersecurity brand — it should look like a tool, not a Squarespace template.

### 5.2 Typography
- **Display / headings:** JetBrains Mono — monospaced, technical, already associated with dev tooling.
- **Body:** Space Grotesk — neutral geometric sans, readable at long line lengths.
- **Tagged labels:** JetBrains Mono, uppercase, letter-spaced.

### 5.3 Layout
- 1280px max content width, 24px gutter.
- Grid-based sections, generous vertical rhythm (96–128px section padding).
- Every "card" uses a 1px border (`rgba(94, 243, 140, 0.2)`) rather than shadows — looks like a dashboard panel, not a SaaS card.
- Hero includes an animated terminal readout with ClaWD simulating a scan.

### 5.4 Motion
- Staggered fade-up on page load for hero lines.
- Scan-line sweep across hero every ~8s.
- Chat widget slides up from bottom-right.
- No gratuitous scroll animations.

### 5.5 Accessibility
- WCAG AA color contrast (green on near-black passes at 7:1 for body text).
- All interactive elements keyboard-reachable.
- Chat widget has visible focus states and an aria-live region for incoming messages.

## 6. Security Requirements (the Red Team WILL try these)

1. `.env` is outside the IIS webroot, and IIS `web.config` explicitly denies `.env`, `.git`, `__pycache__`, and `*.py` direct requests.
2. No API keys, DB credentials, or model names appear in any frontend JS, HTML, or source map.
3. All DB queries use parameterized statements (no string concatenation).
4. All user input sanitized / length-capped before hitting the AI API.
5. CSRF tokens on every POST form.
6. Rate limiting on `/api/chat` (20 requests/min/IP) and `/api/contact` (5/min/IP).
7. Error pages never leak stack traces.
8. Session cookies are `HttpOnly`, `Secure`, `SameSite=Lax`.
9. Content-Security-Policy header restricts script sources to `'self'`.

## 7. Database Schema

```sql
CREATE TABLE products (
  id INT AUTO_INCREMENT PRIMARY KEY,
  kind ENUM('service','product') NOT NULL,
  slug VARCHAR(64) UNIQUE NOT NULL,
  name VARCHAR(128) NOT NULL,
  tagline VARCHAR(255),
  description TEXT NOT NULL,
  tags VARCHAR(255),
  price_tier VARCHAR(32),
  display_order INT DEFAULT 0,
  active TINYINT(1) DEFAULT 1
);

CREATE TABLE contact_submissions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  submitted_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  name VARCHAR(128) NOT NULL,
  email VARCHAR(255) NOT NULL,
  company VARCHAR(128),
  message TEXT NOT NULL,
  source_ip VARCHAR(45)
);

CREATE TABLE engagements (
  id INT AUTO_INCREMENT PRIMARY KEY,
  engagement_code VARCHAR(32) UNIQUE NOT NULL,
  client_email VARCHAR(255) NOT NULL,
  client_company VARCHAR(128) NOT NULL,
  service_type VARCHAR(64) NOT NULL,
  status ENUM('scheduled','in_progress','reporting','complete') NOT NULL,
  last_scan_at DATETIME,
  next_scan_at DATETIME,
  findings_critical INT DEFAULT 0,
  findings_high INT DEFAULT 0,
  findings_medium INT DEFAULT 0,
  findings_low INT DEFAULT 0,
  remediation_percent INT DEFAULT 0,
  notes TEXT
);

CREATE TABLE chat_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  session_id VARCHAR(64) NOT NULL,
  role ENUM('user','assistant') NOT NULL,
  content TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

## 8. Success Criteria

- Site loads at `http://10.0.1.100` and from the internet through the DMZ.
- Products and services render from the `products` table (kill the DB, the catalog goes empty — proves it's live).
- Chat widget returns answers from the university AI API within 5s for typical prompts.
- `/status` resolves a real `engagement_code` and returns both raw data and an AI-written plain-English summary.
- Red Team cannot retrieve `.env`, DB credentials, or the AI bearer token through any HTTP request.
- Site passes a basic Nikto / Nmap script scan with no critical findings.

## 9. Out of scope

- Actual payment processing.
- User accounts / registration (engagement lookup is code + email only).
- Mobile app.
- Real-time scan execution from the public site (that happens inside ClaWD, not here).
