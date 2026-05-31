"""Guide endpoint service and DB-backed context retrieval."""

from __future__ import annotations

import json
import logging
from datetime import date, datetime
from decimal import Decimal
from typing import Any, Callable, Optional
from uuid import UUID

from db import get_connection
from guide_models import AgentHistoryMessage, AgentHistoryResponse, AgentParsedQuery, AgentRequest, AgentResponse
from guide_prompts import AGENT_QUERY_EXTRACT_PROMPT, PLACE_AGENT_SYSTEM_PROMPT
from llm_client import DeepSeekGateway
from memory_repository import fetch_answer_memory, fetch_session_messages, save_answer_memory, session_key

logger = logging.getLogger(__name__)


class GuideService:
    def __init__(
        self,
        llm_gateway: DeepSeekGateway | None = None,
        *,
        answer_memory_fetcher: Callable[[int, str], list[dict[str, Any]]] = fetch_answer_memory,
        answer_memory_saver: Callable[[int, str, str, str], list[dict[str, Any]]] = save_answer_memory,
        session_messages_fetcher: Callable[[int, str], list[dict[str, Any]]] = fetch_session_messages,
    ) -> None:
        self.llm_gateway = llm_gateway or DeepSeekGateway()
        self.answer_memory_fetcher = answer_memory_fetcher
        self.answer_memory_saver = answer_memory_saver
        self.session_messages_fetcher = session_messages_fetcher

    def ask(self, request: AgentRequest) -> AgentResponse:
        answer_memory = self.answer_memory_fetcher(request.user_id, request.session_id)
        parsed_query = extract_agent_query(self.llm_gateway, request, answer_memory)
        database_context = fetch_agent_context(parsed_query)
        user_context = fetch_user_context(request.user_id)

        raw = self.llm_gateway.call_text(
            user_text=build_agent_prompt(
                request,
                parsed_query,
                database_context,
                user_context,
                answer_memory,
            ),
            system_prompt=PLACE_AGENT_SYSTEM_PROMPT,
            temperature=0.3,
            max_tokens=900,
        )
        answer = raw.strip()
        updated_answer_memory = self.answer_memory_saver(
            request.user_id,
            request.session_id,
            request.input_text,
            answer,
        )

        return AgentResponse(
            user_id=request.user_id,
            parsed_query=parsed_query,
            answer=answer,
            raw_text=raw,
            context={
                "database": database_context,
                "user": user_context,
                "memory": {
                    "session_id": session_key(request.session_id),
                    "previous_answers": answer_memory,
                    "last_answers": updated_answer_memory,
                },
            },
        )

    def history(self, user_id: int, session_id: str) -> AgentHistoryResponse:
        rows = self.session_messages_fetcher(user_id, session_id)
        return AgentHistoryResponse(
            user_id=user_id,
            session_id=session_key(session_id),
            messages=[AgentHistoryMessage(**row) for row in rows],
        )


def clean(value: Optional[str]) -> str:
    return value.strip() if value else ""


def like_pattern(value: str) -> str:
    return f"%{value}%"


def combined_agent_text(parsed_query: AgentParsedQuery) -> str:
    return " ".join(
        value
        for value in [
            parsed_query.question,
            parsed_query.place,
            parsed_query.attraction,
            parsed_query.city,
            parsed_query.country,
        ]
        if value
    )


def jsonable_rows(rows) -> list[dict[str, Any]]:
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


def fetch_rows(cur, sql: str, params: dict[str, Any]) -> list[dict[str, Any]]:
    cur.execute(sql, params)
    return jsonable_rows(cur.fetchall())


def merge_unique(
    left: list[dict[str, Any]],
    right: list[dict[str, Any]],
    key: str,
) -> list[dict[str, Any]]:
    seen = {item[key] for item in left if item.get(key) is not None}
    merged = list(left)
    for item in right:
        item_key = item.get(key)
        if item_key is None or item_key in seen:
            continue
        seen.add(item_key)
        merged.append(item)
    return merged


