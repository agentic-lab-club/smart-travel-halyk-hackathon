import unittest

from fastapi.testclient import TestClient

from guide_models import AgentHistoryResponse, AgentParsedQuery, AgentResponse
from main import create_app
from planning_models import PlanningRequest, PlanningResponse


class FakePlanningService:
    def plan_trip(self, request: PlanningRequest) -> PlanningResponse:
        return PlanningResponse(
            normalized_fields={
                "origin_city": "Almaty",
                "destination_country": "Japan",
                "destination_city": "Tokyo",
            },
            missing_fields=["start_date", "end_date", "budget", "transport_type", "trip_purpose", "citizenship"],
            optional_fields={},
            assistant_summary="Need dates and budget.",
            vibe_labels=["family"],
            visa_insights={},
            weather_insights=[],
            review_summaries=[],
            changed_fields=["destination_country", "destination_city"],
            conflicting_fields=[],
            ready_for_confirmation_hint=False,
            field_confidence={"destination_country": "high"},
            extraction_notes=[],
            raw_text='{"normalized_fields": {"destination_country": "Japan"}}',
        )

    def parse_trip_legacy(self, text: str):
        from planning_models import TripData, TripResponse

        return TripResponse(
            parsed=TripData(country="Japan", city="Tokyo", cost=900000),
            raw_text='{"country":"Japan","city":"Tokyo","cost":900000}',
        )


class FakeGuideService:
    def ask(self, request):
        return AgentResponse(
            user_id=request.user_id,
            parsed_query=AgentParsedQuery(
                question=request.input_text,
                city="Tokyo",
                include_attractions=True,
                include_restaurants=True,
                include_seasonal_events=True,
            ),
            answer="Tokyo is great for food and culture.",
            raw_text="Tokyo is great for food and culture.",
            context={"database": {}, "user": {}, "memory": {"session_id": request.session_id}},
        )

    def history(self, user_id: int, session_id: str):
        return AgentHistoryResponse(user_id=user_id, session_id=session_id, messages=[])


class APITests(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(
            create_app(
                planning_service=FakePlanningService(),
                guide_service=FakeGuideService(),
            )
        )

    def test_health(self):
        response = self.client.get("/health")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {"status": "ok"})

    def test_plan_trip_contract(self):
        response = self.client.post(
            "/plan-trip",
            json={
                "trip_id": "trip-1",
                "action": "collect_fields",
                "user_prompt": "Family trip to Tokyo",
                "current_trip": {},
                "chat_history": [],
            },
        )
        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertEqual(payload["normalized_fields"]["destination_country"], "Japan")
        self.assertIn("budget", payload["missing_fields"])
        self.assertEqual(payload["assistant_summary"], "Need dates and budget.")

    def test_parse_trip_legacy_contract(self):
        response = self.client.post("/parse-trip", json={"text": "Trip to Tokyo"})
        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertEqual(payload["parsed"]["country"], "Japan")
        self.assertEqual(payload["parsed"]["city"], "Tokyo")
        self.assertEqual(payload["parsed"]["cost"], 900000)

    def test_agent_contract_stays_stable(self):
        response = self.client.post(
            "/agent",
            json={
                "input_text": "What to see in Tokyo?",
                "user_id": 42,
                "session_id": "11111111-1111-1111-1111-111111111111",
                "language": "en",
            },
        )
        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertEqual(payload["user_id"], 42)
        self.assertEqual(payload["parsed_query"]["city"], "Tokyo")
        self.assertIn("answer", payload)
        self.assertIn("context", payload)

    def test_agent_history_contract(self):
        response = self.client.get(
            "/agent/sessions/11111111-1111-1111-1111-111111111111/messages?user_id=42"
        )
        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertEqual(payload["user_id"], 42)
        self.assertEqual(payload["session_id"], "11111111-1111-1111-1111-111111111111")
        self.assertEqual(payload["messages"], [])


if __name__ == "__main__":
    unittest.main()
