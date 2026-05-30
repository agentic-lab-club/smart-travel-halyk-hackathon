# Agent Refactoring Plan 1

## Goal

Refactor `agent/` from a narrow stateless parser plus generic place Q&A service into a planning-aware AI service that cleanly supports the backend trip flow:

1. backend creates trip draft
2. backend sends user prompt to AI agent
3. AI agent extracts normalized trip fields
4. AI agent reports missing required fields
5. backend saves state and asks user only for missing data
6. backend sends follow-up user answers back to agent
7. agent re-evaluates normalized state
8. when all required fields are present and confirmed, backend triggers final bundle planning

This plan is only for `agent/`.

## Current State

The current `agent/main.py` has two different responsibilities mixed together:

- `/parse-trip`
  - stateless trip extraction
  - returns only `parsed` + `raw_text`
  - supports a narrow fixed `TripData`
- `/agent`
  - place/travel Q&A with DB-backed memory
  - optimized for attraction/city questions, not trip planning workflow

### Current gaps versus required flow

- `/parse-trip` does not understand:
  - trip status
  - required field schema
  - missing fields
  - confirmation readiness
  - previous normalized state
  - follow-up planning chat semantics
- it only accepts raw `text`, not session-aware planning context
- it only returns extracted data, not workflow metadata
- supported fields are too narrow for the target planning flow
- parsing and place Q&A live in one large `main.py` without clear logical boundaries

## Target Role Of `agent/`

The AI agent should be an extraction and planning-assist service for backend, not the source of business state.

### Backend remains source of truth for:

- required field schema
- trip lifecycle status
- persistence
- final confirmation decision
- final bundle generation trigger

### Agent becomes source of truth for:

- natural-language extraction
- normalization proposals
- missing-field reasoning support
- assistant follow-up phrasing
- optional enrichment hints

## Required Contract Direction

The current `/parse-trip` contract should be replaced or superseded by a planning-aware endpoint.

### Recommended new responsibility

The agent should accept:

- current trip state
- latest user prompt
- optional prior chat history
- explicit action

And return:

- normalized fields
- missing fields
- extracted optional fields
- assistant summary
- confidence or extraction notes if needed

### Recommended request shape

Suggested backend-to-agent request model:

- `trip_id`
- `action`
  - `collect_fields`
  - `recheck_fields`
  - `confirm_readiness`
  - optional future `generate_hints`
- `user_prompt`
- `current_trip`
- `chat_history`
- optional `required_fields`

### Recommended response shape

Suggested agent-to-backend response model:

- `normalized_fields`
- `missing_fields`
- `optional_fields`
- `assistant_summary`
- `vibe_labels`
- `visa_insights`
- `weather_insights`
- `review_summaries`
- optional `field_confidence`

Important rule:

- backend should still compute final business status, but agent should return enough structured info for backend to do so deterministically

## Refactoring Boundaries

Keep all write changes inside `agent/`.

Refactor by logical responsibility, even if phase 1 stays in the same module:

- planning extraction
- place Q&A
- memory/session utilities
- DeepSeek/OpenAI client wrapper
- prompt templates
- Pydantic contracts

## Required Logical Split

### 1. Planning Extraction Layer

Owns:

- trip extraction prompts
- normalization logic
- missing-field assistance
- planning-specific request/response models

Suggested files:

- `planning_models.py`
- `planning_prompts.py`
- `planning_service.py`

### 2. Place Q&A Layer

Owns:

- current `/agent` attraction/place response flow
- database context fetch
- answer memory for place guidance

Suggested files:

- `guide_models.py`
- `guide_service.py`
- `guide_prompts.py`

### 3. LLM Gateway Layer

Owns:

- DeepSeek/OpenAI client construction
- request retry policy
- sanitization
- JSON extraction helpers

Suggested files:

- `llm_client.py`
- `json_utils.py`

### 4. Memory Layer

Owns:

- session persistence helpers
- message save/load
- answer memory loading

Suggested files:

- `memory_repository.py`
- `memory_models.py`

### 5. API Layer

Owns:

- FastAPI route registration
- HTTP validation
- mapping service errors to HTTP errors

Suggested files:

- `api_planning.py`
- `api_guide.py`
- `main.py` as thin bootstrap only

## Planning Flow Refactor

### Phase 1. Replace Stateless Trip Parsing With Planning-Aware Parsing

Current `/parse-trip` is too small for the required flow.

Refactor it so agent can process:

- initial prompt
- follow-up answers
- partially filled trip state
- repeated extraction over time

Required behavior:

- if user gives only destination and family intent, agent returns missing budget and dates
- if user later gives dates and budget, agent updates normalized state instead of starting over
- agent must not invent missing values