def agent_search_params(parsed_query: AgentParsedQuery) -> dict[str, Any]:
    search_text = combined_agent_text(parsed_query)
    country = clean(parsed_query.country)
    city = clean(parsed_query.city)
    place = clean(parsed_query.place)
    attraction = clean(parsed_query.attraction)
    question = clean(parsed_query.question)
    return {
        "search_text": search_text,
        "country": country,
        "country_pattern": like_pattern(country),
        "city": city,
        "city_pattern": like_pattern(city),
        "place": place,
        "place_pattern": like_pattern(place),
        "attraction": attraction,
        "attraction_pattern": like_pattern(attraction),
        "question": question,
        "question_pattern": like_pattern(question),
    }


def build_query_extract_input(
    request: AgentRequest,
    answer_memory: list[dict[str, Any]],
) -> str:
    if not answer_memory:
        return request.input_text
    return (
        f"USER_INPUT: {request.input_text}\n\n"
        "ANSWER_MEMORY:\n"
        f"{json.dumps(answer_memory, ensure_ascii=False)}"
    )


def extract_agent_query(
    llm_gateway: DeepSeekGateway,
    request: AgentRequest,
    answer_memory: Optional[list[dict[str, Any]]] = None,
) -> AgentParsedQuery:
    data: dict[str, Any] = {}
    try:
        data, _ = llm_gateway.call_json(
            user_text=build_query_extract_input(request, answer_memory or []),
            system_prompt=AGENT_QUERY_EXTRACT_PROMPT,
            temperature=0.0,
            max_tokens=500,
        )
    except Exception as exc:
        logger.warning("guide_query_extract_failed session_id=%s error=%s", request.session_id, exc)

    data["question"] = data.get("question") or request.input_text
    if request.language:
        data["language"] = request.language
    try:
        return AgentParsedQuery(**data)
    except Exception:
        return AgentParsedQuery(
            question=request.input_text,
            language=request.language,
            include_attractions=True,
            include_restaurants=True,
            include_seasonal_events=True,
        )


def fetch_matching_countries(cur, params: dict[str, Any]) -> list[dict[str, Any]]:
    return fetch_rows(
        cur,
        """
        SELECT country_code, name_ru, name_en, currency_code, timezone_hint
        FROM travel_countries
        WHERE (
            %(country)s <> ''
            AND (name_ru ILIKE %(country_pattern)s OR name_en ILIKE %(country_pattern)s)
        )
        OR (
            %(place)s <> ''
            AND (name_ru ILIKE %(place_pattern)s OR name_en ILIKE %(place_pattern)s)
        )
        OR (
            %(search_text)s <> ''
            AND (
                %(search_text)s ILIKE concat('%%', name_ru, '%%')
                OR %(search_text)s ILIKE concat('%%', name_en, '%%')
            )
        )
        ORDER BY name_en
        LIMIT 5;
        """,
        params,
    )


def fetch_matching_cities(
    cur,
    params: dict[str, Any],
    country_codes: list[str],
    include_country_cities: bool,
) -> list[dict[str, Any]]:
    query_params = {
        **params,
        "country_codes": country_codes or [""],
        "include_country_cities": include_country_cities,
    }
    return fetch_rows(
        cur,
        """
        SELECT
            c.city_id,
            c.country_code,
            co.name_ru AS country_name_ru,
            co.name_en AS country_name_en,
            c.name_ru,
            c.name_en,
            c.region,
            c.latitude,
            c.longitude,
            c.description
        FROM travel_cities c
        JOIN travel_countries co ON co.country_code = c.country_code
        WHERE (
            %(city)s <> ''
            AND (c.name_ru ILIKE %(city_pattern)s OR c.name_en ILIKE %(city_pattern)s)
        )
        OR (
            %(place)s <> ''
            AND (c.name_ru ILIKE %(place_pattern)s OR c.name_en ILIKE %(place_pattern)s)
        )
        OR (
            %(include_country_cities)s
            AND c.country_code = ANY(%(country_codes)s)
        )
        OR (
            %(search_text)s <> ''
            AND (
                %(search_text)s ILIKE concat('%%', c.name_ru, '%%')
                OR %(search_text)s ILIKE concat('%%', c.name_en, '%%')
            )
        )
        ORDER BY c.country_code, c.name_en
        LIMIT 8;
        """,
        query_params,
    )


