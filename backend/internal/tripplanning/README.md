# tripplanning

Owns the trip draft and planning workflow under `/api/v1/trips/*` before the final bundle is opened in mobile.

Routes:
- `POST /api/v1/trips`
- `GET /api/v1/trips/:tripId/planning`
- `PATCH /api/v1/trips/:tripId`
- `POST /api/v1/trips/:tripId/chat/messages`
- `GET /api/v1/trips/:tripId/chat/messages`
- `POST /api/v1/trips/:tripId/confirm`
- `POST /api/v1/trips/:tripId/regenerate`

Dependencies:
- `pkg/travelcore` for shared planning state, agent orchestration, and final bundle generation.

Tests:
- `go test ./internal/tripplanning`
