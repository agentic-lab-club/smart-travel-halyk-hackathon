import unittest

from json_utils import JSONParseError
from planning_models import PlanningRequest
from planning_service import PlanningService


class FakeGateway:
    def __init__(self, payload=None, raw="{}"):
        self.payload = payload or {}
        self.raw = raw

    def call_json(self, **kwargs):
        return self.payload, self.raw


class FailingJSONGateway:
    def call_json(self, **kwargs):
        raise JSONParseError("bad json")


class PlanningServiceTests(unittest.TestCase):
    def test_incomplete_prompt_returns_missing_fields(self):
        service = PlanningService(
            llm_gateway=FakeGateway(
                payload={
                    "normalized_fields": {
                        "destination_country": "Japan",
                        "destination_city": "Tokyo",
                        "trip_purpose": "family",
                    },
                    "assistant_summary": "Need more details.",
                    "vibe_labels": ["family", "culture"],
                }
            )
        )

        response = service.plan_trip(
            PlanningRequest(
                trip_id="trip-1",
                action="collect_fields",
                user_prompt="Family trip to Tokyo",
                current_trip={},
                chat_history=[],
            )
        )

        self.assertEqual(response.normalized_fields["destination_country"], "Japan")
        self.assertIn("budget", response.missing_fields)
        self.assertIn("start_date", response.missing_fields)
        self.assertFalse(response.ready_for_confirmation_hint)

    def test_follow_up_preserves_existing_fields(self):
        service = PlanningService(
            llm_gateway=FakeGateway(
                payload={
                    "normalized_fields": {
                        "start_date": "2026-07-10",
                        "end_date": "2026-07-17",
                    },
                    "assistant_summary": "Dates captured.",
                }
            )
        )

        response = service.plan_trip(
            PlanningRequest(
                trip_id="trip-2",
                action="recheck_fields",
                user_prompt="We want to travel from July 10 to July 17",
                current_trip={
                    "destination_country": "Japan",
                    "destination_city": "Tokyo",
                    "trip_purpose": "family",
                    "origin_city": "Almaty",
                    "citizenship": "Kazakhstan",
                    "transport_type": "flight",
                },
                chat_history=[],
            )
        )

        self.assertEqual(response.normalized_fields["destination_city"], "Tokyo")
        self.assertEqual(response.normalized_fields["start_date"], "2026-07-10")
        self.assertNotIn("start_date", response.missing_fields)
        self.assertIn("budget", response.missing_fields)

    def test_complete_prompt_becomes_ready(self):
        service = PlanningService(
            llm_gateway=FakeGateway(
                payload={
                    "normalized_fields": {
                        "origin_city": "Almaty",
                        "destination_country": "Japan",
                        "destination_city": "Tokyo",
                        "start_date": "2026-07-10",
                        "end_date": "2026-07-17",
                        "budget": 900000,
                        "transport_type": "flight",
                        "trip_purpose": "family",
                        "citizenship": "Kazakhstan",
                    },
                    "assistant_summary": "Ready to confirm.",
                }
            )
        )

        response = service.plan_trip(
            PlanningRequest(
                trip_id="trip-3",
                action="confirm_readiness",
                user_prompt="All details are confirmed",
                current_trip={},
                chat_history=[],
            )
        )

        self.assertEqual(response.missing_fields, [])
        self.assertTrue(response.ready_for_confirmation_hint)

    def test_conflicting_field_is_reported(self):
        service = PlanningService(
            llm_gateway=FakeGateway(
                payload={
                    "normalized_fields": {
                        "destination_country": "Turkey",
                    }
                }
            )
        )

        response = service.plan_trip(
            PlanningRequest(
                trip_id="trip-4",
                action="recheck_fields",
                user_prompt="Actually let's go to Turkey",
                current_trip={"destination_country": "Japan"},
                chat_history=[],
            )
        )

        self.assertIn("destination_country", response.changed_fields)
        self.assertIn("destination_country", response.conflicting_fields)

    def test_legacy_parse_preserves_arbitrary_country(self):
        service = PlanningService(
            llm_gateway=FakeGateway(
                payload={
                    "normalized_fields": {
                        "destination_country": "Spain",
                        "destination_city": "Barcelona",
                    }
                }
            )
        )

        response = service.parse_trip_legacy("Trip to Barcelona")

        self.assertEqual(response.parsed.country, "Spain")
        self.assertEqual(response.parsed.city, "Barcelona")

    def test_json_failure_returns_structured_partial_response(self):
        service = PlanningService(llm_gateway=FailingJSONGateway())

        response = service.plan_trip(
            PlanningRequest(
                trip_id="trip-5",
                action="collect_fields",
                user_prompt="Trip to Japan",
                current_trip={"destination_country": "Japan"},
                chat_history=[],
            )
        )

        self.assertEqual(response.normalized_fields["destination_country"], "Japan")
        self.assertTrue(response.extraction_notes)
        self.assertIn("destination_city", response.missing_fields)


if __name__ == "__main__":
    unittest.main()
