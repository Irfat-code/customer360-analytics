# =============================================================================
# CUSTOMER360 INTELLIGENCE PLATFORM
# Data Generation Script
# Generates realistic enterprise data for all raw tables
# =============================================================================

import random
import uuid
from datetime import datetime, timedelta
from faker import Faker
import psycopg2
from psycopg2.extras import execute_batch

fake = Faker()
random.seed(42)
Faker.seed(42)

# =============================================================================
# DATABASE CONNECTION
# =============================================================================
conn = psycopg2.connect(
    host="127.0.0.1",
    port=5432,
    database="customer360",
    user="postgres",
    password="customer360"
)
cursor = conn.cursor()

print("Connected to customer360 database.")

# =============================================================================
# CONFIGURATION
# =============================================================================
NUM_COMPANIES       = 200
NUM_CONTACTS        = 600
NUM_SUBSCRIPTIONS   = 200
NUM_INVOICES        = 800
NUM_TICKETS         = 1000
NUM_SESSIONS        = 5000
NUM_FEATURE_EVENTS  = 8000
NUM_CAMPAIGNS       = 30
NUM_EMAIL_EVENTS    = 6000
NUM_NPS_RESPONSES   = 500

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================
def random_date(start_days_ago=730, end_days_ago=0):
    start = datetime.now() - timedelta(days=start_days_ago)
    end   = datetime.now() - timedelta(days=end_days_ago)
    return start + (end - start) * random.random()

def random_id():
    return str(uuid.uuid4())[:8].upper()

# =============================================================================
# GENERATE COMPANIES
# =============================================================================
print("Generating companies...")

industries = ["SaaS", "FinTech", "HealthTech", "E-Commerce", "EdTech",
              "Manufacturing", "Retail", "Logistics", "Media", "Consulting"]
tiers      = ["Enterprise", "Mid-Market", "SMB", "Startup"]
statuses   = ["Active", "Churned", "At-Risk", "New"]

companies = []
company_ids = []

for _ in range(NUM_COMPANIES):
    cid = f"COM-{random_id()}"
    company_ids.append(cid)
    companies.append((
        cid,
        fake.company(),
        random.choice(industries),
        fake.country(),
        fake.city(),
        random.randint(10, 10000),
        round(random.uniform(100000, 50000000), 2),
        random.choice(tiers),
        random.choice(statuses),
        f"OWN-{random_id()}",
        random_date(730, 365),
        random_date(30, 0)
    ))

execute_batch(cursor, """
    INSERT INTO raw.companies
    (id, name, industry, country, city, employee_count, annual_revenue,
     tier, status, owner_id, created_at, updated_at)
    VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
    ON CONFLICT (id) DO NOTHING
""", companies)
conn.commit()
print(f"  {len(companies)} companies inserted.")

# =============================================================================
# GENERATE CONTACTS
# =============================================================================
print("Generating contacts...")

departments = ["Engineering", "Sales", "Marketing", "Finance",
               "Operations", "HR", "Product", "Support"]
job_titles  = ["CEO", "CTO", "VP of Sales", "Director", "Manager",
               "Analyst", "Engineer", "Specialist"]

contacts = []
contact_ids = []

for i in range(NUM_CONTACTS):
    coid = f"CON-{random_id()}"
    contact_ids.append(coid)
    contacts.append((
        coid,
        random.choice(company_ids),
        fake.first_name(),
        fake.last_name(),
        fake.email(),
        fake.phone_number()[:20],
        random.choice(job_titles),
        random.choice(departments),
        i % 3 == 0,
        random_date(730, 365),
        random_date(30, 0)
    ))

execute_batch(cursor, """
    INSERT INTO raw.contacts
    (id, company_id, first_name, last_name, email, phone,
     job_title, department, is_primary, created_at, updated_at)
    VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
    ON CONFLICT (id) DO NOTHING
""", contacts)
conn.commit()
print(f"  {len(contacts)} contacts inserted.")

# =============================================================================
# GENERATE SUBSCRIPTIONS
# =============================================================================
print("Generating subscriptions...")

plans = [
    ("Starter",    "SMB",        500,    6000),
    ("Growth",     "Mid-Market", 2000,   24000),
    ("Business",   "Mid-Market", 5000,   60000),
    ("Enterprise", "Enterprise", 15000,  180000),
    ("Ultimate",   "Enterprise", 50000,  600000),
]
sub_statuses = ["Active", "Cancelled", "Expired", "Trial"]

subscriptions = []
subscription_ids = []

