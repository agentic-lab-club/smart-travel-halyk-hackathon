# AGENTS.md

## Project

This project is a hackathon MVP for **Halyk Travel**, a personalized travel planner inside a banking ecosystem.

The core product experience is:
- personalized trip recommendations;
- segmented trip timeline;
- smart map with hotel, airport, routes and attractions;
- budget breakdown;
- hotel reviews and room upgrade/downgrade options;
- cashback and financial challenges.

## Main UX concept

The selected trip screen is built around two synchronized views:

1. **Segmented timeline**
   - arrival
   - airport to hotel transfer
   - hotel check-in
   - day itinerary
   - intercity movement
   - departure

2. **Smart map**
   - airport
   - hotel
   - attractions
   - events
   - restaurants
   - routes
   - taxi/public transport estimates

Selecting a timeline segment should focus the map.
Selecting a map marker should scroll to the matching segment.

## Important product rule

Do not expose AI as a heavy chatbot-first experience.

AI should be invisible and useful through:
- recommendation labels;
- hotel and route trade-offs;
- warnings;
- hotel review summaries;
- budget explanations;
- cashback/challenge personalization.

## API contract

Use these files as source of truth:
- `docs/api/api-data-requirements.md`
- `docs/api/api-response-models.md`
- `docs/data/mock-data-requirements.md`
- `docs/data/hotel-reviews-room-selection.md`

The backend should return a ready `TripDetailsResponse` object, not raw disconnected data.

Important IDs:
- `segmentId` connects timeline, map markers, routes, warnings and smart labels.
- `markerId` identifies map markers.
- `routeId` identifies map routes.
- `selectedRoomId` identifies the room selected for the user.

## Trip modes

Support three global modes:
- `economy`
- `balanced`
- `comfort`

Changing the mode should affect:
- hotel choice;
- selected room;
- transport strategy;
- total cost;
- travel time;
- smart labels.

## Hotel requirements

Hotel data must include:
- overall rating;
- ratings by source;
- reviews grouped by source;
- summarized review;
- available rooms;
- selected room;
- upgrade and downgrade options;
- hotel location info relative to airport and trip objects.

## Coding guidelines

- Keep models typed and explicit.
- Prefer small, composable components.
- Do not hardcode business logic in UI when it belongs in API/mock data.
- Use mock data that looks production-ready.
- Keep demo flow stable and polished over adding too many features.
- Keep labels short and UI-ready.
- Use stable string IDs for every entity.
- Every visible price must use a money object with `amount` and `currency`.

## Demo priority

The main demo should show:
1. User opens recommendations.
2. User selects a trip.
3. Timeline and map appear.
4. User sees airport to hotel transfer.
5. User switches economy / balanced / comfort.
6. Hotel, route, cost and time update.
7. User sees hotel reviews, selected room, and upgrade/downgrade.
8. User sees cashback/challenge.
