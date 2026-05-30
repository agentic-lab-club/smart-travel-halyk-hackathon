"""FastAPI service for travel parsing and place Q&A via DeepSeek LLM."""
import json
import os
from decimal import Decimal
from typing import Any, Optional

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from openai import OpenAI
from pydantic import BaseModel, Field, field_validator, model_validator

load_dotenv()

DEEPSEEK_API_KEY = os.getenv("DEEPSEEK_API_KEY")
if not DEEPSEEK_API_KEY:
    raise RuntimeError("DEEPSEEK_API_KEY is not set in environment")

client = OpenAI(api_key=DEEPSEEK_API_KEY, base_url="https://api.deepseek.com")

app = FastAPI(title="SmartTravel Halyk — Travel Agent")

# ---------------------------------------------------------------------------
# Pydantic models
# ---------------------------------------------------------------------------

ALLOWED_COUNTRIES = {"Казахстан", "Япония", "Германия"}
ALLOWED_THEMES = {
    "Romantic",
    "Luxury",
    "Cultural",
    "Historical",
    "Foodie",
    "Adventure",
    "Backpacking",
    "Relaxing",
    "Beach",
    "Digital Nomad",
    "Cruise",
    "Roadtrip",
    "Budget",
    "Family",
    "Nightlife",
    "Nature",
    "Surprise Me",
}


class TripRequest(BaseModel):
    text: str = Field(..., description="Free-text user request")