def fetch_cities_by_ids(cur, city_ids: list[int]) -> list[dict[str, Any]]:
    if not city_ids:
        return []
    return fetch_rows(
        cur,
        """
        SELECT
            c.city_id,
            c.country_code,
            co.name_ru AS country_name_ru,
            co.name_en AS country_name_en,
            c.name_ru,
            c.name_en,
            c.region,
            c.latitude,
            c.longitude,
            c.description
        FROM travel_cities c
        JOIN travel_countries co ON co.country_code = c.country_code
        WHERE c.city_id = ANY(%(city_ids)s)
        ORDER BY c.country_code, c.name_en;
        """,
        {"city_ids": city_ids},
    )


def fetch_matching_attractions(
    cur,
    params: dict[str, Any],
    city_ids: list[int],
    country_codes: list[str],
    include_country_attractions: bool,
) -> list[dict[str, Any]]:
    query_params = {
        **params,
        "city_ids": city_ids or [-1],
        "country_codes": country_codes or [""],
        "include_country_attractions": include_country_attractions,
    }
    return fetch_rows(
        cur,
        """
        SELECT
            a.attraction_id,
            a.city_id,
            c.country_code,
            c.name_ru AS city_name_ru,
            c.name_en AS city_name_en,
            co.name_ru AS country_name_ru,
            co.name_en AS country_name_en,
            a.name_ru,
            a.name_en,
            a.category,
            a.description,
            a.recommended_duration_minutes,
            a.price_level,
            a.is_family_friendly
        FROM travel_attractions a
        JOIN travel_cities c ON c.city_id = a.city_id
        JOIN travel_countries co ON co.country_code = c.country_code
        WHERE a.city_id = ANY(%(city_ids)s)
        OR (
            %(include_country_attractions)s
            AND c.country_code = ANY(%(country_codes)s)
        )
        OR (
            %(attraction)s <> ''
            AND (a.name_ru ILIKE %(attraction_pattern)s OR a.name_en ILIKE %(attraction_pattern)s)
        )
        OR (
            %(place)s <> ''
            AND (a.name_ru ILIKE %(place_pattern)s OR a.name_en ILIKE %(place_pattern)s)
        )
        OR (
            %(question)s <> ''
            AND (a.name_ru ILIKE %(question_pattern)s OR a.name_en ILIKE %(question_pattern)s)
        )
        OR (
            %(search_text)s <> ''
            AND (
                %(search_text)s ILIKE concat('%%', a.name_ru, '%%')
                OR %(search_text)s ILIKE concat('%%', a.name_en, '%%')
            )
        )
        ORDER BY c.country_code, c.name_en, a.name_en
        LIMIT 12;
        """,
        query_params,
    )


