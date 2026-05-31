# Tests

This repository currently has automated tests in:

- `backend/` for Go unit and integration-style tests
- `backend/` full integration suite for `backend -> agent` and mobile-facing endpoint flow
- `agent/` for Python `unittest` API and planning-service tests

Automated test commands for `App/` are not wired at the repository root yet, so they are not part of the root-level "run all tests" flow.

## Prerequisites

- Docker Desktop is running
- root `.env` exists and contains the variables required by `docker-compose.yml`
- commands are run from the repository root

## Run All Existing Tests

Use the root `Makefile` target:

```bash
make test
```

This is an alias for:

```bash
make test-all
```

## Run Backend Tests Only

Runs all Go tests through the `backend-test` Docker Compose service:

```bash
make test-backend
```

Direct Docker Compose equivalent:

```bash
docker compose run --rm --no-deps backend-test go test ./...
```

## Run Backend Full Integration Suite

This is the highest-signal backend validation before mobile integration. It runs the module-level integration flow from `backend/` and checks the live `backend + agent` wiring.

Build the images first:

```bash
make test-backend-integration-build
```

If Docker cache is warm, this step may finish very quickly and may not rebuild anything substantial. That is expected.

Then run the suite:

```bash
make test-backend-integration
```

Or run both steps together:

```bash
make test-backend-integration-all
```

Direct module-level equivalent:

```bash
cd backend
make integration-test-build
make integration-test
```

This suite validates:

- live `agent` availability
- live `backend` availability
- planning flow under `/api/v1/trips/*`
- mobile-facing endpoints:
  - `/api/v1/user-profile`
  - `/api/v1/recommendations`
  - `/api/v1/trips/{tripId}`
  - `/api/v1/hotels/{hotelId}`

Important note:

- these root targets intentionally delegate into `backend/Makefile`
- the real integration orchestration lives in `backend` because it uses `backend/docker-compose.yml` and `backend/docker-compose.integration.yml`
- successful output like `ok .../backend/tests/integration` means the suite really executed
- output like `(cached)` is normal for `go test` and means the Go test result was reused from cache because the test inputs did not change
- even when the test result is cached, the Docker integration stack can still be created and removed during the orchestration step

## Run Backend Full Integration Suite Without Go Test Cache

If you want to force a fresh integration test run without Go test cache:

```bash
cd backend
docker compose -f docker-compose.yml -f docker-compose.integration.yml up -d postgres agent golang-integration
docker compose -f docker-compose.yml -f docker-compose.integration.yml run --rm --no-deps golang-test go test -count=1 -tags=integration ./tests/integration
docker compose -f docker-compose.yml -f docker-compose.integration.yml down
```

Use this when:

- you want to verify the suite re-runs from scratch
- you suspect a cached Go test result is hiding a flaky integration issue
- you want a clean confidence check before mobile integration

## Manual Testing Flow

This section is the exact human flow for checking the system manually in the right order:

1. test the `agent` directly
2. test the `backend` directly
3. test the real app by clicking through the mobile UI

Do not start with mobile first. If `agent` or `backend` is broken, mobile results will be misleading.

## Manual Testing Prerequisites

### Step 1. Start required services

Run from the repository root:

```bash
docker compose up -d postgres minio minio-init agent
docker compose up --build -d backend
```

### Step 2. Check that services are healthy

Run:

```bash
docker compose ps
```

You want to see:

- `agent` -> `Up`
- `backend` -> `Up` and healthy
- `postgres` -> `Up` and healthy

If `backend` was changed recently, also refresh swagger:

```bash
cd backend
make swagger
cd ..
docker compose up --build -d backend
```

### Step 3. Open the correct Swagger pages

Open these in the browser:

- Agent Swagger: `http://127.0.0.1:8000/docs`
- Backend Swagger: `http://127.0.0.1:8080/docs`

If Swagger UI looks stale:

- hard refresh with `Ctrl+F5`
- or reopen with a query param like `http://127.0.0.1:8080/docs/?v=2`

