"""Pydantic models for the place/travel guide endpoint."""

from __future__ import annotations

from typing import Any, Optional
from uuid import UUID

from pydantic import AliasChoices, BaseModel, ConfigDict, Field, field_validator


class AgentRequest(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    input_text: str = Field(
        ...,
        validation_alias=AliasChoices("input_text", "inputText", "text", "question"),
        description="Free-text user question or request",
    )
    user_id: int = Field(
        ...,
        validation_alias=AliasChoices("user_id", "userId"),
        description="Application user id",
    )
    session_id: str = Field(
        ...,
        validation_alias=AliasChoices("session_id", "sessionId"),
        description="Go chat/session id UUID",
    )
    language: Optional[str] = Field(
        default=None,
        validation_alias=AliasChoices("language", "lang"),
        description="Preferred answer language, e.g. ru, kk, en",
    )

    @field_validator("input_text", "language")
    @classmethod
    def normalize_text_fields(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        cleaned = v.strip()
        return cleaned or None

    @field_validator("input_text")
    @classmethod
    def validate_input_text(cls, v: Optional[str]) -> str:
        if not v:
            raise ValueError("input_text is required")
        return v

    @field_validator("session_id")
    @classmethod
    def validate_session_id(cls, v: str) -> str:
        cleaned = v.strip()
        if not cleaned:
            raise ValueError("session_id is required")
        try:
            UUID(cleaned)
        except ValueError as exc:
            raise ValueError("session_id must be a UUID") from exc
        return cleaned


class AgentParsedQuery(BaseModel):
    question: str = Field(..., description="Cleaned user question")
    country: Optional[str] = Field(default=None, description="Detected country")
    city: Optional[str] = Field(default=None, description="City context")
    place: Optional[str] = Field(default=None, description="Detected place")
    attraction: Optional[str] = Field(default=None, description="Detected attraction")
    language: Optional[str] = Field(default=None, description="Answer language")
    include_attractions: bool = True
    include_restaurants: bool = True
    include_seasonal_events: bool = True

    @field_validator(
        "question",
        "country",
        "city",
        "place",
        "attraction",
        "language",
    )
    @classmethod
    def normalize_blank(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        cleaned = v.strip()
        return cleaned or None


class AgentResponse(BaseModel):
    user_id: int
    parsed_query: AgentParsedQuery
    answer: str
    raw_text: str
    context: dict[str, Any] = Field(default_factory=dict)
