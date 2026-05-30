# Backend API Spec

## Base

- Base path: `/api/v1`
- Style: REST
- Chat response mode: normal request/response
- No streaming in MVP

## Endpoints

### `POST /trips`

Creates a trip draft.

Request:

```json
{
  "title": "Summer family trip"
}
```

### `GET /trips/{tripId}`

Returns full `TripDetailsResponse`.

### `PATCH /trips/{tripId}`

Updates trip fields collected during intake or confirmation.

### `POST /trips/{tripId}/chat/messages`

Adds a user message and returns assistant response plus missing fields.

Request:

```json
{
  "content": "Family trip to Turkey in July with budget 900000",
  "action": "collect_fields"
}
```

### `GET /trips/{tripId}/chat/messages`

Returns chat history for the current trip.

### `POST /trips/{tripId}/confirm`

Confirms fields and generates the master-plan.

### `POST /trips/{tripId}/regenerate`

Regenerates a trip from the current state.

### `GET /trips/{tripId}/options/transport`

Lists transport options.

### `POST /trips/{tripId}/options/transport/{optionId}/select`

Selects a transport option.

### `GET /trips/{tripId}/options/hotels`

Lists hotel options.

### `POST /trips/{tripId}/options/hotels/{optionId}/select`

Selects a hotel option.

### `POST /trips/{tripId}/activities`

Adds a manual place or event.

### `GET /trips/{tripId}/budget`

Returns budget summary.

### `GET /trips/{tripId}/visa`

Returns visa block.

### `GET /trips/{tripId}/reviews`

Returns review summaries.

## Aggregate Response

`TripDetailsResponse` should contain:

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

## Budget Contract

The MVP budget block returns:

- `transport_total`
- `hotel_total`
- `events_total`
- `estimated_food_total`
- `estimated_local_transport_total`
- `insurance_estimate`
- `grand_total`
- `cashback_amount`
- `bonus_amount`
- `halyk_offer_label`

## Halyk Mock Fields

The backend should expose:

- `cashback`
- `bonus`
- `halyk_offer`

These are mock values only, with no real Halyk integration.
