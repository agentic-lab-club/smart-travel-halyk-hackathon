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

Then run the suite:

```bash
make test-backend-integration
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
