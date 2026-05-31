"""Planning-aware trip extraction service."""

from __future__ import annotations

import logging
from copy import deepcopy
from typing import Any

from json_utils import JSONParseError
from llm_client import DeepSeekGateway, LLMTransportError
from planning_models import (
    DEFAULT_REQUIRED_FIELDS,
    PlanningRequest,
    PlanningResponse,
    TripData,
    TripResponse,
)
from planning_prompts import build_planning_prompt

logger = logging.getLogger(__name__)


class PlanningService:
    def __init__(self, llm_gateway: DeepSeekGateway | None = None) -> None:
        self.llm_gateway = llm_gateway or DeepSeekGateway()

    def plan_trip(self, request: PlanningRequest) -> PlanningResponse:
        required_fields = request.required_fields or DEFAULT_REQUIRED_FIELDS
        current_trip = canonicalize_trip_state(request.current_trip)
        prompt = build_planning_prompt(
            action=request.action,
            user_prompt=request.user_prompt,
            current_trip=current_trip,
            chat_history=[item.model_dump() for item in request.chat_history],
            required_fields=required_fields,
        )

        extraction_notes: list[str] = []
        llm_payload: dict[str, Any] = {}
        raw_text = ""
        try:
            llm_payload, raw_text = self.llm_gateway.call_json(
                user_text=prompt,
                system_prompt="Return only valid JSON.",
                temperature=0.0,
                max_tokens=1200,
            )
        except JSONParseError as exc:
            extraction_notes.append(f"llm_json_parse_failed: {exc}")
            logger.warning(
                "planning_json_parse_failed trip_id=%s action=%s",
                request.trip_id,
                request.action,
            )
        except LLMTransportError as exc:
            extraction_notes.append(f"llm_transport_failed: {exc}")
            logger.warning(
                "planning_transport_failed trip_id=%s action=%s",
                request.trip_id,
                request.action,
            )

        extracted_normalized = canonicalize_trip_state(
            llm_payload.get("normalized_fields", {})
        )
        optional_fields = canonicalize_optional_fields(
            llm_payload.get("optional_fields", {})
        )

        merged, changed_fields, conflicting_fields = merge_trip_state(
            current=current_trip,
            extracted=extracted_normalized,
        )
        missing_fields = compute_missing_fields(merged, required_fields)

        response = PlanningResponse(
            normalized_fields=merged,
            missing_fields=missing_fields,
            optional_fields=optional_fields,
            assistant_summary=build_assistant_summary(
                llm_payload.get("assistant_summary"),
                missing_fields,
            ),
            vibe_labels=normalize_string_list(llm_payload.get("vibe_labels")),
            visa_insights=ensure_object(llm_payload.get("visa_insights")),
            weather_insights=normalize_string_list(
                llm_payload.get("weather_insights")
            ),
            review_summaries=ensure_object_list(llm_payload.get("review_summaries")),
            changed_fields=changed_fields,
            conflicting_fields=conflicting_fields,
            ready_for_confirmation_hint=not missing_fields,
            field_confidence=normalize_confidence_map(
                llm_payload.get("field_confidence")
            ),
            extraction_notes=extraction_notes,
            raw_text=raw_text,
        )
        logger.info(
            "planning_response_ready trip_id=%s action=%s missing=%s changed=%s conflicting=%s",
            request.trip_id,
            request.action,
            len(response.missing_fields),
            len(response.changed_fields),
            len(response.conflicting_fields),
        )
        return response

    def parse_trip_legacy(self, text: str) -> TripResponse:
        planning_response = self.plan_trip(
            PlanningRequest(
                trip_id="legacy-parse-trip",
                action="collect_fields",
                user_prompt=text,
                current_trip={},
                chat_history=[],
            )
        )
        parsed = TripData(
            country=as_optional_str(
                planning_response.normalized_fields.get("destination_country")
            ),
            departure_date=as_optional_str(
                planning_response.normalized_fields.get("start_date")
            ),
            arrival_date=as_optional_str(
                planning_response.normalized_fields.get("end_date")
            ),
            city=as_optional_str(
                planning_response.normalized_fields.get("destination_city")
            ),
            theme=first_or_none(planning_response.vibe_labels),
            cost=as_optional_int(planning_response.normalized_fields.get("budget")),
            people_count=extract_people_count(planning_response),
        )
        return TripResponse(parsed=parsed, raw_text=planning_response.raw_text)


def canonicalize_trip_state(payload: dict[str, Any]) -> dict[str, Any]:
    out: dict[str, Any] = {}
    for key, value in (payload or {}).items():
        canonical_key = canonicalize_field_name(key)
        normalized_value = normalize_value(canonical_key, value)
        if normalized_value is not None:
            out[canonical_key] = normalized_value
    return out


def canonicalize_optional_fields(payload: dict[str, Any]) -> dict[str, Any]:
    out: dict[str, Any] = {}
    for key, value in (payload or {}).items():
        normalized_value = normalize_generic_value(value)
        if normalized_value is not None:
            out[key] = normalized_value
    return out


def canonicalize_field_name(name: str) -> str:
    mapping = {
        "country": "destination_country",
        "city": "destination_city",
        "departure_date": "start_date",
        "arrival_date": "end_date",
        "cost": "budget",
        "people_count": "travelers_count",
    }
    return mapping.get(name, name)