### Phase 2. Introduce Required-Field Awareness

Even if backend owns the canonical schema, the agent should receive or know the backend-required field list and use it while producing structured output.

Recommended first required field set:

- `origin_city`
- `destination_country`
- `destination_city`
- `start_date`
- `end_date`
- `budget`
- `transport_type`
- `trip_purpose`
- `citizenship`

Optional later additions:

- `travelers`
- `hotel_preferences`
- `insurance_needed`
- `event_interest`
- `interests`

### Phase 3. Add Follow-Up Assistant Output

The agent should return short assistant guidance that backend/mobile can show to collect the next missing inputs.

Examples:

- ask for travel dates
- ask for budget
- ask for citizenship if visa logic depends on it

This must be structured enough for backend/mobile to render without deriving business logic themselves.

### Phase 4. Add Confirmation-Oriented Readiness Checks

The agent should help backend answer:

- are all required fields present?
- does the current prompt contradict prior state?
- which values changed?

Recommended structured additions:

- `changed_fields`
- `conflicting_fields`
- `ready_for_confirmation_hint`

Backend still decides final status, but the agent should expose this reasoning clearly.

## Prompt Refactor

### Current issue

Prompt text is embedded directly in `main.py` and partially tied to current narrow extraction output.

### Required change

Separate prompts by concern:

- trip planning extraction prompt
- planning follow-up prompt
- place Q&A extraction prompt
- place Q&A answer prompt

### Prompt rules

- planning prompts must optimize for deterministic JSON
- they must explicitly forbid guessing missing fields
- they must preserve prior known fields unless contradicted
- they must treat current user message as higher priority than memory when conflict exists

## Data Model Refactor

Current `TripData` is too narrow and too transport-specific for the target system.

Refactor planning models into:

- `PlanningRequest`
- `PlanningResponse`
- `NormalizedTripFields`
- `MissingField`
- optional `FieldConfidence`

Do not force backend-shaped storage concerns into the agent models, but do align names with backend planning contracts.

## Error Handling Requirements

The current service mainly returns:

- invalid JSON errors
- DeepSeek API errors

Refactor to distinguish:

- LLM transport failure
- invalid JSON from model
- schema validation failure
- unsupported value normalization
- partial extraction success

Recommended behavior:

- partial extraction should still return structured output where possible
- backend should not receive a 500-equivalent when some fields were successfully parsed

## Observability Requirements

Add structured logging for:

- endpoint
- request action
- session or trip id
- model call duration
- parse success/failure
- validation failures

Sensitive rule:

- do not log raw prompts blindly if they may contain personal trip details

## Backward Compatibility Strategy

### Recommended approach

Do not immediately delete current `/agent`.

Instead:

- keep place Q&A endpoint behavior stable
- introduce new planning-specific endpoint or upgraded `/parse-trip` contract version
- let backend migrate to the new planning contract first

Recommended option:

- add `/plan-trip`
- keep `/parse-trip` temporarily for compatibility
- deprecate `/parse-trip` after backend migration

## Concrete Refactor Sequence

### Step 1

Split `main.py` into:

- bootstrap
- planning contracts/service
- guide contracts/service
- LLM utility layer

### Step 2

Introduce planning-specific request/response models and prompt templates.

### Step 3

Implement planning endpoint that accepts prior state plus latest prompt.

### Step 4

Add structured missing-field and assistant-summary output.

### Step 5

Add conflict/change detection for iterative planning chat.

### Step 6

Only after planning flow stabilizes, clean up or deprecate old parsing behavior.

## Testing Plan

### Unit Tests

- normalize country/date/budget extraction
- preserve previously known fields when new prompt omits them
- update fields when new prompt explicitly changes them
- compute missing fields for incomplete prompts
- detect readiness when required fields are complete

### Contract Tests

- planning request schema
- planning response schema
- backward-compatible behavior for existing guide endpoint

### Prompt/LLM Safety Tests

- invalid JSON recovery path
- partial extraction handling
- contradictory follow-up message
- ambiguous date input

### End-to-End Scenarios

1. Initial prompt without budget and dates
   - returns normalized partial fields
   - returns missing budget and dates

2. Follow-up prompt with dates only
   - keeps prior destination
   - removes date fields from missing list

3. Follow-up prompt with budget
   - becomes ready for confirmation

4. Place Q&A session still works independently
   - `/agent` remains focused on attractions/places

## Acceptance Criteria

The `agent` refactor is done when:

- trip planning extraction is no longer a stateless narrow parser only
- agent can process iterative planning chat with prior state
- agent returns structured missing fields support data
- prompts and services are logically separated from place Q&A
- `main.py` is no longer the single giant implementation file
- backend can use the agent as a deterministic planning helper instead of a raw parser
