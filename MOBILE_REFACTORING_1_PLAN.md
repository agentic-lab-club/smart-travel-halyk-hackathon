# Mobile Refactoring Plan 1

## Goal

Refactor `App/` so the mobile app consumes a real backend planning workflow and a real final trip bundle contract without deriving required fields or business logic locally.

The source of truth for consumer-facing entities remains:

- `App/docs/api/api-response-models.md`
- `App/docs/api/api-data-requirements.md`
- current typed Swift models in `App/SmartTravelHalyk/Core/Models`

The source of truth for required planning fields is backend schema, not UI.

## Product Flow To Support

1. User opens entry/discovery screen.
2. App loads:
   - `UserProfileResponse`
   - `RecommendationsResponse`
3. User starts trip planning by entering a prompt.
4. App creates a trip draft in backend.
5. App sends prompt to backend planning chat.
6. Backend returns:
   - normalized fields
   - missing required fields
   - updated planning status
7. App renders only backend-requested missing fields.
8. User provides missing information and confirms extracted values.
9. App explicitly calls final confirm.
10. App receives final `TripDetailsResponse`.
11. App opens `SelectedTrip` flow using backend-generated bundle.

## Refactoring Boundaries

### Keep As Source Of Truth

- `TripDetailsResponse`
- `HotelDetailsFull`
- `UserProfileResponse`
- `RecommendationsResponse`
- `TripRecommendation`
- all current typed supporting models in `Core/Models`

### Add New Workflow Models

Add a dedicated planning contract layer for pre-generation state. Do not overload `TripDetailsResponse`.

Introduce Swift models for:

- `TripPlanningStatus`
- `TripPlanningState`
- `PlanningChatResponse`
- `PlanningMessage`
- `MissingField`
- `TripConfirmationState` if confirmation UI needs its own view state

## Required Structural Changes

### 1. `TravelAPIClient`

Refactor `Core/Services/TravelAPIClient.swift` into two API groups:

- read contracts
  - `fetchUserProfile()`
  - `fetchRecommendations()`
  - `fetchTripDetails(tripId:)`
  - `fetchHotelDetails(hotelId:)`
- workflow contracts
  - `createTrip(title:)`
  - `fetchPlanningState(tripId:)`
  - `sendPlanningMessage(tripId:content:action:)`
  - `patchTripFields(tripId:payload:)` if backend exposes structured patching
  - `confirmTrip(tripId:)`
  - `regenerateTrip(tripId:)`

Requirements:

- use explicit versioned backend paths
- keep mock fallback only for preview/demo resilience
- do not embed business rules in the client

### 2. `EntryFlowViewModel`

Refactor `Features/EntryFlow/ViewModels/EntryFlowViewModel.swift` to own both:

- discovery state
- planning workflow state

Add state for:

- `activePlanningTrip`
- `planningMessages`
- `missingFields`
- `normalizedFields`
- `isPlanning`
- `isConfirming`
- `generatedTrip`
- `planningError`

Behavior rules:

- `submitChatbotPrompt()` must become async
- first prompt creates a trip if none exists
- later prompts append to the same planning session
- missing fields come from backend only
- when status becomes `ready_for_confirmation`, show confirmation UI
- only after explicit confirm should the app request final trip bundle

### 3. `EntryFlowView`

Refactor `Features/EntryFlow/Views/EntryFlowView.swift` to show three layers:

- discovery feed
- planning prompt input
- planning state summary

Add UI blocks for:

- current planning status
- normalized extracted fields preview
- backend-reported missing fields
- confirm action
- loading/error states for planning

Important rule:

- user should not navigate to `SelectedTripView` from prompt flow until final generated trip is received

### 4. Navigation

Refactor recommendation and planning navigation separately:

- recommendation cards may remain browse-first
- planning flow navigation must be data-driven from `generatedTrip`

Recommended implementation:

- `NavigationStack` destination bound to generated trip state
- no mock trip injection once real backend flow is connected

### 5. `SelectedTripViewModel`

Keep `SelectedTripViewModel` read-model driven.

Do not move planning logic into `SelectedTrip`.

Optional cleanup after backend is ready:

- replace remaining `MockTravelData` dependencies for hotel details and budget mode helpers
- fetch `HotelDetailsFull` from backend when opening hotel detail surface

## Concrete Refactor Steps

### Phase 1. Workflow Contract Layer

- add new planning models under `Core/Models`
- update API client with planning endpoints
- keep existing read models unchanged

### Phase 2. Entry Flow Integration

- make prompt submission async
- create trip draft on first prompt
- render missing fields from backend
- persist planning state in view model

### Phase 3. Confirmation And Final Navigation

- add explicit confirm action
- call backend final confirm
- open `SelectedTripView` with returned final bundle

### Phase 4. Remove Mock Coupling From Core Flow

- stop using mock selected trip for planning flow navigation
- keep mock fallback only for preview and resilience

## Acceptance Criteria

The mobile refactor is done when:

- prompt planning no longer mutates UI-only state as business truth
- app renders backend-provided missing fields
- app waits for explicit confirm before showing final bundle
- `SelectedTripView` can open from backend-generated `TripDetailsResponse`
- contract models remain typed and separated between planning workflow and final read models

## Testing Plan

### Unit / ViewModel

- first prompt creates trip and stores planning state
- second prompt reuses same trip ID
- missing fields update after each response
- confirm action is disabled until backend says ready
- confirm action loads final trip and sets navigation target

### Contract Decoding

- decode backend `TripPlanningState`
- decode backend `PlanningChatResponse`
- decode backend `TripDetailsResponse`
- decode backend `HotelDetailsFull`

### Manual QA

- incomplete prompt with missing budget and dates
- follow-up prompt fills missing fields
- confirmation step appears only when ready
- final trip opens and renders map/segments/budget
