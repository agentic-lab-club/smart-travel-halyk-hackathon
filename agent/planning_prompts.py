"""Prompt templates for planning extraction."""

from __future__ import annotations

import json


def build_planning_prompt(
    *,
    action: str,
    user_prompt: str,
    current_trip: dict,
    chat_history: list[dict],
    required_fields: list[str],
) -> str:
    return f"""You are a trip planning extraction assistant for SmartTravel Halyk.
Return ONLY valid JSON. Do not add markdown, comments, or explanations.

ACTION:
{action}

REQUIRED_FIELDS:
{json.dumps(required_fields, ensure_ascii=False)}

CURRENT_TRIP_STATE:
{json.dumps(current_trip, ensure_ascii=False)}

CHAT_HISTORY:
{json.dumps(chat_history, ensure_ascii=False)}

LATEST_USER_PROMPT:
{user_prompt}

Return a JSON object with these top-level keys:
- normalized_fields: object with canonical planning fields
- optional_fields: object with optional extracted fields
- assistant_summary: short string suitable for mobile/backend UI
- vibe_labels: string array
- visa_insights: object
- weather_insights: string array
- review_summaries: array of objects
- field_confidence: object mapping field name to low|medium|high

Canonical planning fields may include:
- origin_city
- destination_country
- destination_city
- start_date
- end_date
- budget
- transport_type
- trip_purpose
- citizenship
- travelers
- hotel_preferences
- insurance_needed
- event_interest
- interests

Rules:
1. Preserve already known CURRENT_TRIP_STATE values unless the latest user prompt clearly changes them.
2. If a field is not explicitly supported by the latest prompt or chat context, leave it null or omit it from normalized_fields.
3. Do NOT guess missing values.
4. Dates must be YYYY-MM-DD when explicit enough to normalize.
5. Budget must be an integer in KZT when explicit enough to normalize.
6. assistant_summary should be concise and directly renderable by a mobile app.
7. If the latest prompt contradicts prior state, output the new value in normalized_fields and let backend compare.
8. Return raw JSON only.
"""
