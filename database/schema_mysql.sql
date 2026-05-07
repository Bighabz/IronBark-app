-- IronBark Security Solutions — MySQL schema
-- Run on the Database VM (10.0.1.200)

CREATE DATABASE IF NOT EXISTS ironbark
  DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ironbark;

-- Dedicated app user with least privilege
-- (adjust host to the web server's IP: '10.0.1.100')
-- CREATE USER 'ironbark_app'@'10.0.1.100' IDENTIFIED BY 'CHANGE_ME_STRONG_PASSWORD';
-- GRANT SELECT, INSERT, UPDATE ON ironbark.* TO 'ironbark_app'@'10.0.1.100';
-- FLUSH PRIVILEGES;

DROP TABLE IF EXISTS chat_logs;
DROP TABLE IF EXISTS engagements;
DROP TABLE IF EXISTS contact_submissions;
DROP TABLE IF EXISTS products;

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
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_session (session_id)
);

-- ---------------------------------------------------------------------------
-- Seed: 3 services + 3 products (matches IronBark business concept)
-- ---------------------------------------------------------------------------

INSERT INTO products (kind, slug, name, tagline, description, tags, price_tier, display_order) VALUES
('service', 'managed-pentesting',
 'Managed Penetration Testing',
 'Continuous, AI-driven red team assessments — 24/7.',
 'Continuous, AI-driven red team assessments of enterprise networks using autonomous hacking agents. Delivers scheduled vulnerability reports and real-time alerts via integrated communication platforms (Discord, Slack), giving clients around-the-clock security visibility without manual intervention. Engagements run on a monthly cadence with ad-hoc deep dives triggered by your team.',
 'AI,AUTOMATED,24/7,RED-TEAM',
 'Enterprise', 10),

('service', 'compliance-audit',
 'Compliance Auditing & Risk Assessment',
 'NIST, CMMC, DoD — scored, prioritized, actionable.',
 'Comprehensive network security audits aligned with NIST 800-171, CMMC 2.0, and DoD standards. We produce CSET-scored compliance reports with prioritized, actionable remediation guidance tailored to each organization''s risk profile and regulatory requirements. Deliverables include executive summary, technical findings, and a 30/60/90-day remediation plan.',
 'NIST,CMMC,CSET,COMPLIANCE',
 'Per engagement', 20),

('service', 'secure-deployment',
 'Secure Infrastructure Deployment',
 'Hardened environments, built secure from the ground up.',
 'End-to-end design and deployment of hardened enterprise environments — Active Directory, DNS, web servers, firewalls, and database systems — with security built in from the ground up, not bolted on afterward. Includes documentation, runbooks, and a 30-day post-deployment hypercare window.',
 'AD,DNS,FIREWALL,HARDENING',
 'Project-based', 30),

('product', 'clawd-agent',
 'ClaWD Autonomous Red Team Agent',
 'Self-hosted AI pentester. No humans required.',
 'A self-hosted AI-powered hacking agent that autonomously runs penetration tests on a schedule. Integrates natively with Discord and Slack for real-time alerts and on-demand scan commands. Generates structured vulnerability reports saved to shared directories — no manual oversight required. Runs on Kali Linux, orchestrates Nmap, Nikto, and Metasploit, and writes its findings in plain English.',
 'AUTONOMOUS,KALI,DISCORD',
 'Annual license', 40),

('product', 'securepack-appliance',
 'SecurePack SMB Network Appliance',
 'Plug-and-play red team hardware. One-time cost.',
 'A pre-configured physical security node loaded with Kali Linux, automated scan scheduling, and shared reporting infrastructure. Rapid deployment on any enterprise network segment. Hardware-on-network red team capability at a one-time cost with zero cloud restrictions. Ships with a 3-year hardware warranty and 1 year of firmware updates.',
 'HARDWARE,PLUG-AND-PLAY,NO-CLOUD',
 'One-time', 50),

('product', 'compliance-dashboard',
 'IronBark Compliance Dashboard',
 'Single pane of glass for security posture.',
 'A web-based reporting portal aggregating automated scan data, tracking remediation progress over time, and exporting presentation-ready compliance scorecards. Feeds directly from ClaWD scan results and CSET scoring — single pane of glass for security posture visibility. SSO-compatible, role-based access control, and air-gapped deployment option available.',
 'WEB-PORTAL,CSET,REPORTING',
 'Subscription', 60);

-- Sample engagements for /status demo
INSERT INTO engagements (engagement_code, client_email, client_company, service_type,
    status, last_scan_at, next_scan_at,
    findings_critical, findings_high, findings_medium, findings_low,
    remediation_percent, notes) VALUES
('IB-2026-0042', 'cto@northridge-mfg.example', 'Northridge Manufacturing',
 'Managed Penetration Testing', 'in_progress',
 '2026-04-10 02:00:00', '2026-05-08 02:00:00',
 0, 3, 7, 12, 67,
 'High-severity findings are all related to outdated Windows SMBv1. Remediation plan drafted.'),
('IB-2026-0051', 'security@ridgelineaero.example', 'Ridgeline Aerospace',
 'Compliance Auditing & Risk Assessment', 'reporting',
 '2026-04-01 09:00:00', NULL,
 1, 4, 11, 22, 25,
 'CMMC Level 2 audit in progress. Draft report under internal QA.'),
('IB-2026-0063', 'it@canyonhealthgroup.example', 'Canyon Health Group',
 'Secure Infrastructure Deployment', 'complete',
 '2026-03-22 14:00:00', '2026-06-22 14:00:00',
 0, 0, 2, 5, 100,
 'AD + DNS redesign complete. Post-deployment monitoring passed. Follow-up scan scheduled.');
