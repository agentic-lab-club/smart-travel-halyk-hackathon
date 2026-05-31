"""Utilities for parsing model JSON safely."""

from __future__ import annotations

import json
from typing import Any


class JSONParseError(ValueError):
    """Raised when the model returns invalid JSON."""


def sanitize_json(text: str) -> str:
    """Remove markdown code fences if the model ignored instructions."""
    cleaned = text.strip()
    if cleaned.startswith("```json"):
        cleaned = cleaned[7:]
    if cleaned.startswith("```"):
        cleaned = cleaned[3:]
    if cleaned.endswith("```"):
        cleaned = cleaned[:-3]
    return cleaned.strip()


def parse_json_object(text: str) -> dict[str, Any]:
    cleaned = sanitize_json(text)
    try:
        data = json.loads(cleaned)
    except json.JSONDecodeError as exc:
        raise JSONParseError(f"invalid JSON: {exc}") from exc
    if not isinstance(data, dict):
        raise JSONParseError("top-level JSON value must be an object")
    return data
