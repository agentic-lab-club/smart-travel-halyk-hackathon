"""FastAPI service for travel parsing and place Q&A via DeepSeek LLM."""
import json
import os
from typing import Optional

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
        if not any([self.text, self.question, self.place, self.attraction]):
            raise ValueError("Provide text/question, place, or attraction")
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
Give practical, concise information:
- what the place or attraction is;
- why it is interesting;
- what to see or do there;
- visit tips, timing, etiquette, transport or safety notes when useful;
- nearby context if the city/country is provided.

Rules:
1. Do not parse trip dates or budgets here. This endpoint is for place and attraction Q&A.
2. Do not invent exact current ticket prices, opening hours, event schedules, or temporary closures. If the user asks for current details, say they should be checked before visiting.
3. If the place is ambiguous, explain the likely interpretation and ask for city/country only if needed.
4. Keep the answer useful for a mobile app: clear paragraphs or short bullet points, no markdown tables."""


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
        raw = _call_deepseek(
            request.to_prompt(),
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
    return AgentResponse(answer=answer, raw_text=raw)


@app.get("/health")
async def health():
    return {"status": "ok"}
