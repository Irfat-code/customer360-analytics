-- =============================================================================
-- CUSTOMER360 INTELLIGENCE PLATFORM
-- Raw Layer Tables
-- Data lands here exactly as it comes from source systems
-- =============================================================================

-- ---------------------------------------------------------------------------
-- CRM: Companies and Contacts
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS raw.companies (
    id                  VARCHAR(50) PRIMARY KEY,
    name                VARCHAR(255) NOT NULL,
    industry            VARCHAR(100),
    country             VARCHAR(100),
    city                VARCHAR(100),
    employee_count      INTEGER,
    annual_revenue      NUMERIC(15,2),
    tier                VARCHAR(20),
    status              VARCHAR(20),
    owner_id            VARCHAR(50),
    created_at          TIMESTAMP,
    updated_at          TIMESTAMP,
    _ingested_at        TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.contacts (
    id                  VARCHAR(50) PRIMARY KEY,
    company_id          VARCHAR(50),
    first_name          VARCHAR(100),
    last_name           VARCHAR(100),
    email               VARCHAR(255),
    phone               VARCHAR(50),
    job_title           VARCHAR(150),
    department          VARCHAR(100),
    is_primary          BOOLEAN DEFAULT FALSE,
    created_at          TIMESTAMP,
    updated_at          TIMESTAMP,
    _ingested_at        TIMESTAMP DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- BILLING: Subscriptions and Invoices
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS raw.subscriptions (
    id                  VARCHAR(50) PRIMARY KEY,
    company_id          VARCHAR(50),
    plan_name           VARCHAR(100),
    plan_tier           VARCHAR(50),
    status              VARCHAR(30),
    mrr                 NUMERIC(12,2),
    arr                 NUMERIC(12,2),
    currency            VARCHAR(10) DEFAULT 'USD',
    started_at          TIMESTAMP,
    renewed_at          TIMESTAMP,
    expires_at          TIMESTAMP,
    cancelled_at        TIMESTAMP,
    created_at          TIMESTAMP,
    updated_at          TIMESTAMP,
    _ingested_at        TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.invoices (
    id                  VARCHAR(50) PRIMARY KEY,
    company_id          VARCHAR(50),
    subscription_id     VARCHAR(50),
    amount              NUMERIC(12,2),
    currency            VARCHAR(10) DEFAULT 'USD',
    status              VARCHAR(30),
    due_date            DATE,
    paid_date           DATE,
    created_at          TIMESTAMP,
    _ingested_at        TIMESTAMP DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- SUPPORT: Tickets
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS raw.support_tickets (
    id                  VARCHAR(50) PRIMARY KEY,
    company_id          VARCHAR(50),
    contact_id          VARCHAR(50),
    subject             VARCHAR(500),
    description         TEXT,
    status              VARCHAR(30),
    priority            VARCHAR(20),
    category            VARCHAR(100),
    channel             VARCHAR(50),
    assigned_to         VARCHAR(100),
    created_at          TIMESTAMP,
    first_response_at   TIMESTAMP,
    resolved_at         TIMESTAMP,
    closed_at           TIMESTAMP,
    satisfaction_score  INTEGER,
    _ingested_at        TIMESTAMP DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- PRODUCT USAGE: Sessions and Feature Events
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS raw.product_sessions (
    id                  VARCHAR(50) PRIMARY KEY,
    company_id          VARCHAR(50),
    contact_id          VARCHAR(50),
    session_date        DATE,
    duration_seconds    INTEGER,
    page_views          INTEGER,
    actions_count       INTEGER,
    device_type         VARCHAR(50),
    created_at          TIMESTAMP,
    _ingested_at        TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.feature_events (
    id                  VARCHAR(50) PRIMARY KEY,
    company_id          VARCHAR(50),
    contact_id          VARCHAR(50),
    feature_name        VARCHAR(150),
    event_type          VARCHAR(100),
    event_date          DATE,
    properties          JSONB,
    created_at          TIMESTAMP,
    _ingested_at        TIMESTAMP DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- MARKETING: Campaigns and Emails
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS raw.campaigns (
    id                  VARCHAR(50) PRIMARY KEY,
    name                VARCHAR(255),
    type                VARCHAR(100),
    status              VARCHAR(30),
    channel             VARCHAR(50),
    target_segment      VARCHAR(100),
    budget              NUMERIC(12,2),
    started_at          DATE,
    ended_at            DATE,
    created_at          TIMESTAMP,
    _ingested_at        TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw.email_events (
    id                  VARCHAR(50) PRIMARY KEY,
    campaign_id         VARCHAR(50),
    contact_id          VARCHAR(50),
    company_id          VARCHAR(50),
    event_type          VARCHAR(50),
    event_timestamp     TIMESTAMP,
    _ingested_at        TIMESTAMP DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- SURVEYS: NPS Responses
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS raw.nps_responses (
    id                  VARCHAR(50) PRIMARY KEY,
    company_id          VARCHAR(50),
    contact_id          VARCHAR(50),
    score               INTEGER CHECK (score BETWEEN 0 AND 10),
    category            VARCHAR(20),
    comment             TEXT,
    survey_date         DATE,
    created_at          TIMESTAMP,
    _ingested_at        TIMESTAMP DEFAULT NOW()
);