## 1. Detailed Manual Testing For Agent Swagger

### Goal

Make sure the AI agent service itself can:

- accept a planning request
- extract known fields
- keep unknown fields missing
- return structured JSON

### Step 1. Check health

In Agent Swagger:

- open `GET /health`
- click `Try it out`
- click `Execute`

Expected:

- HTTP status `200`
- response shows the service is healthy

If this fails, stop here. Backend and mobile testing will not be trustworthy.

### Step 2. Find the planning endpoint

In Agent Swagger, find the planning endpoint used for trip extraction.

Depending on the current agent version, this may be:

- `/plan-trip`
- or a temporary compatibility endpoint such as `/parse-trip`

Use the newest planning endpoint if both exist.

### Step 3. Send an incomplete trip request

Use a request that intentionally omits some required fields.

If the endpoint is `/plan-trip`, use a body like:

```json
{
  "trip_id": "manual-test-1",
  "action": "collect_fields",
  "user_prompt": "I want to travel from Almaty to Tokyo with my wife. We want a calm family trip, but we have not decided the exact dates or budget yet.",
  "current_trip": {},
  "chat_history": []
}
```

If the endpoint is the legacy `/parse-trip`, use the body shape shown in Swagger and put the same idea into the text field.

### Step 4. Read the response carefully

You want to verify these points:

- the response is HTTP `200`
- destination-related fields are extracted
- already known values appear in structured JSON
- missing values stay missing
- the agent does not invent dates or budget

Expected interpretation:

- `origin_city` should be something like `Almaty`
- destination should be something like `Tokyo` or `Japan/Tokyo`
- `trip_purpose` may be something like `family`
- dates should still be missing
- budget should still be missing

### Step 5. Send a follow-up request with the missing values

If `/plan-trip` supports iterative requests, send a second request with previous state included.

Example:

```json
{
  "trip_id": "manual-test-1",
  "action": "collect_fields",
  "user_prompt": "Our budget is 4000 dollars total. We want to travel from September 10 until September 18.",
  "current_trip": {
    "origin_city": "Almaty",
    "destination_city": "Tokyo",
    "trip_purpose": "family"
  },
  "chat_history": []
}
```

Expected:

- previously extracted fields remain preserved
- budget is added
- start and end dates are added
- fewer missing fields remain than before

### Step 6. Decide whether Agent is healthy enough

Agent manual testing is considered good if:

- health endpoint works
- planning endpoint returns valid JSON
- missing fields are identified instead of guessed
- a second request can complete more fields without deleting earlier fields

### Step 7. Test the `/agent` follow-up question flow

This is a separate manual check from trip planning.

Its purpose is to verify that the existing guide/chat-style `agent` endpoint still works with:

- `session_id`
- follow-up questions
- context memory between requests

### Step 7.1 Find the `/agent` endpoint in Agent Swagger

Open Agent Swagger:

- `http://127.0.0.1:8000/docs`

Find the endpoint:

- `POST /agent`

### Step 7.2 Send the first question

Click `Try it out` and use a body like:

```json
{
  "input_text": "Tell me about top places to visit in Tokyo",
  "user_id": 1,
  "session_id": "11111111-1111-1111-1111-111111111111",
  "language": "en"
}
```

Then click `Execute`.

Expected:

- HTTP `200`
- the agent returns a useful answer
- the response is not empty
- the request succeeds with the given `session_id`

### Step 7.3 Send a real follow-up question with the same `session_id`

Use the same endpoint again.

Keep:

- `user_id` the same
- `session_id` the same
- `language` the same

Change only `input_text`.

Example follow-up request:

```json
{
  "input_text": "Which of those places are best for a quiet family walk?",
  "user_id": 1,
  "session_id": "11111111-1111-1111-1111-111111111111",
  "language": "en"
}
```

Then click `Execute`.

Expected:

