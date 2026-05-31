# Smart Travel Halyk Backend

Go backend for Smart Travel Halyk with:

- `Fiber v3` HTTP server
- `PostgreSQL` + auto migrations via `goose`
- `Trip planning` prototype endpoints under `/api/v1/trips`
- `/health` and `/api/v1/healthcheck/*` endpoints
- Prometheus metrics support
- Swagger generation support
- Docker Compose for local development

## Quick Start

1. Copy `.env.example` to `.env`
2. Update `config/config.local.yaml` if needed
3. Run:

```bash
docker compose up --build
```

API defaults:

- App: `http://localhost:8080`
- Health: `http://localhost:8080/health`
- Trips: `http://localhost:8080/api/v1/trips`
- Readiness: `http://localhost:8080/health/readiness`
- Liveness: `http://localhost:8080/health/liveness`
- Metrics: `http://localhost:8080/metrics`

## Swagger

Generate Swagger locally:

```bash
make swagger
```

Then open:

```text
http://localhost:8080/docs
```

## Full Integration Suite

For the full `mobile-consumer -> backend -> agent` wiring check, run:

```bash
make integration-test-build
make integration-test
```

This suite:

- starts `postgres`, `backend`, and `agent`
- validates `/parse-trip` on the live agent
- validates the full planning flow under `/api/v1/trips/*`
- validates mobile-facing endpoints:
  - `/api/v1/user-profile`
  - `/api/v1/recommendations`
  - `/api/v1/trips/{tripId}`
  - `/api/v1/hotels/{hotelId}`

## Development Notes

- Add new feature modules under `internal/<module>`
- Wire modules only from `cmd/server/main.go`
- Keep shared infrastructure in `pkg/`
- Add schema changes in `db/migrations`
