# Running Locally

## Prerequisites
- Docker Desktop
- Python 3.11+
- Git

## Setup

```bash
git clone https://github.com/Irfat-code/customer360-analytics.git
cd customer360-analytics

# Start all services
docker compose up -d

# Wait for PostgreSQL to be healthy, then generate data
python scripts/generate_data.py

# Build the dbt models
docker exec -it c360_dbt bash -c "cd /usr/app/dbt/customer360 && dbt run"

# Run data quality tests
docker exec -it c360_dbt bash -c "cd /usr/app/dbt/customer360 && dbt test"
```

## Services

| Service | URL | Credentials |
|---|---|---|
| Airflow | http://localhost:8080 | admin / admin |
| Metabase | http://localhost:3000 | set on first visit |
| PostgreSQL | localhost:5432 | postgres / customer360 |

## Running the full pipeline

```bash
docker exec -it c360_airflow_webserver airflow dags trigger customer360_pipeline
```

## Stopping

```bash
docker compose down
```

To also remove all data volumes (full reset):

```bash
docker compose down -v
```