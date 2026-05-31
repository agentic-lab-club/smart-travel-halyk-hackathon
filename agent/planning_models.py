"""Pydantic models for trip planning extraction."""

from __future__ import annotations

from typing import Any, Literal, Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator

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

DEFAULT_REQUIRED_FIELDS = [
    "origin_city",
    "destination_country",
    "destination_city",
    "start_date",
    "end_date",
    "budget",
    "transport_type",
    "trip_purpose",
    "citizenship",
]


class TripRequest(BaseModel):
    text: str = Field(..., description="Free-text user request")


class TripData(BaseModel):
    country: Optional[str] = Field(default=None, description="Destination country")
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
        cleaned = v.strip()
        return cleaned or None

    @field_validator("theme")
    @classmethod
    def validate_theme(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        cleaned = v.strip()
        if cleaned not in ALLOWED_THEMES:
            return None
        return cleaned


class TripResponse(BaseModel):
    parsed: TripData
    raw_text: str


class PlanningChatMessage(BaseModel):
    role: Literal["user", "assistant", "system"] = "user"
    content: str
    action: Optional[str] = None

    @field_validator("content")
    @classmethod
    def validate_content(cls, value: str) -> str:
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("content is required")
        return cleaned


class PlanningRequest(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    trip_id: str = Field(..., description="Backend trip id")
    action: Literal[
        "collect_fields",
        "recheck_fields",
        "confirm_readiness",
        "generate_hints",
    ] = "collect_fields"
    user_prompt: str = Field(..., description="Latest user planning message")
    current_trip: dict[str, Any] = Field(default_factory=dict)
    chat_history: list[PlanningChatMessage] = Field(default_factory=list)
    required_fields: list[str] | None = None

    @field_validator("trip_id", "user_prompt")
    @classmethod
    def validate_non_blank(cls, value: str) -> str:
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("field must not be blank")
        return cleaned


class PlanningResponse(BaseModel):
    normalized_fields: dict[str, Any]
    missing_fields: list[str]
    optional_fields: dict[str, Any] = Field(default_factory=dict)
    assistant_summary: str
    vibe_labels: list[str] = Field(default_factory=list)
    visa_insights: dict[str, Any] = Field(default_factory=dict)
    weather_insights: list[str] = Field(default_factory=list)
    review_summaries: list[dict[str, Any]] = Field(default_factory=list)
    changed_fields: list[str] = Field(default_factory=list)
    conflicting_fields: list[str] = Field(default_factory=list)
    ready_for_confirmation_hint: bool = False
    field_confidence: dict[str, str] | None = None
    extraction_notes: list[str] = Field(default_factory=list)
    raw_text: str = ""