for _ in range(NUM_SUBSCRIPTIONS):
    sid      = f"SUB-{random_id()}"
    plan     = random.choice(plans)
    status   = random.choice(sub_statuses)
    start    = random_date(730, 30)
    renewed  = start + timedelta(days=365)
    expires  = renewed + timedelta(days=365)
    cancelled = start + timedelta(days=random.randint(30, 300)) if status == "Cancelled" else None

    subscription_ids.append(sid)
    subscriptions.append((
        sid,
        random.choice(company_ids),
        plan[0], plan[1],
        status,
        plan[2], plan[3],
        "USD",
        start, renewed, expires, cancelled,
        start, random_date(30, 0)
    ))

execute_batch(cursor, """
    INSERT INTO raw.subscriptions
    (id, company_id, plan_name, plan_tier, status, mrr, arr, currency,
     started_at, renewed_at, expires_at, cancelled_at, created_at, updated_at)
    VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
    ON CONFLICT (id) DO NOTHING
""", subscriptions)
conn.commit()
print(f"  {len(subscriptions)} subscriptions inserted.")

# =============================================================================
# GENERATE INVOICES
# =============================================================================
print("Generating invoices...")

inv_statuses = ["Paid", "Unpaid", "Overdue", "Refunded"]

invoices = []
for _ in range(NUM_INVOICES):
    status   = random.choice(inv_statuses)
    due_date = random_date(365, 0).date()
    paid_date = due_date + timedelta(days=random.randint(0, 15)) if status == "Paid" else None
    invoices.append((
        f"INV-{random_id()}",
        random.choice(company_ids),
        random.choice(subscription_ids),
        round(random.uniform(500, 50000), 2),
        "USD",
        status,
        due_date,
        paid_date,
        random_date(400, 0)
    ))

execute_batch(cursor, """
    INSERT INTO raw.invoices
    (id, company_id, subscription_id, amount, currency,
     status, due_date, paid_date, created_at)
    VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
    ON CONFLICT (id) DO NOTHING
""", invoices)
conn.commit()
print(f"  {len(invoices)} invoices inserted.")

# =============================================================================
# GENERATE SUPPORT TICKETS
# =============================================================================
print("Generating support tickets...")

priorities   = ["Low", "Medium", "High", "Critical"]
categories   = ["Billing", "Technical", "Onboarding", "Feature Request", "Bug"]
channels     = ["Email", "Chat", "Phone", "Portal"]
ticket_statuses = ["Open", "In Progress", "Resolved", "Closed"]

tickets = []
for _ in range(NUM_TICKETS):
    created  = random_date(365, 0)
    first_r  = created + timedelta(hours=random.randint(1, 48))
    resolved = first_r + timedelta(hours=random.randint(1, 168))
    status   = random.choice(ticket_statuses)
    closed   = resolved + timedelta(hours=2) if status == "Closed" else None

    tickets.append((
        f"TKT-{random_id()}",
        random.choice(company_ids),
        random.choice(contact_ids),
        fake.sentence(nb_words=8),
        fake.paragraph(nb_sentences=3),
        status,
        random.choice(priorities),
        random.choice(categories),
        random.choice(channels),
        fake.name(),
        created, first_r, resolved, closed,
        random.randint(1, 5)
    ))

execute_batch(cursor, """
    INSERT INTO raw.support_tickets
    (id, company_id, contact_id, subject, description, status, priority,
     category, channel, assigned_to, created_at, first_response_at,
     resolved_at, closed_at, satisfaction_score)
    VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
    ON CONFLICT (id) DO NOTHING
""", tickets)
conn.commit()
print(f"  {len(tickets)} support tickets inserted.")

# =============================================================================
# GENERATE PRODUCT SESSIONS
# =============================================================================
print("Generating product sessions...")

devices = ["Desktop", "Mobile", "Tablet"]

sessions = []
for _ in range(NUM_SESSIONS):
    sessions.append((
        f"SES-{random_id()}",
        random.choice(company_ids),
        random.choice(contact_ids),
        random_date(180, 0).date(),
        random.randint(30, 3600),
        random.randint(1, 50),
        random.randint(1, 100),
        random.choice(devices),
        random_date(180, 0)
    ))

execute_batch(cursor, """
    INSERT INTO raw.product_sessions
    (id, company_id, contact_id, session_date, duration_seconds,
     page_views, actions_count, device_type, created_at)
    VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
    ON CONFLICT (id) DO NOTHING
""", sessions)
conn.commit()
print(f"  {len(sessions)} product sessions inserted.")

# =============================================================================
# GENERATE FEATURE EVENTS
# =============================================================================
print("Generating feature events...")

features    = ["Dashboard", "Reports", "API", "Integrations", "Billing Portal",
               "User Management", "Analytics", "Exports", "Alerts", "Settings"]
event_types = ["viewed", "clicked", "created", "deleted", "exported", "shared"]

