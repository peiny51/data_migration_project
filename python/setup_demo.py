import logging
from pathlib import Path

from migrate import get_connection, execute_sql_file


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
)


def main():
    with get_connection() as conn:
        try:
            with conn.cursor() as cursor:
                execute_sql_file(cursor, "01_create_source_tables.sql")
                execute_sql_file(cursor, "02_seed_source_data.sql")
            conn.commit()
            logging.info("Demo source data created successfully.")
        except Exception:
            conn.rollback()
            logging.exception("Demo setup failed.")
            raise


if __name__ == "__main__":
    main()
