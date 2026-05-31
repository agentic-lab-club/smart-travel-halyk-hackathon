# tripdetails

Owns generated trip read models used by mobile after planning is confirmed.

Routes:
- `GET /api/v1/trips/:tripId`
- `GET /api/v1/trips/:tripId/options/transport`
- `POST /api/v1/trips/:tripId/options/transport/:optionId/select`
- `GET /api/v1/trips/:tripId/options/hotels`
- `POST /api/v1/trips/:tripId/options/hotels/:optionId/select`
- `POST /api/v1/trips/:tripId/activities`
- `GET /api/v1/trips/:tripId/budget`
- `GET /api/v1/trips/:tripId/visa`
- `GET /api/v1/trips/:tripId/reviews`

Tests:
- `go test ./internal/tripdetails`
