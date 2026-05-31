"""FastAPI routes for planning extraction."""

from __future__ import annotations

from fastapi import APIRouter, HTTPException

from planning_models import PlanningRequest, PlanningResponse, TripRequest, TripResponse
from planning_service import PlanningService


def create_planning_router(service: PlanningService) -> APIRouter:
    router = APIRouter()

    @router.post("/plan-trip", response_model=PlanningResponse)
    async def plan_trip(request: PlanningRequest) -> PlanningResponse:
        try:
            return service.plan_trip(request)
        except Exception as exc:
            raise HTTPException(
                status_code=502,
                detail=f"Planning service error: {exc}",
            ) from exc

    @router.post("/parse-trip", response_model=TripResponse)
    async def parse_trip(request: TripRequest) -> TripResponse:
        try:
            return service.parse_trip_legacy(request.text)
        except Exception as exc:
            raise HTTPException(
                status_code=422,
                detail=f"Legacy parse error: {exc}",
            ) from exc

    return router
