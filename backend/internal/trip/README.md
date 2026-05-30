# Trip Module

This module owns the hackathon prototype `Smart Travel` planning flow for the mobile/frontend app.

It is the backend integration surface for:

- trip draft creation
- AI chat intake
- trip confirmation and regeneration
- transport/hotel replacement
- manual place or event insertion
- budget, visa, offer, and review read models

## Purpose

The module returns one frontend-friendly aggregate response instead of forcing the mobile app to join raw provider data itself.

Primary response shape:

- `TripDetailsResponse`

That response is designed to drive a `Todo-first` dashboard in the app.

## Main Flow

1. Frontend creates trip draft
2. Frontend sends AI chat messages
3. Backend stores trip + chat state
4. Backend adapts the request to the current Python `agent` service using `POST /parse-trip`
5. Backend enriches with mock transport, hotel, event, visa, weather, and review data
6. Backend returns a full trip dashboard payload

## Endpoints

### Trip lifecycle

- `POST /api/v1/trips`
- `GET /api/v1/trips/{tripId}`
- `PATCH /api/v1/trips/{tripId}`
- `POST /api/v1/trips/{tripId}/confirm`
- `POST /api/v1/trips/{tripId}/regenerate`

### AI chat

- `POST /api/v1/trips/{tripId}/chat/messages`
- `GET /api/v1/trips/{tripId}/chat/messages`

### Option selection

- `GET /api/v1/trips/{tripId}/options/transport`
- `POST /api/v1/trips/{tripId}/options/transport/{optionId}/select`
- `GET /api/v1/trips/{tripId}/options/hotels`
- `POST /api/v1/trips/{tripId}/options/hotels/{optionId}/select`

### Manual edits and read models

- `POST /api/v1/trips/{tripId}/activities`
- `GET /api/v1/trips/{tripId}/budget`
- `GET /api/v1/trips/{tripId}/visa`
- `GET /api/v1/trips/{tripId}/reviews`

## Key DTOs

### `CreateTripDTO`

Minimal trip draft creation payload.

```json
{
  "title": "Summer family trip"
}
```

### `PatchTripDTO`

Used before confirmation to fill normalized trip fields.

Example fields:

- `origin_city`
- `destination_country`
- `destination_city`
- `start_date`
- `end_date`
- `budget`
- `transport_type`
- `trip_purpose`
- `citizenship`
- `hotel_preferences`
- `event_interest`
- `insurance_needed`
- `interests`
- `travelers`

### `ChatMessageDTO`

```json
{
  "content": "Family trip to Japan in July with budget 900000",
  "action": "collect_fields"
}
```

### `ManualActivityDTO`

```json
{
  "kind": "event",
  "title": "Kino.kz partner event",
  "location": "Tokyo",
  "day_label": "Day 3",
  "price": 22000,
  "source_name": "Kino.kz",
  "source_link": "https://kino.kz",
  "description": "Manual event insertion"
}
```

## Main Response Contract

### `TripDetailsResponse`

Contains:

- `trip`
- `travelers`
- `todo_sections`
- `selected_transport`
- `selected_hotel`
- `activities`
- `budget`
- `visa`
- `review_summaries`
- `offers`
- `chat_entrypoints`

Frontend/mobile should treat this as the main screen contract for the trip dashboard.

## MVP Notes

- state is currently stored in-memory for the prototype
- supported mock destinations: `Kazakhstan`, `Japan`, `Turkey`, `UAE`
- external providers are mock-based
- Halyk values such as `cashback`, `bonus`, and `halyk_offer` are mock logic
- if the Python `agent` is unavailable or returns invalid data, backend falls back to its local planner
- manual edits implemented in code:
  - replace hotel
  - replace transport
  - add place/event manually

## Swagger

Swagger annotations live in [handler.go](/D:/Hackathons/smart-travel-halyk-hackathon/backend/internal/trip/handler.go).

To regenerate OpenAPI artifacts:

```powershell
make swagger-backend
```
