# Backend Refactoring Plan 1

## Goal

Refactor `backend/internal/trip` so it stops acting like one mixed module and instead exposes two clear layers:

- planning workflow layer
- consumer-facing read-model layer

The backend must be logically split according to the mobile entities and feature boundaries, even if the first refactor keeps files inside `internal/trip`.

Mobile contract areas to mirror:

- `profile`
- `recommendations`
- `trip planning`
- `trip details`
- `hotel details`

## Required Architectural Rule

Backend owns:

- required field schema
- missing field computation
- trip planning state machine
- final bundle generation

Mobile only consumes:

- missing fields
- planning status
- normalized values for confirmation
- final generated trip bundle

## Current Problem

`internal/trip` currently mixes:

- trip draft storage
- AI prompt handling
- field extraction
- planning state
- transport/hotel selection
- budget/visa/reviews
- final aggregate response

This prevents stable contracts and makes the module impossible to scale cleanly.

## Target Logical Split

Keep implementation inside `backend/internal/trip` for the first pass if needed, but split the code into logical subdomains.

### 1. Planning Workflow

Owns:

- trip draft creation
- planning chat ingestion
- normalized fields update
- required field validation
- missing field computation
- planning status transitions
- confirmation eligibility

Suggested file/service group:

- `planning_state.go`
- `planning_service.go`
- `planning_contracts.go`
- `planning_handler.go`

### 2. Final Bundle Generation

Owns:

- generation trigger after explicit confirm
- enrichment from transport/hotel/activity seeds or providers
- budget assembly
- visa and review enrichment
- final bundle snapshot assembly

Suggested file/service group:

- `bundle_service.go`
- `bundle_builder.go`
- `bundle_enrichment.go`

### 3. Consumer Read Models

Owns backend-facing adapters for mobile contracts:

- `UserProfileResponse`
- `RecommendationsResponse`
- `TripDetailsResponse`
- `HotelDetailsFull`

Suggested file/service group:

- `profile_read_model.go`
- `recommendations_read_model.go`
- `trip_details_read_model.go`
- `hotel_details_read_model.go`

### 4. Internal Persistence Shape

Keep internal entities separate from outward DTOs.

Required separation:

- internal draft entity
- chat/session entity
- generation inputs
- generated bundle snapshot
- outward mobile DTOs

Do not return internal `Trip` directly as the public app contract.

## Required State Machine

Backend planning status must be explicit and stable:

- `draft`
- `collecting_input`
- `ready_for_confirmation`
- `confirmed`
- `generated`
- optional `failed`

Transition rules:

- `draft -> collecting_input` after first prompt
- `collecting_input -> ready_for_confirmation` when required schema is complete
- `ready_for_confirmation -> confirmed` only after explicit user confirm
- `confirmed -> generated` after bundle generation succeeds

Backend must reject early generation if status is not confirmable.

## Required Field Schema

The first schema version should explicitly define required fields:

- `origin_city`
- `destination_country`
- `destination_city`
- `start_date`
- `end_date`
- `budget`
- `transport_type`
- `trip_purpose`
- `citizenship`

Optional/derived fields may continue to exist, but the first refactor must stabilize the required core instead of letting AI decide everything dynamically.

## Public API Refactor

### Workflow Endpoints

Keep or add endpoints for:

- create trip draft
- get planning state
- send planning message
- patch structured fields when needed
- confirm trip
- regenerate trip

Workflow responses should return planning DTOs, not final trip details.

Recommended response DTOs:

- `PlanningTripResponse`
- `PlanningChatResponse`

These should include:

- `tripId`
- `status`
- `normalizedFields`
- `missingFields`
- `readyForConfirmation`
- `messages`
- optional assistant hints

### Consumer Read Endpoints

Add dedicated read endpoints that match mobile contracts:

- `GET /api/v1/user-profile`
- `GET /api/v1/recommendations`
- `GET /api/v1/trips/{tripId}`
- `GET /api/v1/hotels/{hotelId}`

Rules:

- `GET /trips/{tripId}` returns final `TripDetailsResponse`
- it must not return draft/planning state shape
- pre-generation planning should use dedicated planning endpoints

## DTO Mapping Rules

The backend refactor must introduce explicit mappers:

- planning entity -> planning response DTO
- generated bundle entity -> mobile `TripDetailsResponse`
- selected hotel / review data -> `HotelDetailsFull`

No handler should assemble ad hoc JSON directly from internal storage structs.

## `TripDetailsResponse` Responsibilities

The final trip read model must be assembled only after generation and must include mobile-ready fields for:

- summary
- route navigator
- map
- itinerary segments
- budget breakdown
- mode variants
- visa
- cashback
- challenges
- warnings

Important serialization requirement:

- `segments.details` must match the mobile decoding contract using `{ "kind": "...", "payload": { ... } }`

## `HotelDetailsFull` Responsibilities

The hotel read model must provide:

- base hotel info
- coordinates
- ratings by source
- grouped reviews
- review summary
- room list
- selected room
- upgrade/downgrade options
- location info
- selection reason

This should be a dedicated builder, not a thin wrapper around `HotelOption`.

## Recommended File Refactor Sequence

### Phase 1. Extract Workflow Contracts

- create dedicated planning DTOs
- isolate planning status logic
- isolate required field schema logic

### Phase 2. Extract Bundle Builder

- move generation and enrichment responsibilities out of generic service methods
- keep service entrypoints thin

### Phase 3. Add Read-Model Builders

- implement dedicated builders for:
  - profile
  - recommendations
  - trip details
  - hotel details

### Phase 4. Clean Handler Boundaries

- handlers call workflow services or read-model builders
- handlers no longer expose internal aggregate structs

### Phase 5. Optional Physical Package Split

If the first refactor stabilizes boundaries, then split physically into new internal modules later.

Recommended future package targets:

- `internal/profile`
- `internal/recommendations`
- `internal/tripplanning`
- `internal/tripdetails`
- `internal/hoteldetails`

## Testing Plan

### Workflow Tests

- create draft from prompt
- detect missing required fields
- update normalized fields after follow-up message
- transition to `ready_for_confirmation`
- reject final generation before confirm
- generate final bundle after confirm

### Contract Tests

- `PlanningTripResponse` shape
- `PlanningChatResponse` shape
- `UserProfileResponse` shape
- `RecommendationsResponse` shape
- `TripDetailsResponse` shape
- `HotelDetailsFull` shape

### Serialization Tests

- segment `details.kind`
- segment `details.payload`
- mode variant object keys
- hotel room/review nested structures

### Manual Flow Validation

1. create trip
2. send incomplete prompt
3. receive missing fields
4. send required follow-up data
5. reach ready-for-confirmation
6. confirm
7. fetch final trip
8. fetch hotel details for selected hotel

## Acceptance Criteria

The backend refactor is done when:

- required field logic is backend-owned and stable
- planning responses are separate from final read models
- final `TripDetailsResponse` is assembled by dedicated mapping code
- hotel details are exposed by a dedicated read model
- `internal/trip` is logically split even if still physically colocated
- handlers no longer leak internal planning/storage shapes as public app contracts
