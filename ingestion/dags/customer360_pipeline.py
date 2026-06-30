# =============================================================================
# CUSTOMER360 INTELLIGENCE PLATFORM
# Airflow DAG: Daily Pipeline Orchestration
# Runs dbt staging models -> mart models -> audit logging
# =============================================================================

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator

default_args = {
    "owner": "customer360",
    "depends_on_past": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}

DBT_PROJECT_DIR = "/opt/airflow/scripts/dbt_project"

with DAG(
    dag_id="customer360_pipeline",
    description="Daily Customer360 Intelligence Platform pipeline",
    default_args=default_args,
    schedule_interval="@daily",
    start_date=datetime(2026, 6, 1),
    catchup=False,
    tags=["customer360", "dbt", "production"],
) as dag:

    run_staging_models = BashOperator(
        task_id="run_staging_models",
        bash_command=(
            "cd /opt/airflow/scripts/dbt_project && "
            "dbt run --select staging --profiles-dir /opt/airflow/scripts "
            "--log-path /tmp/dbt_logs --target-path /tmp/dbt_target"
        ),
    )

    run_mart_models = BashOperator(
        task_id="run_mart_models",
        bash_command=(
            "cd /opt/airflow/scripts/dbt_project && "
            "dbt run --select marts --profiles-dir /opt/airflow/scripts "
            "--log-path /tmp/dbt_logs --target-path /tmp/dbt_target"
        ),
    )

    run_dbt_tests = BashOperator(
        task_id="run_dbt_tests",
        bash_command=(
            "cd /opt/airflow/scripts/dbt_project && "
            "dbt test --profiles-dir /opt/airflow/scripts "
            "--log-path /tmp/dbt_logs --target-path /tmp/dbt_target"
        ),
    )

    def log_pipeline_run():
        import psycopg2
        conn = psycopg2.connect(
            host="postgres",
            port=5432,
            database="customer360",
            user="postgres",
            password="customer360"
        )
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO audit.pipeline_runs
            (pipeline_name, source_system, status, started_at, completed_at)
            VALUES (%s, %s, %s, NOW(), NOW())
        """, ("customer360_pipeline", "airflow", "success"))
        conn.commit()
        cursor.close()
        conn.close()

    log_run = PythonOperator(
        task_id="log_pipeline_run",
        python_callable=log_pipeline_run,
    )

    run_staging_models >> run_mart_models >> run_dbt_tests >> log_run