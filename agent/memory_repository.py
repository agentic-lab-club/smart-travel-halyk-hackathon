"""Persistence helpers for agent answer memory."""

from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal
from typing import Any
from uuid import UUID

from db import get_connection

AGENT_MEMORY_LIMIT = 5


def session_key(session_id: str) -> str:
    return session_id.strip()


def init_agent_memory_tables(cur) -> None:
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS agent_chat_sessions (
            session_id UUID PRIMARY KEY,
            user_id BIGINT NOT NULL,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );

        CREATE TABLE IF NOT EXISTS agent_chat_messages (
            id BIGSERIAL PRIMARY KEY,
            session_id UUID NOT NULL
                REFERENCES agent_chat_sessions(session_id) ON DELETE CASCADE,
            user_id BIGINT NOT NULL,
            role VARCHAR(32) NOT NULL CHECK (role IN ('user', 'assistant')),
            content TEXT NOT NULL,
            input_text TEXT,
            answer TEXT,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );

        CREATE INDEX IF NOT EXISTS idx_agent_chat_messages_session_user_created
            ON agent_chat_messages(session_id, user_id, created_at DESC, id DESC);

        CREATE INDEX IF NOT EXISTS idx_agent_chat_messages_assistant_memory
            ON agent_chat_messages(user_id, session_id, role, id DESC);
        """
    )


def _jsonable_rows(rows) -> list[dict[str, Any]]:
    result = []
    for row in rows:
        clean_row = {}
        for key, value in dict(row).items():
            if isinstance(value, Decimal):
                value = float(value)
            elif isinstance(value, (datetime, date)):
                value = value.isoformat()
            elif isinstance(value, UUID):
                value = str(value)
            clean_row[key] = value
        result.append(clean_row)
    return result


def _fetch_rows(cur, sql: str, params: dict[str, Any]) -> list[dict[str, Any]]:
    cur.execute(sql, params)
    return _jsonable_rows(cur.fetchall())


def fetch_answer_memory(user_id: int, session_id: str) -> list[dict[str, Any]]:
    from psycopg2.extras import RealDictCursor

    normalized_session = session_key(session_id)
    conn = get_connection()
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            init_agent_memory_tables(cur)
            rows = _fetch_rows(
                cur,
                """
                SELECT
                    id,
                    user_id,
                    session_id::text AS session_id,
                    input_text,
                    answer,
                    created_at
                FROM agent_chat_messages
                WHERE user_id = %(user_id)s
                  AND session_id = %(session_id)s::uuid
                  AND role = 'assistant'
                ORDER BY id DESC
                LIMIT %(limit)s;
                """,
                {
                    "user_id": user_id,
                    "session_id": normalized_session,
                    "limit": AGENT_MEMORY_LIMIT,
                },
            )
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

    return list(reversed(rows))


def fetch_session_messages(user_id: int, session_id: str, limit: int = 50) -> list[dict[str, Any]]:
    from psycopg2.extras import RealDictCursor

    normalized_session = session_key(session_id)
    conn = get_connection()
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            init_agent_memory_tables(cur)
            rows = _fetch_rows(
                cur,
                """
                SELECT
                    id,
                    user_id,
                    session_id::text AS session_id,
                    role,
                    content,
                    input_text,
                    answer,
                    created_at
                FROM agent_chat_messages
                WHERE user_id = %(user_id)s
                  AND session_id = %(session_id)s::uuid
                ORDER BY id DESC
                LIMIT %(limit)s;
                """,
                {
                    "user_id": user_id,
                    "session_id": normalized_session,
                    "limit": limit,
                },
            )
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

    return list(reversed(rows))


def save_answer_memory(
    user_id: int,
    session_id: str,
    input_text: str,
    answer: str,
) -> list[dict[str, Any]]:
    normalized_session = session_key(session_id)
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            init_agent_memory_tables(cur)
            cur.execute(
                """
                INSERT INTO agent_chat_sessions (session_id, user_id)
                VALUES (%(session_id)s::uuid, %(user_id)s)
                ON CONFLICT (session_id) DO UPDATE SET
                    user_id = EXCLUDED.user_id,
                    updated_at = NOW();
                """,
                {"session_id": normalized_session, "user_id": user_id},
            )
            cur.execute(
                """
                INSERT INTO agent_chat_messages (
                    session_id,
                    user_id,
                    role,
                    content,
                    input_text,
                    answer
                )
                VALUES
                    (
                        %(session_id)s::uuid,
                        %(user_id)s,
                        'user',
                        %(input_text)s,
                        %(input_text)s,
                        NULL
                    ),
                    (
                        %(session_id)s::uuid,
                        %(user_id)s,
                        'assistant',
                        %(answer)s,
                        %(input_text)s,
                        %(answer)s
                    );
                """,
                {
                    "session_id": normalized_session,
                    "user_id": user_id,
                    "input_text": input_text,
                    "answer": answer,
                },
            )
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

    return fetch_answer_memory(user_id, normalized_session)
