import logging
import os
from pathlib import Path

import psycopg
from psycopg import sql
from dotenv import load_dotenv


BASE_DIR = Path(__file__).resolve().parent.parent
SQL_DIR = BASE_DIR / "sql"

load_dotenv(BASE_DIR / ".env")

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
)


def get_connection():
    return psycopg.connect(
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT", "5432"),
        dbname=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
    )


def execute_sql_file(cursor, filename: str):
    path = SQL_DIR / filename
    logging.info("Executing %s", filename)
    cursor.execute(path.read_text(encoding="utf-8"))


def get_row_count(cursor, table_name: str) -> int:
    query = sql.SQL("SELECT COUNT(*) FROM {}").format(
        sql.Identifier(table_name)
    )
    cursor.execute(query)
    return cursor.fetchone()[0]

# coalesce: handle NULL values to return 0 if there are no rows in the table
def get_total_amount(cursor, table_name: str):
    query = sql.SQL(
        "SELECT COALESCE(SUM(amount), 0) FROM {}"
    ).format(sql.Identifier(table_name))
    cursor.execute(query)
    return cursor.fetchone()[0]


def validate_ready_split(cursor):
    source_customer_count = get_row_count(cursor, "clean_customers")
    ready_customer_count = get_row_count(cursor, "migration_ready_customers")
    rejected_customer_count = get_row_count(cursor, "rejected_customers")

    if source_customer_count != ready_customer_count + rejected_customer_count:
        raise ValueError(
            "Customer split reconciliation failed: "
            f"{source_customer_count} != "
            f"{ready_customer_count} + {rejected_customer_count}"
        )

    source_order_count = get_row_count(cursor, "legacy_orders")
    ready_order_count = get_row_count(cursor, "migration_ready_orders")
    rejected_order_count = get_row_count(cursor, "rejected_orders")

    if source_order_count != ready_order_count + rejected_order_count:
        raise ValueError(
            "Order split reconciliation failed: "
            f"{source_order_count} != "
            f"{ready_order_count} + {rejected_order_count}"
        )

    source_amount = get_total_amount(cursor, "legacy_orders")
    ready_amount = get_total_amount(cursor, "migration_ready_orders")
    rejected_amount = get_total_amount(cursor, "rejected_orders")

    if source_amount != ready_amount + rejected_amount:
        raise ValueError(
            "Order amount reconciliation failed: "
            f"{source_amount} != {ready_amount} + {rejected_amount}"
        )

    logging.info(
        "Pre-migration validation passed: customers=%s ready=%s rejected=%s; "
        "orders=%s ready=%s rejected=%s",
        source_customer_count,
        ready_customer_count,
        rejected_customer_count,
        source_order_count,
        ready_order_count,
        rejected_order_count,
    )


def validate_staging(cursor):
    cursor.execute("""
        SELECT customer_id
        FROM staging_customers
        GROUP BY customer_id
        HAVING COUNT(*) > 1
    """)
    duplicate_customers = cursor.fetchall()
    if duplicate_customers:
        raise ValueError(
            f"Duplicate customers found in staging: {duplicate_customers}"
        )

    cursor.execute("""
        SELECT order_id
        FROM staging_orders
        GROUP BY order_id
        HAVING COUNT(*) > 1
    """)
    duplicate_orders = cursor.fetchall()
    if duplicate_orders:
        raise ValueError(
            f"Duplicate orders found in staging: {duplicate_orders}"
        )

    cursor.execute("""
        SELECT o.order_id
        FROM staging_orders o
        LEFT JOIN staging_customers c
            ON o.customer_id = c.customer_id
        WHERE c.customer_id IS NULL
    """)
    orphans = cursor.fetchall()
    if orphans:
        raise ValueError(
            f"Orphan orders found in staging: {orphans}"
        )

    logging.info("Staging validation passed.")


def reset_target_tables(cursor):
    cursor.execute("TRUNCATE TABLE target_orders")
    cursor.execute("TRUNCATE TABLE target_customers")


def load_target(cursor):
    cursor.execute("""
        INSERT INTO target_customers (
            customer_id,
            name,
            email,
            city,
            updated_at
        )
        SELECT
            customer_id,
            name,
            email,
            city,
            updated_at
        FROM staging_customers
    """)

    cursor.execute("""
        INSERT INTO target_orders (
            order_id,
            customer_id,
            order_date,
            amount
        )
        SELECT
            order_id,
            customer_id,
            order_date,
            amount
        FROM staging_orders
    """)


def validate_target(cursor):
    checks = [
        (
            "customer row count",
            get_row_count(cursor, "staging_customers"),
            get_row_count(cursor, "target_customers"),
        ),
        (
            "order row count",
            get_row_count(cursor, "staging_orders"),
            get_row_count(cursor, "target_orders"),
        ),
        (
            "order amount",
            get_total_amount(cursor, "staging_orders"),
            get_total_amount(cursor, "target_orders"),
        ),
    ]

    for check_name, expected, actual in checks:
        if expected != actual:
            raise ValueError(
                f"Post-migration {check_name} failed: "
                f"expected={expected}, actual={actual}"
            )

    cursor.execute("""
        SELECT s.order_id
        FROM staging_orders s
        LEFT JOIN target_orders t
            ON s.order_id = t.order_id
        WHERE t.order_id IS NULL
    """)
    missing_orders = cursor.fetchall()

    if missing_orders:
        raise ValueError(
            f"Orders missing from target: {missing_orders}"
        )

    cursor.execute("""
        SELECT
            s.order_id,
            s.customer_id AS staging_customer_id,
            t.customer_id AS target_customer_id,
            s.amount AS staging_amount,
            t.amount AS target_amount
        FROM staging_orders s
        JOIN target_orders t
            ON s.order_id = t.order_id
        WHERE s.customer_id IS DISTINCT FROM t.customer_id
           OR s.amount IS DISTINCT FROM t.amount
    """)
    mismatches = cursor.fetchall()

    if mismatches:
        raise ValueError(
            f"Target data mismatches found: {mismatches}"
        )

    logging.info("Post-migration validation passed.")


def run_pipeline():
    with get_connection() as conn:
        try:
            with conn.cursor() as cursor:
                execute_sql_file(cursor, "04_prepare_customers.sql")
                execute_sql_file(cursor, "05_prepare_orders.sql")
                execute_sql_file(cursor, "06_build_staging.sql")
                execute_sql_file(cursor, "07_create_target_tables.sql")

                validate_ready_split(cursor)
                validate_staging(cursor)

                logging.info("Resetting target tables.")
                reset_target_tables(cursor)

                logging.info("Loading target tables.")
                load_target(cursor)

                validate_target(cursor)

            conn.commit()
            logging.info("Migration completed successfully.")

        except Exception:
            conn.rollback()
            logging.exception(
                "Migration failed. Transaction rolled back."
            )
            raise


if __name__ == "__main__":
    run_pipeline()
