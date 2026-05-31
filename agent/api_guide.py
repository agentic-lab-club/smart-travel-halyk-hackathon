"""FastAPI routes for the place/travel guide endpoint."""

from __future__ import annotations

from fastapi import APIRouter, HTTPException, Query

from guide_models import AgentHistoryResponse, AgentRequest, AgentResponse
from guide_service import GuideService
from llm_client import LLMTransportError


def create_guide_router(service: GuideService) -> APIRouter:
    router = APIRouter()

    @router.post("/agent", response_model=AgentResponse)
    async def ask_agent(request: AgentRequest) -> AgentResponse:
        try:
            return service.ask(request)
        except LLMTransportError as exc:
            raise HTTPException(
                status_code=502,
                detail=f"DeepSeek API error: {exc}",
            ) from exc
        except Exception as exc:
            raise HTTPException(
                status_code=503,
                detail=f"Travel database or memory error: {exc}",
            ) from exc

    @router.get("/agent/sessions/{session_id}/messages", response_model=AgentHistoryResponse)
    async def get_agent_history(session_id: str, user_id: int = Query(default=1, alias="user_id")) -> AgentHistoryResponse:
        try:
            return service.history(user_id=user_id, session_id=session_id)
        except Exception as exc:
            raise HTTPException(
                status_code=503,
                detail=f"Travel database or memory error: {exc}",
            ) from exc

    return router
