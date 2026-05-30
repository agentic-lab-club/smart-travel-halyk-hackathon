"""PostgreSQL connection helper for analytics_db."""
import os
from contextlib import contextmanager

import psycopg2
from dotenv import load_dotenv

load_dotenv()

DEFAULT_DB_URL = (
    "postgresql://analytics:analytics_pass@localhost:5432/analytics_db"
)


def get_connection_string() -> str:
    return os.getenv("DATABASE_URL", DEFAULT_DB_URL)


def get_connection():
    return psycopg2.connect(get_connection_string())


@contextmanager
def get_cursor(commit: bool = False):
    conn = get_connection()
    cur = conn.cursor()
    try:
        yield cur
        if commit:
            conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        cur.close()
        conn.close()


def init_db():
    """Runs init.sql against the database (idempotent)."""
    script_path = os.path.join(os.path.dirname(__file__), "..", "db", "init.sql")
    with open(script_path, "r", encoding="utf-8") as f:
        sql = f.read()
    with get_cursor(commit=True) as cur:
        cur.execute(sql)


if __name__ == "__main__":
    init_db()
    print("Database initialized successfully.")