feature_events = []
for _ in range(NUM_FEATURE_EVENTS):
    feature_events.append((
        f"FEV-{random_id()}",
        random.choice(company_ids),
        random.choice(contact_ids),
        random.choice(features),
        random.choice(event_types),
        random_date(180, 0).date(),
        '{}',
        random_date(180, 0)
    ))

execute_batch(cursor, """
    INSERT INTO raw.feature_events
    (id, company_id, contact_id, feature_name, event_type,
     event_date, properties, created_at)
    VALUES (%s,%s,%s,%s,%s,%s,%s::jsonb,%s)
    ON CONFLICT (id) DO NOTHING
""", feature_events)
conn.commit()
print(f"  {len(feature_events)} feature events inserted.")

# =============================================================================
# GENERATE CAMPAIGNS
# =============================================================================
print("Generating campaigns...")

campaign_types    = ["Email", "Webinar", "In-App", "Social", "Paid"]
campaign_statuses = ["Active", "Completed", "Draft", "Paused"]
segments          = ["All Users", "Enterprise", "At-Risk", "New Users", "Power Users"]

campaigns = []
campaign_ids = []

for _ in range(NUM_CAMPAIGNS):
    cid   = f"CAM-{random_id()}"
    start = random_date(365, 30).date()
    end   = start + timedelta(days=random.randint(7, 60))
    campaign_ids.append(cid)
    campaigns.append((
        cid,
        fake.catch_phrase(),
        random.choice(campaign_types),
        random.choice(campaign_statuses),
        random.choice(campaign_types),
        random.choice(segments),
        round(random.uniform(1000, 50000), 2),
        start, end,
        random_date(365, 30)
    ))

execute_batch(cursor, """
    INSERT INTO raw.campaigns
    (id, name, type, status, channel, target_segment,
     budget, started_at, ended_at, created_at)
    VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
    ON CONFLICT (id) DO NOTHING
""", campaigns)
conn.commit()
print(f"  {len(campaigns)} campaigns inserted.")

# =============================================================================
# GENERATE EMAIL EVENTS
# =============================================================================
print("Generating email events...")

email_event_types = ["sent", "delivered", "opened", "clicked", "bounced", "unsubscribed"]

email_events = []
for _ in range(NUM_EMAIL_EVENTS):
    email_events.append((
        f"EML-{random_id()}",
        random.choice(campaign_ids),
        random.choice(contact_ids),
        random.choice(company_ids),
        random.choice(email_event_types),
        random_date(365, 0)
    ))

execute_batch(cursor, """
    INSERT INTO raw.email_events
    (id, campaign_id, contact_id, company_id, event_type, event_timestamp)
    VALUES (%s,%s,%s,%s,%s,%s)
    ON CONFLICT (id) DO NOTHING
""", email_events)
conn.commit()
print(f"  {len(email_events)} email events inserted.")

# =============================================================================
# GENERATE NPS RESPONSES
# =============================================================================
print("Generating NPS responses...")

nps_responses = []
for _ in range(NUM_NPS_RESPONSES):
    score    = random.randint(0, 10)
    category = "Promoter" if score >= 9 else "Passive" if score >= 7 else "Detractor"
    nps_responses.append((
        f"NPS-{random_id()}",
        random.choice(company_ids),
        random.choice(contact_ids),
        score,
        category,
        fake.sentence(nb_words=12),
        random_date(365, 0).date(),
        random_date(365, 0)
    ))

execute_batch(cursor, """
    INSERT INTO raw.nps_responses
    (id, company_id, contact_id, score, category,
     comment, survey_date, created_at)
    VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
    ON CONFLICT (id) DO NOTHING
""", nps_responses)
conn.commit()
print(f"  {len(nps_responses)} NPS responses inserted.")

# =============================================================================
# SUMMARY
# =============================================================================
cursor.close()
conn.close()

print("\n" + "="*60)
print("DATA GENERATION COMPLETE")
print("="*60)
print(f"  Companies:       {NUM_COMPANIES}")
print(f"  Contacts:        {NUM_CONTACTS}")
print(f"  Subscriptions:   {NUM_SUBSCRIPTIONS}")
print(f"  Invoices:        {NUM_INVOICES}")
print(f"  Support Tickets: {NUM_TICKETS}")
print(f"  Sessions:        {NUM_SESSIONS}")
print(f"  Feature Events:  {NUM_FEATURE_EVENTS}")
print(f"  Campaigns:       {NUM_CAMPAIGNS}")
print(f"  Email Events:    {NUM_EMAIL_EVENTS}")
print(f"  NPS Responses:   {NUM_NPS_RESPONSES}")
print("="*60)