- HTTP `200`
- the agent answers as a follow-up to the previous message
- the answer should feel context-aware
- it should not behave like a completely unrelated first request

### Step 7.4 Send a second follow-up question

Use the same `session_id` again:

```json
{
  "input_text": "Now suggest two good evening food areas near those places",
  "user_id": 1,
  "session_id": "11111111-1111-1111-1111-111111111111",
  "language": "en"
}
```

Expected:

- HTTP `200`
- the answer still uses the earlier conversation context
- the session behaves consistently across multiple turns

### Step 7.5 Verify that a new session behaves like a fresh conversation

Now send the same kind of request, but with a different session id:

```json
{
  "input_text": "Which of those places are best for a quiet family walk?",
  "user_id": 1,
  "session_id": "22222222-2222-2222-2222-222222222222",
  "language": "en"
}
```

Expected:

- HTTP `200`
- the answer should behave more like a new conversation
- it should not strongly depend on the context of `11111111-1111-1111-1111-111111111111`

This step confirms that session memory is tied to `session_id`.

### Step 7.6 Decide whether `/agent` follow-up behavior is healthy enough

The follow-up flow is considered good if:

- first request succeeds
- follow-up requests with the same `session_id` feel context-aware
- a different `session_id` behaves like a fresh conversation

## 2. Detailed Manual Testing For Backend Swagger

### Goal

Make sure the backend:

- exposes the new endpoints in Swagger
- can call the live agent
- can drive the full planning flow
- can return the final mobile-facing trip response

### Step 1. Confirm the new endpoints are visible

Open `http://127.0.0.1:8080/docs` and make sure you can see these endpoint groups:

- `GET /api/v1/user-profile`
- `GET /api/v1/recommendations`
- `POST /api/v1/trips`
- `PATCH /api/v1/trips/{tripId}`
- `GET /api/v1/trips/{tripId}`
- `POST /api/v1/trips/{tripId}/chat/messages`
- `GET /api/v1/trips/{tripId}/chat/messages`
- `POST /api/v1/trips/{tripId}/confirm`
- `POST /api/v1/trips/{tripId}/regenerate`
- `GET /api/v1/hotels/{hotelId}`

If these endpoints are not visible, stop and fix Swagger before doing any more manual testing.

### Step 2. Check simple read endpoints first

#### 2.1 User profile

- open `GET /api/v1/user-profile`
- click `Try it out`
- click `Execute`

Expected:

- HTTP `200`
- JSON response for profile
- no server error

#### 2.2 Recommendations

- open `GET /api/v1/recommendations`
- click `Try it out`
- click `Execute`

Expected:

- HTTP `200`
- array or response object with recommendation cards
- no server error

These two checks prove that the backend read-model endpoints are alive before the more complex planning flow.

### Step 3. Create a new trip draft

- open `POST /api/v1/trips`
- click `Try it out`
- send a simple body, for example:

```json
{
  "title": "Manual Tokyo Trip"
}
```

- click `Execute`

Expected:

- HTTP `201`
- response is a planning-state response
- response contains `trip_id`
- response contains `status`
- response contains `missing_fields`

Important:

- this endpoint should not return the final trip itinerary yet
- if it immediately returns full generated trip details, the planning flow is broken

### Step 4. Save the returned `trip_id`

Copy the exact `trip_id` from the response.

You will use the same `trip_id` in all the next backend calls.

### Step 5. Send the first planning message

Open `POST /api/v1/trips/{tripId}/chat/messages`.

- replace `{tripId}` with the real trip id
- click `Try it out`
- send a body like:

```json
{
  "content": "I want to travel from Almaty to Tokyo with my wife. We want a relaxed family vacation, but we still do not know the exact dates or budget."
}
```

- click `Execute`

Expected:

- HTTP `200`
- response contains planning chat state
- response contains updated trip planning data
- response contains `missing_fields`

What should be missing after this call:

- exact dates
- budget
- anything else required by backend schema that was not provided

### Step 6. Verify current planning state