def fetch_matching_restaurants(
    cur,
    params: dict[str, Any],
    city_ids: list[int],
    country_codes: list[str],
    include_country_restaurants: bool,
) -> list[dict[str, Any]]:
    query_params = {
        **params,
        "city_ids": city_ids or [-1],
        "country_codes": country_codes or [""],
        "include_country_restaurants": include_country_restaurants,
    }
    return fetch_rows(
        cur,
        """
        SELECT
            r.restaurant_id,
            r.city_id,
            c.country_code,
            c.name_ru AS city_name_ru,
            c.name_en AS city_name_en,
            co.name_ru AS country_name_ru,
            co.name_en AS country_name_en,
            r.name,
            r.cuisine,
            r.price_level,
            r.description,
            r.area,
            r.reservation_recommended
        FROM popular_restaurants r
        JOIN travel_cities c ON c.city_id = r.city_id
        JOIN travel_countries co ON co.country_code = c.country_code
        WHERE r.city_id = ANY(%(city_ids)s)
        OR (
            %(include_country_restaurants)s
            AND c.country_code = ANY(%(country_codes)s)
        )
        OR (
            %(place)s <> ''
            AND r.name ILIKE %(place_pattern)s
        )
        OR (
            %(question)s <> ''
            AND r.name ILIKE %(question_pattern)s
        )
        OR (
            %(search_text)s <> ''
            AND %(search_text)s ILIKE concat('%%', r.name, '%%')
        )
        ORDER BY c.country_code, c.name_en, r.name
        LIMIT 10;
        """,
        query_params,
    )


def fetch_matching_seasonal_events(
    cur,
    params: dict[str, Any],
    city_ids: list[int],
    country_codes: list[str],
    include_country_city_events: bool,
) -> list[dict[str, Any]]:
    query_params = {
        **params,
        "city_ids": city_ids or [-1],
        "country_codes": country_codes or [""],
        "include_country_city_events": include_country_city_events,
    }
    return fetch_rows(
        cur,
        """
        SELECT
            se.seasonal_event_id,
            se.country_code,
            se.city_id,
            c.name_ru AS city_name_ru,
            c.name_en AS city_name_en,
            co.name_ru AS country_name_ru,
            co.name_en AS country_name_en,
            se.scope_type,
            se.name_ru,
            se.name_en,
            se.category,
            se.start_month,
            se.start_day,
            se.end_month,
            se.end_day,
            se.description,
            se.travel_tip,
            se.is_annual
        FROM seasonal_events se
        JOIN travel_countries co ON co.country_code = se.country_code
        LEFT JOIN travel_cities c ON c.city_id = se.city_id
        WHERE se.city_id = ANY(%(city_ids)s)
        OR (
            se.scope_type = 'country'
            AND se.country_code = ANY(%(country_codes)s)
        )
        OR (
            %(include_country_city_events)s
            AND se.country_code = ANY(%(country_codes)s)
        )
        OR (
            %(place)s <> ''
            AND (se.name_ru ILIKE %(place_pattern)s OR se.name_en ILIKE %(place_pattern)s)
        )
        OR (
            %(question)s <> ''
            AND (se.name_ru ILIKE %(question_pattern)s OR se.name_en ILIKE %(question_pattern)s)
        )
        OR (
            %(search_text)s <> ''
            AND (
                %(search_text)s ILIKE concat('%%', se.name_ru, '%%')
                OR %(search_text)s ILIKE concat('%%', se.name_en, '%%')
            )
        )
        ORDER BY se.start_month, se.start_day, se.name_en
        LIMIT 12;
        """,
        query_params,
    )