class TripData(BaseModel):
    country: Optional[str] = Field(
        default=None,
        description="Destination country (Казахстан, Япония or Германия)",
    )
    departure_date: Optional[str] = Field(
        default=None, description="Departure date in YYYY-MM-DD format"
    )
    arrival_date: Optional[str] = Field(
        default=None, description="Arrival / landing date in YYYY-MM-DD format"
    )
    city: Optional[str] = Field(default=None, description="Destination city")
    theme: Optional[str] = Field(default=None, description="Trip theme")
    cost: Optional[int] = Field(
        default=None, description="Budget in KZT (Kazakhstani Tenge)"
    )
    people_count: Optional[int] = Field(
        default=None, description="Number of travellers"
    )

    @field_validator("country")
    @classmethod
    def validate_country(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        v_clean = v.strip()
        if v_clean not in ALLOWED_COUNTRIES:
            return None
        return v_clean

    @field_validator("theme")
    @classmethod
    def validate_theme(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        v_clean = v.strip()
        if v_clean not in ALLOWED_THEMES:
            return None
        return v_clean


class TripResponse(BaseModel):
    parsed: TripData
    raw_text: str


class AgentRequest(BaseModel):
    text: Optional[str] = Field(
        default=None,
        description="User question about a place or attraction",
    )
    question: Optional[str] = Field(
        default=None,
        description="Alias for text, useful for backend clients",
    )
    place: Optional[str] = Field(
        default=None,
        description="Place name, city, region or country",
    )
    attraction: Optional[str] = Field(
        default=None,
        description="Attraction name",
    )
    city: Optional[str] = Field(default=None, description="City context")
    country: Optional[str] = Field(default=None, description="Country context")
    language: Optional[str] = Field(
        default=None,
        description="Preferred answer language, e.g. ru, kk, en",
    )

    @field_validator(
        "text",
        "question",
        "place",
        "attraction",
        "city",
        "country",
        "language",
    )
    @classmethod
    def normalize_blank(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        v_clean = v.strip()
        return v_clean or None

    @model_validator(mode="after")
    def validate_payload(self):
        if not any(
            [
                self.text,
                self.question,
                self.place,
                self.attraction,
                self.city,
                self.country,
            ]
        ):
            raise ValueError("Provide text/question, place, attraction, city, or country")
        return self

    def to_prompt(self) -> str:
        parts = []
        user_question = self.text or self.question

        if user_question:
            parts.append(f"Question: {user_question}")
        if self.attraction:
            parts.append(f"Attraction: {self.attraction}")
        if self.place:
            parts.append(f"Place: {self.place}")
        if self.city:
            parts.append(f"City: {self.city}")
        if self.country:
            parts.append(f"Country: {self.country}")
        if self.language:
            parts.append(f"Preferred answer language: {self.language}")

        return "\n".join(parts)


class AgentResponse(BaseModel):
    answer: str
    raw_text: str
    context: dict[str, list[dict[str, Any]]] = Field(default_factory=dict)


# ---------------------------------------------------------------------------
# System prompt
# ---------------------------------------------------------------------------

SYSTEM_PROMPT = """You are a travel-request parser. The user writes a free-text message in any language (Russian, English, Kazakh, etc.).
Your job is to extract trip parameters and return **only** a valid JSON object. Do not wrap it in markdown, do not add explanations.

Required JSON fields:
- "country"      : one of ["Казахстан", "Япония", "Германия"]. Use **null** if not mentioned or unknown.
- "departure_date": date the user wants to leave (YYYY-MM-DD). Use **null** if not mentioned.
- "arrival_date" : date the user wants to arrive / land (YYYY-MM-DD). Use **null** if not mentioned.
- "city"         : destination city. Use **null** if not mentioned.
- "theme"        : one of [
    "Romantic", "Luxury", "Cultural", "Historical", "Foodie",
    "Adventure", "Backpacking", "Relaxing", "Beach", "Digital Nomad",
    "Cruise", "Roadtrip", "Budget", "Family", "Nightlife", "Nature",
    "Surprise Me"
  ]. Use **null** if not mentioned or does not match any value above.
- "cost"         : budget in Kazakhstani Tenge (KZT), integer. Use **null** if not mentioned.
- "people_count" : number of travellers, integer. Use **null** if not mentioned.

Rules:
1. Return ONLY raw JSON. No ```json fences, no comments.
2. If the user mentions a month/day without a year, assume the nearest future date (current year is 2026).
3. "cost" must be a number (e.g. 500000), not a string. Convert words like "пятьсот тысяч" to 500000.
4. "people_count" must be a number (e.g. 2). Convert words like "двоём" or "we are three" to integers.
5. "departure_date" and "arrival_date" are independent — provide whichever is present.
6. If a field is not explicitly mentioned in the user's message, set it to **null**. Do NOT guess defaults."""


PLACE_AGENT_SYSTEM_PROMPT = """You are a helpful travel guide agent for SmartTravel Halyk.
The user asks about a tourist attraction, city, country, neighborhood, landmark, or a place in a trip.

Answer in the user's language unless a preferred answer language is provided.
Use DATABASE_CONTEXT as the primary source. It contains live rows from the service database.
Give practical, concise information:
- what the place or attraction is;
- why it is interesting;
- what to see or do there;
- visit tips, timing, etiquette, transport or safety notes when useful;
- nearby context if the city/country is provided.

Rules:
1. Do not parse trip dates or budgets here. This endpoint is for place and attraction Q&A.
2. Prefer facts from DATABASE_CONTEXT over general knowledge.
3. If DATABASE_CONTEXT is empty or does not contain the requested fact, say that the database does not have that exact data yet.
4. Do not invent exact current ticket prices, opening hours, event schedules, or temporary closures. If the user asks for current details, say they should be checked before visiting.
5. If the place is ambiguous, explain the likely interpretation and ask for city/country only if needed.
6. Keep the answer useful for a mobile app: clear paragraphs or short bullet points, no markdown tables."""


def _call_deepseek(
    user_text: str,
    system_prompt: str,
    temperature: float = 0.1,
    max_tokens: int = 512,
) -> str:
    response = client.chat.completions.create(
        model="deepseek-chat",
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_text},
        ],
        temperature=temperature,
        max_tokens=max_tokens,
    )
    return response.choices[0].message.content


def _sanitize_json(text: str) -> str:
    """Remove markdown fences if the model ignored instructions."""
    text = text.strip()
    if text.startswith("```json"):
        text = text[7:]
    if text.startswith("```"):
        text = text[3:]
    if text.endswith("```"):
        text = text[:-3]
    return text.strip()


def _clean(value: Optional[str]) -> str:
    return value.strip() if value else ""


def _like_pattern(value: str) -> str:
    return f"%{value}%"


def _combined_agent_text(request: AgentRequest) -> str:
    return " ".join(
        value
        for value in [
            request.text,
            request.question,
            request.place,
            request.attraction,
            request.city,
            request.country,
        ]
        if value
    )


def _jsonable_rows(rows) -> list[dict[str, Any]]:
    result = []
    for row in rows:
        clean_row = {}
        for key, value in dict(row).items():
            if isinstance(value, Decimal):
                value = float(value)
            clean_row[key] = value
        result.append(clean_row)
    return result


def _fetch_rows(cur, sql: str, params: dict[str, Any]) -> list[dict[str, Any]]:
    cur.execute(sql, params)
    return _jsonable_rows(cur.fetchall())


def _merge_unique(
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


def _agent_search_params(request: AgentRequest) -> dict[str, Any]:
    search_text = _combined_agent_text(request)
    country = _clean(request.country)
    city = _clean(request.city)
    place = _clean(request.place)
    attraction = _clean(request.attraction)
    question = _clean(request.text or request.question)

    return {
        "search_text": search_text,
        "country": country,
        "country_pattern": _like_pattern(country),
        "city": city,
        "city_pattern": _like_pattern(city),
        "place": place,
        "place_pattern": _like_pattern(place),
        "attraction": attraction,
        "attraction_pattern": _like_pattern(attraction),
        "question": question,
        "question_pattern": _like_pattern(question),
    }


def _fetch_matching_countries(cur, params: dict[str, Any]) -> list[dict[str, Any]]:
    return _fetch_rows(
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


def _fetch_matching_cities(
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
    return _fetch_rows(
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
        ORDER BY
            CASE
                WHEN %(city)s <> ''
                    AND (c.name_ru ILIKE %(city_pattern)s OR c.name_en ILIKE %(city_pattern)s)
                    THEN 0
                WHEN %(place)s <> ''
                    AND (c.name_ru ILIKE %(place_pattern)s OR c.name_en ILIKE %(place_pattern)s)
                    THEN 1
                WHEN %(search_text)s <> ''
                    AND (
                        %(search_text)s ILIKE concat('%%', c.name_ru, '%%')
                        OR %(search_text)s ILIKE concat('%%', c.name_en, '%%')
                    )
                    THEN 2
                ELSE 3
            END,
            c.country_code,
            c.name_en
        LIMIT 8;
        """,
        query_params,
    )


def _fetch_cities_by_ids(cur, city_ids: list[int]) -> list[dict[str, Any]]:
    if not city_ids:
        return []

    return _fetch_rows(
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


def _fetch_matching_attractions(
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
    return _fetch_rows(
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
        ORDER BY
            CASE
                WHEN a.city_id = ANY(%(city_ids)s) THEN 0
                WHEN %(attraction)s <> ''
                    AND (a.name_ru ILIKE %(attraction_pattern)s OR a.name_en ILIKE %(attraction_pattern)s)
                    THEN 1
                WHEN %(place)s <> ''
                    AND (a.name_ru ILIKE %(place_pattern)s OR a.name_en ILIKE %(place_pattern)s)
                    THEN 2
                ELSE 3
            END,
            c.country_code,
            c.name_en,
            a.name_en
        LIMIT 12;
        """,
        query_params,
    )


def _fetch_matching_restaurants(
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
    return _fetch_rows(
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
        ORDER BY
            CASE
                WHEN r.city_id = ANY(%(city_ids)s) THEN 0
                ELSE 1
            END,
            c.country_code,
            c.name_en,
            r.name
        LIMIT 10;
        """,
        query_params,
    )


def _fetch_matching_seasonal_events(
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
    return _fetch_rows(
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


def _fetch_agent_context(request: AgentRequest) -> dict[str, list[dict[str, Any]]]:
    from db import get_connection
    from psycopg2.extras import RealDictCursor

    params = _agent_search_params(request)

    conn = get_connection()
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            countries = _fetch_matching_countries(cur, params)
            country_codes = {
                country["country_code"]
                for country in countries
                if country.get("country_code")
            }

            include_country_cities = not any(
                [params["city"], params["place"], params["attraction"]]
            )
            cities = _fetch_matching_cities(
                cur,
                params,
                sorted(country_codes),
                include_country_cities,
            )
            city_ids = {
                city["city_id"]
                for city in cities
                if city.get("city_id") is not None
            }
            country_codes.update(
                city["country_code"]
                for city in cities
                if city.get("country_code")
            )

            attractions = _fetch_matching_attractions(
                cur,
                params,
                sorted(city_ids),
                sorted(country_codes),
                include_country_attractions=not city_ids
                and bool(country_codes)
                and not any([params["attraction"], params["place"]]),
            )
            city_ids.update(
                attraction["city_id"]
                for attraction in attractions
                if attraction.get("city_id") is not None
            )
            country_codes.update(
                attraction["country_code"]
                for attraction in attractions
                if attraction.get("country_code")
            )

            cities = _merge_unique(
                cities,
                _fetch_cities_by_ids(cur, sorted(city_ids)),
                "city_id",
            )

            country_codes.update(
                city["country_code"]
                for city in cities
                if city.get("country_code")
            )

            restaurants = _fetch_matching_restaurants(
                cur,
                params,
                sorted(city_ids),
                sorted(country_codes),
                include_country_restaurants=not city_ids and bool(country_codes),
            )
            seasonal_events = _fetch_matching_seasonal_events(
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


def _build_agent_prompt(
    request: AgentRequest,
    context: dict[str, list[dict[str, Any]]],
) -> str:
    context_json = json.dumps(context, ensure_ascii=False)
    return (
        f"{request.to_prompt()}\n\n"
        "DATABASE_CONTEXT:\n"
        f"{context_json}"
    )


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@app.post("/parse-trip", response_model=TripResponse)
@app.post("/parser-trip", response_model=TripResponse)
async def parse_trip(request: TripRequest):
    try:
        raw = _call_deepseek(request.text, SYSTEM_PROMPT)
        clean = _sanitize_json(raw)
        data = json.loads(clean)
    except json.JSONDecodeError as exc:
        raise HTTPException(
            status_code=422,
            detail=f"DeepSeek returned invalid JSON: {exc}. Raw text: {raw}",
        )
    except Exception as exc:
        raise HTTPException(
            status_code=502,
            detail=f"DeepSeek API error: {exc}",
        )

    try:
        parsed = TripData(**data)
    except Exception as exc:
        raise HTTPException(
            status_code=422,
            detail=f"Validation error: {exc}. Raw data: {data}",
        )

    return TripResponse(parsed=parsed, raw_text=raw)


@app.post("/agent", response_model=AgentResponse)
async def ask_agent(request: AgentRequest):
    try:
        context = _fetch_agent_context(request)
    except Exception as exc:
        raise HTTPException(
            status_code=503,
            detail=f"Travel database error: {exc}",
        )

    try:
        raw = _call_deepseek(
            _build_agent_prompt(request, context),
            PLACE_AGENT_SYSTEM_PROMPT,
            temperature=0.3,
            max_tokens=900,
        )
    except Exception as exc:
        raise HTTPException(
            status_code=502,
            detail=f"DeepSeek API error: {exc}",
        )

    answer = raw.strip()
    return AgentResponse(answer=answer, raw_text=raw, context=context)


@app.get("/health")
async def health():
    return {"status": "ok"}
