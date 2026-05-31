"""DeepSeek/OpenAI client wrapper used by agent services."""

from __future__ import annotations

import logging
import os
import time
from typing import Any

from dotenv import load_dotenv
from openai import OpenAI

from json_utils import JSONParseError, parse_json_object

logger = logging.getLogger(__name__)

load_dotenv()


class LLMTransportError(RuntimeError):
    """Raised when the upstream LLM call fails."""


class DeepSeekGateway:
    """Small wrapper around DeepSeek chat completions."""

    def __init__(
        self,
        client: OpenAI | None = None,
        api_key: str | None = None,
        base_url: str = "https://api.deepseek.com",
        model: str = "deepseek-chat",
    ) -> None:
        self._client = client
        self._api_key = api_key
        self._base_url = base_url
        self._model = model

    def _ensure_client(self) -> OpenAI:
        if self._client is not None:
            return self._client
        api_key = self._api_key or os.getenv("DEEPSEEK_API_KEY")
        if not api_key:
            raise LLMTransportError("DEEPSEEK_API_KEY is not set")
        self._client = OpenAI(api_key=api_key, base_url=self._base_url)
        return self._client

    def call_text(
        self,
        *,
        user_text: str,
        system_prompt: str,
        temperature: float = 0.1,
        max_tokens: int = 512,
    ) -> str:
        started_at = time.perf_counter()
        try:
            response = self._ensure_client().chat.completions.create(
                model=self._model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_text},
                ],
                temperature=temperature,
                max_tokens=max_tokens,
            )
        except Exception as exc:  # pragma: no cover - network/provider failure
            raise LLMTransportError(str(exc)) from exc

        elapsed_ms = int((time.perf_counter() - started_at) * 1000)
        logger.info(
            "llm_call_success model=%s duration_ms=%s max_tokens=%s",
            self._model,
            elapsed_ms,
            max_tokens,
        )
        return (response.choices[0].message.content or "").strip()

    def call_json(
        self,
        *,
        user_text: str,
        system_prompt: str,
        temperature: float = 0.0,
        max_tokens: int = 900,
    ) -> tuple[dict[str, Any], str]:
        raw = self.call_text(
            user_text=user_text,
            system_prompt=system_prompt,
            temperature=temperature,
            max_tokens=max_tokens,
        )
        try:
            return parse_json_object(raw), raw
        except JSONParseError:
            logger.warning("llm_json_parse_failed")
            raise
