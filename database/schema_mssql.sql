-- IronBark Security Solutions — Microsoft SQL Server schema
-- Run on the Database VM (10.0.1.200) if using MSSQL

IF DB_ID('ironbark') IS NULL
    CREATE DATABASE ironbark;
GO

USE ironbark;
GO

IF OBJECT_ID('chat_logs', 'U') IS NOT NULL DROP TABLE chat_logs;
IF OBJECT_ID('engagements', 'U') IS NOT NULL DROP TABLE engagements;
IF OBJECT_ID('contact_submissions', 'U') IS NOT NULL DROP TABLE contact_submissions;
IF OBJECT_ID('products', 'U') IS NOT NULL DROP TABLE products;
GO

CREATE TABLE products (
    id INT IDENTITY(1,1) PRIMARY KEY,
    kind VARCHAR(16) NOT NULL CHECK (kind IN ('service','product')),
    slug VARCHAR(64) UNIQUE NOT NULL,
    name NVARCHAR(128) NOT NULL,
    tagline NVARCHAR(255),
    description NVARCHAR(MAX) NOT NULL,
    tags NVARCHAR(255),
    price_tier NVARCHAR(32),
    display_order INT DEFAULT 0,
    active BIT DEFAULT 1
);

CREATE TABLE contact_submissions (
    id INT IDENTITY(1,1) PRIMARY KEY,
    submitted_at DATETIME DEFAULT GETDATE(),
    name NVARCHAR(128) NOT NULL,
    email NVARCHAR(255) NOT NULL,
    company NVARCHAR(128),
    message NVARCHAR(MAX) NOT NULL,
    source_ip VARCHAR(45)
);

CREATE TABLE engagements (
    id INT IDENTITY(1,1) PRIMARY KEY,
    engagement_code VARCHAR(32) UNIQUE NOT NULL,
    client_email NVARCHAR(255) NOT NULL,
    client_company NVARCHAR(128) NOT NULL,
    service_type NVARCHAR(64) NOT NULL,
    status VARCHAR(16) NOT NULL CHECK (status IN ('scheduled','in_progress','reporting','complete')),
    last_scan_at DATETIME NULL,
    next_scan_at DATETIME NULL,
    findings_critical INT DEFAULT 0,
    findings_high INT DEFAULT 0,
    findings_medium INT DEFAULT 0,
    findings_low INT DEFAULT 0,
    remediation_percent INT DEFAULT 0,
    notes NVARCHAR(MAX)
);

CREATE TABLE chat_logs (
    id INT IDENTITY(1,1) PRIMARY KEY,
    session_id VARCHAR(64) NOT NULL,
    role VARCHAR(16) NOT NULL CHECK (role IN ('user','assistant')),
    content NVARCHAR(MAX) NOT NULL,
    created_at DATETIME DEFAULT GETDATE()
);
CREATE INDEX idx_chat_session ON chat_logs(session_id);
GO

-- Seed data
INSERT INTO products (kind, slug, name, tagline, description, tags, price_tier, display_order) VALUES
('service','managed-pentesting','Managed Penetration Testing','Continuous, AI-driven red team assessments — 24/7.','Continuous, AI-driven red team assessments of enterprise networks using autonomous hacking agents. Delivers scheduled vulnerability reports and real-time alerts via integrated communication platforms (Discord, Slack), giving clients around-the-clock security visibility without manual intervention.','AI,AUTOMATED,24/7,RED-TEAM','Enterprise',10),
('service','compliance-audit','Compliance Auditing & Risk Assessment','NIST, CMMC, DoD — scored, prioritized, actionable.','Comprehensive network security audits aligned with NIST 800-171, CMMC 2.0, and DoD standards. Produces CSET-scored compliance reports with prioritized, actionable remediation guidance.','NIST,CMMC,CSET,COMPLIANCE','Per engagement',20),
('service','secure-deployment','Secure Infrastructure Deployment','Hardened environments, built secure from the ground up.','End-to-end design and deployment of hardened enterprise environments — Active Directory, DNS, web servers, firewalls, and database systems — with security built in from the ground up.','AD,DNS,FIREWALL,HARDENING','Project-based',30),
('product','clawd-agent','ClaWD Autonomous Red Team Agent','Self-hosted AI pentester. No humans required.','A self-hosted AI-powered hacking agent that autonomously runs penetration tests on a schedule. Integrates natively with Discord and Slack for real-time alerts and on-demand scan commands.','AUTONOMOUS,KALI,DISCORD','Annual license',40),
('product','securepack-appliance','SecurePack SMB Network Appliance','Plug-and-play red team hardware. One-time cost.','A pre-configured physical security node loaded with Kali Linux, automated scan scheduling, and shared reporting infrastructure.','HARDWARE,PLUG-AND-PLAY,NO-CLOUD','One-time',50),
('product','compliance-dashboard','IronBark Compliance Dashboard','Single pane of glass for security posture.','A web-based reporting portal aggregating automated scan data, tracking remediation progress over time, and exporting presentation-ready compliance scorecards.','WEB-PORTAL,CSET,REPORTING','Subscription',60);

INSERT INTO engagements (engagement_code, client_email, client_company, service_type, status, last_scan_at, next_scan_at, findings_critical, findings_high, findings_medium, findings_low, remediation_percent, notes) VALUES
('IB-2026-0042','cto@northridge-mfg.example','Northridge Manufacturing','Managed Penetration Testing','in_progress','2026-04-10 02:00:00','2026-05-08 02:00:00',0,3,7,12,67,'High-severity findings are all related to outdated Windows SMBv1.'),
('IB-2026-0051','security@ridgelineaero.example','Ridgeline Aerospace','Compliance Auditing & Risk Assessment','reporting','2026-04-01 09:00:00',NULL,1,4,11,22,25,'CMMC Level 2 audit in progress.'),
('IB-2026-0063','it@canyonhealthgroup.example','Canyon Health Group','Secure Infrastructure Deployment','complete','2026-03-22 14:00:00','2026-06-22 14:00:00',0,0,2,5,100,'AD + DNS redesign complete.');