def fetch_agent_context(parsed_query: AgentParsedQuery) -> dict[str, list[dict[str, Any]]]:
    from psycopg2.extras import RealDictCursor

    params = agent_search_params(parsed_query)
    conn = get_connection()
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            countries = fetch_matching_countries(cur, params)
            country_codes = {
                item["country_code"] for item in countries if item.get("country_code")
            }
            include_country_cities = not any(
                [params["city"], params["place"], params["attraction"]]
            )
            cities = fetch_matching_cities(
                cur,
                params,
                sorted(country_codes),
                include_country_cities,
            )
            city_ids = {
                city["city_id"] for city in cities if city.get("city_id") is not None
            }
            country_codes.update(
                city["country_code"] for city in cities if city.get("country_code")
            )

            attractions = []
            if parsed_query.include_attractions:
                attractions = fetch_matching_attractions(
                    cur,
                    params,
                    sorted(city_ids),
                    sorted(country_codes),
                    include_country_attractions=not city_ids
                    and bool(country_codes)
                    and not any([params["attraction"], params["place"]]),
                )

            city_ids.update(
                item["city_id"] for item in attractions if item.get("city_id") is not None
            )
            country_codes.update(
                item["country_code"] for item in attractions if item.get("country_code")
            )
            cities = merge_unique(
                cities,
                fetch_cities_by_ids(cur, sorted(city_ids)),
                "city_id",
            )
            country_codes.update(
                city["country_code"] for city in cities if city.get("country_code")
            )

            restaurants = []
            if parsed_query.include_restaurants:
                restaurants = fetch_matching_restaurants(
                    cur,
                    params,
                    sorted(city_ids),
                    sorted(country_codes),
                    include_country_restaurants=not city_ids and bool(country_codes),
                )

            seasonal_events = []
            if parsed_query.include_seasonal_events:
                seasonal_events = fetch_matching_seasonal_events(
                    cur,
                    params,
                    sorted(city_ids),
                    sorted(country_codes),
                    include_country_city_events=not city_ids and bool(country_codes),
                )
    finally:
        conn.close()

    return {
        "matched_countries": countries,
        "matched_cities": cities,
        "attractions": attractions,
        "popular_restaurants": restaurants,
        "seasonal_events": seasonal_events,
    }


def fetch_user_context(user_id: int) -> dict[str, list[dict[str, Any]]]:
    from psycopg2.extras import RealDictCursor

    conn = get_connection()
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            kino_preferences = fetch_rows(
                cur,
                """
                SELECT
                    COALESCE(class_code, 'unknown') AS class_code,
                    COALESCE(genre_code, 'unknown') AS genre_code,
                    COALESCE(city, 'unknown') AS city,
                    COUNT(*) AS events_count,
                    COALESCE(SUM(total_amount), 0) AS total_amount
                FROM kino_ticket_transactions
                WHERE user_id = %(user_id)s
                  AND (status IS NULL OR status = 'paid')
                GROUP BY class_code, genre_code, city
                ORDER BY events_count DESC, total_amount DESC
                LIMIT 5;
                """,
                {"user_id": user_id},
            )
            spending_categories = fetch_rows(
                cur,
                """
                SELECT
                    COALESCE(category_name, category_code, 'unknown') AS category,
                    COUNT(*) AS transactions_count,
                    COALESCE(SUM(amount), 0) AS total_amount
                FROM account_transactions
                WHERE user_id = %(user_id)s
                  AND direction = 'expense'
                  AND (status IS NULL OR status = 'success')
                GROUP BY COALESCE(category_name, category_code, 'unknown')
                ORDER BY total_amount DESC
                LIMIT 5;
                """,
                {"user_id": user_id},
            )
    finally:
        conn.close()

    return {
        "kino_preferences": kino_preferences,
        "spending_categories": spending_categories,
    }


def build_agent_prompt(
    request: AgentRequest,
    parsed_query: AgentParsedQuery,
    database_context: dict[str, list[dict[str, Any]]],
    user_context: dict[str, list[dict[str, Any]]],
    answer_memory: list[dict[str, Any]],
) -> str:
    return (
        f"USER_ID: {request.user_id}\n"
        f"SESSION_ID: {session_key(request.session_id)}\n"
        f"USER_INPUT: {request.input_text}\n"
        f"PARSED_QUERY: {json.dumps(parsed_query.model_dump(), ensure_ascii=False)}\n\n"
        "ANSWER_MEMORY:\n"
        f"{json.dumps(answer_memory, ensure_ascii=False)}\n\n"
        "USER_CONTEXT:\n"
        f"{json.dumps(user_context, ensure_ascii=False)}\n\n"
        "DATABASE_CONTEXT:\n"
        f"{json.dumps(database_context, ensure_ascii=False)}"
    )