Open `GET /api/v1/trips/{tripId}/chat/messages`.

- click `Try it out`
- click `Execute`

Expected:

- HTTP `200`
- message history includes your prompt
- planning state reflects what backend has already extracted

This step confirms the backend is saving chat/planning state correctly.

### Step 7. Fill missing values

Now provide the missing fields.

You can do this either by:

- `PATCH /api/v1/trips/{tripId}`
- or by sending another `POST /api/v1/trips/{tripId}/chat/messages`

Use whichever path your backend team expects as the main UX path.

#### Option A. Patch the trip directly

Use a body like:

```json
{
  "budget": 4000,
  "start_date": "2026-09-10",
  "end_date": "2026-09-18",
  "citizenship": "Kazakhstan",
  "transport_type": "flight"
}
```

Expected:

- HTTP `200`
- `missing_fields` list becomes smaller
- `ready_for_confirmation` may become `true`

#### Option B. Send another chat message

Use:

```json
{
  "content": "Our total budget is 4000 dollars. We want to go from September 10 to September 18. My citizenship is Kazakhstan. We prefer to fly."
}
```

Expected:

- HTTP `200`
- backend extracts the new values
- `missing_fields` becomes smaller
- `ready_for_confirmation` may become `true`

### Step 8. Confirm that planning is ready

Look at the latest backend response.

You want:

- `missing_fields` is empty, or only contains fields that are truly optional in your flow
- `ready_for_confirmation` is `true`

If backend still says it is not ready, do not call `confirm` yet. Fix missing values first.

### Step 9. Confirm the trip

Open `POST /api/v1/trips/{tripId}/confirm`.

- click `Try it out`
- execute with the trip id

Expected:

- HTTP `200`
- backend returns a generated mobile-facing trip response, or confirms generation success depending on the contract

This step proves the final generation gate works only after explicit confirmation.

### Step 10. Read the final trip details

Open `GET /api/v1/trips/{tripId}` and execute it.

Expected:

- HTTP `200`
- final mobile-facing trip response
- trip title/subtitle
- segments or itinerary
- budget data
- visa data
- map or route-related data if present in the contract

This is the most important backend read-model check before mobile integration.

### Step 11. Check secondary read endpoints

If available in the generated response, also test:

- `GET /api/v1/trips/{tripId}/budget`
- `GET /api/v1/trips/{tripId}/visa`
- `GET /api/v1/trips/{tripId}/reviews`
- `GET /api/v1/trips/{tripId}/options/hotels`
- `GET /api/v1/trips/{tripId}/options/transport`

If hotel options return one or more hotel ids, also test:

- `GET /api/v1/hotels/{hotelId}`

Expected:

- every endpoint returns `200`
- shapes are stable
- no endpoint falls back to old contract shapes unexpectedly

### Step 12. Decide whether Backend is healthy enough

Backend manual testing is considered good if:

- Swagger shows the new endpoints
- create-trip works
- chat message updates planning state
- missing fields come from backend
- confirmation is required before final generation
- final trip details endpoint returns a mobile-facing DTO
- profile, recommendations, and hotel details endpoints respond successfully

## 3. Detailed Manual Testing For Mobile

### Goal

Make sure the real app can complete the flow by button clicking against the real backend, not only against mocks.

### Step 1. Launch the app against the real backend

Before opening the app, make sure:

- backend is running on the expected host and port
- agent is running
- the mobile app is configured to call this backend

If the app has environment switching, select the environment that points to your local backend.

### Step 2. Open the first screen

When the app starts, go to the entry screen or recommendations screen.

Expected:

- the screen loads without crashing
- recommendation content appears
- there is no immediate decode error or empty-state caused by wrong DTOs

If recommendations do not load, stop and inspect backend `GET /api/v1/recommendations`.

### Step 3. Start a new trip from the UI

Tap the button that starts trip creation.

Examples:

- `Create trip`
- `Start planning`
- `Plan my trip`

Expected:

- the app navigates to the trip planning flow
- no immediate API error is shown

### Step 4. Enter an incomplete prompt

In the planning text field, enter:

`I want to go from Almaty to Tokyo with my wife. We want a quiet family vacation but we do not know the dates or budget yet.`

Tap the submit button.

Examples:

- `Send`
- `Continue`
- `Plan`

Expected:

- request is sent successfully
- app does not open final trip details yet
- app shows a missing-fields step or follow-up questions

Very important validation:

- mobile must show missing fields returned by backend
- mobile must not locally invent what is required

### Step 5. Fill the missing fields through the UI

Enter the missing values requested by the app.

Typical values:

- budget: `4000`
- start date: `2026-09-10`
- end date: `2026-09-18`
- citizenship: `Kazakhstan`
- transport preference: `Flight`

Tap the next submit or continue button.

Expected:

- the app sends another backend request
- the missing-fields list becomes smaller or disappears
- the app moves toward a confirmation/review screen

### Step 6. Review the extracted data

When the app shows a review or confirmation screen, inspect what it displays.

Expected:

- origin is correct
- destination is correct
- dates are correct
- budget is correct
- trip purpose or vibe is reasonable

Important:

- these values must come from backend state
- the app should be rendering normalized backend output, not its own guessed version

### Step 7. Tap the confirm button

Tap the final confirmation action.

Examples:

- `Confirm`
- `Generate trip`
- `Build plan`

Expected:

- app shows loading
- backend generation starts
- app eventually opens the final selected trip screen

If the app opens the final trip before explicit confirmation, the flow is incorrect.

### Step 8. Inspect the final trip screen

On the final trip screen, manually inspect:

- title
- subtitle
- travel dates
- duration
- people count
- itinerary or segment list
- budget block
- visa block
- hotel or transport options if shown
- warnings or notices if shown

Expected:

- the screen renders without decode errors
- there are no obvious empty placeholders caused by contract mismatches
- the content looks consistent with the data entered earlier

### Step 9. Open nested detail screens

If the UI supports them, tap into:

- hotel details
- budget details
- visa details
- reviews
- transport options

Expected:

- screens open successfully
- details are populated from backend
- no mock-only behavior is required for the flow to continue

### Step 10. Decide whether Mobile integration is healthy enough

Mobile manual testing is considered good if:

- recommendations load from backend
- trip creation starts successfully
- incomplete prompt leads to backend-driven missing-fields UI
- user can provide missing values
- user must explicitly confirm before final trip generation
- final trip screen opens and renders backend data
- nested detail screens also work

## Final Readiness Checklist Before Declaring The System Ready

Treat the system as ready for real mobile integration only if all of these are true:

- `make test-backend` passes
- `make test-agent` passes
- `make test-backend-integration` passes
- Agent Swagger manual flow passes
- Backend Swagger manual flow passes
- Mobile manual click-through flow passes
- the same trip can move through:
  - draft creation
  - missing field collection
  - explicit confirmation
  - final generated trip details

## Run Agent Tests Only

Runs all currently existing Python tests in `agent/`:

```bash
make test-agent
```

Direct Docker Compose equivalent:

```bash
docker compose run --rm --no-deps agent python -m unittest test_planning_service.py test_api.py
```

## Build Backend Test Image

If backend test dependencies or the Dockerfile test stage changed:

```bash
make test-build-backend
```

Backward-compatible alias:

```bash
make test-build
```

## Current Test Inventory

Backend Go tests currently detected:

- `backend/pkg/timekit/timekit_test.go`
- `backend/internal/tripdetails/module_test.go`
- `backend/internal/healthcheck/module_test.go`
- `backend/internal/trip/planner_client_test.go`
- `backend/internal/trip/module_test.go`
- `backend/internal/tripplanning/module_test.go`
- `backend/tests/integration/journey_test.go`

Agent Python tests currently detected:

- `agent/test_planning_service.py`
- `agent/test_api.py`