def normalize_value(field_name: str, value: Any) -> Any:
    if value is None:
        return None
    if isinstance(value, str):
        cleaned = value.strip()
        if not cleaned:
            return None
        if field_name in {"destination_country", "citizenship"}:
            return normalize_country(cleaned)
        if field_name in {"transport_type", "trip_purpose"}:
            return cleaned.lower().replace(" ", "_")
        return cleaned
    if isinstance(value, bool):
        return value
    if isinstance(value, (int, float)):
        if field_name in {"budget", "travelers_count"}:
            numeric = int(value)
            return numeric if numeric > 0 else None
        return value
    if isinstance(value, list):
        items = [normalize_generic_value(item) for item in value]
        items = [item for item in items if item not in (None, "", [])]
        return items or None
    if isinstance(value, dict):
        out = {}
        for key, inner_value in value.items():
            normalized = normalize_generic_value(inner_value)
            if normalized is not None:
                out[str(key)] = normalized
        return out or None
    return value


def normalize_generic_value(value: Any) -> Any:
    if value is None:
        return None
    if isinstance(value, str):
        cleaned = value.strip()
        return cleaned or None
    if isinstance(value, list):
        items = [normalize_generic_value(item) for item in value]
        items = [item for item in items if item is not None]
        return items or None
    if isinstance(value, dict):
        out = {}
        for key, inner in value.items():
            normalized = normalize_generic_value(inner)
            if normalized is not None:
                out[str(key)] = normalized
        return out or None
    return value


def normalize_country(value: str) -> str:
    lookup = {
        "казахстан": "Kazakhstan",
        "қазақстан": "Kazakhstan",
        "kazakhstan": "Kazakhstan",
        "япония": "Japan",
        "japan": "Japan",
        "германия": "Germany",
        "germany": "Germany",
        "турция": "Turkey",
        "turkey": "Turkey",
        "оаэ": "UAE",
        "uae": "UAE",
        "united arab emirates": "UAE",
    }
    return lookup.get(value.strip().lower(), value.strip())


def merge_trip_state(
    *,
    current: dict[str, Any],
    extracted: dict[str, Any],
) -> tuple[dict[str, Any], list[str], list[str]]:
    merged = deepcopy(current)
    changed_fields: list[str] = []
    conflicting_fields: list[str] = []

    for key, new_value in extracted.items():
        if is_empty_value(new_value):
            continue
        old_value = merged.get(key)
        if is_empty_value(old_value):
            merged[key] = new_value
            changed_fields.append(key)
            continue
        if old_value != new_value:
            merged[key] = new_value
            changed_fields.append(key)
            conflicting_fields.append(key)

    return merged, unique_list(changed_fields), unique_list(conflicting_fields)


def compute_missing_fields(
    values: dict[str, Any],
    required_fields: list[str],
) -> list[str]:
    missing = []
    for field_name in required_fields:
        if is_empty_value(values.get(field_name)):
            missing.append(field_name)
    return missing


def is_empty_value(value: Any) -> bool:
    if value is None:
        return True
    if isinstance(value, str):
        return not value.strip()
    if isinstance(value, (int, float)):
        return value == 0
    if isinstance(value, (list, dict)):
        return len(value) == 0
    return False


def build_assistant_summary(raw_summary: Any, missing_fields: list[str]) -> str:
    if isinstance(raw_summary, str) and raw_summary.strip():
        return raw_summary.strip()
    if missing_fields:
        return (
            "I collected part of the trip context. I still need: "
            + ", ".join(missing_fields)
            + "."
        )
    return (
        "I collected the required trip fields. Please review and confirm "
        "the extracted trip details."
    )


def normalize_string_list(value: Any) -> list[str]:
    if not isinstance(value, list):
        return []
    out: list[str] = []
    for item in value:
        if isinstance(item, str) and item.strip():
            out.append(item.strip())
    return unique_list(out)


def ensure_object(value: Any) -> dict[str, Any]:
    return value if isinstance(value, dict) else {}


def ensure_object_list(value: Any) -> list[dict[str, Any]]:
    if not isinstance(value, list):
        return []
    return [item for item in value if isinstance(item, dict)]


def normalize_confidence_map(value: Any) -> dict[str, str] | None:
    if not isinstance(value, dict):
        return None
    out: dict[str, str] = {}
    for key, item in value.items():
        if isinstance(item, str) and item.strip():
            out[str(key)] = item.strip().lower()
    return out or None


def unique_list(items: list[str]) -> list[str]:
    seen: set[str] = set()
    out: list[str] = []
    for item in items:
        if item in seen:
            continue
        seen.add(item)
        out.append(item)
    return out


def first_or_none(items: list[str]) -> str | None:
    return items[0] if items else None


def as_optional_str(value: Any) -> str | None:
    if isinstance(value, str) and value.strip():
        return value.strip()
    return None


def as_optional_int(value: Any) -> int | None:
    if isinstance(value, int) and value > 0:
        return value
    return None


def extract_people_count(response: PlanningResponse) -> int | None:
    if isinstance(response.optional_fields.get("people_count"), int):
        return response.optional_fields["people_count"]
    if isinstance(response.normalized_fields.get("travelers_count"), int):
        return response.normalized_fields["travelers_count"]
    return None
