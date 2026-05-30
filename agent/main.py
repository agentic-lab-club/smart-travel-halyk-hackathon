"""FastAPI service that parses free-text travel requests via DeepSeek LLM."""
import json
import os
from typing import Optional

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from openai import OpenAI
from pydantic import BaseModel, Field, field_validator

load_dotenv()

DEEPSEEK_API_KEY = os.getenv("DEEPSEEK_API_KEY")
if not DEEPSEEK_API_KEY:
    raise RuntimeError("DEEPSEEK_API_KEY is not set in environment")

client = OpenAI(api_key=DEEPSEEK_API_KEY, base_url="https://api.deepseek.com")

app = FastAPI(title="SmartTravel Halyk — Trip Parser")

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


def _call_deepseek(user_text: str) -> str:
    response = client.chat.completions.create(
        model="deepseek-chat",
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": user_text},
        ],
        temperature=0.1,
        max_tokens=512,
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


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@app.post("/parse-trip", response_model=TripResponse)
async def parse_trip(request: TripRequest):
    try:
        raw = _call_deepseek(request.text)
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


@app.get("/health")
async def health():
    return {"status": "ok"}
