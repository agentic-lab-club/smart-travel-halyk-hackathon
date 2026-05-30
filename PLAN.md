# Smart Travel Prototype Plan

## Summary

This repository will implement a working prototype of `Smart Travel / Trip Planner` for the Halyk hackathon. The prototype is intentionally hybrid: the code structure should look production-like, while external integrations remain mock-based and deterministic for demo use.

The implementation is centered on five build-driving artifacts:

1. Frontend user flow
2. C4 architecture
3. Backend ERD
4. Backend REST API spec
5. AI_Agent chat spec

The prototype scope is:

- one trip equals one `master-plan`
- primary flow is `Create Trip -> AI Chat Intake -> Confirm Fields -> Trip Dashboard`
- backend is the source of truth
- AI_Agent is stateless and returns structured JSON
- Halyk ecosystem values are represented with mock fields such as `cashback`, `bonus`, and `halyk_offer`
- no real booking, payment, event checkout, installment, or real provider APIs

## User Flow

### Main flow

1. User opens the app and can view notification mocks.
2. User taps `Create Trip`.
3. User enters the AI chat intake flow.
4. AI asks for and normalizes all required fields.
5. User confirms the collected trip fields.
6. Backend requests a structured plan from `AI_Agent`.
7. Backend enriches the plan with mock transport, hotel, event, visa, weather, and review data.
8. Backend calculates total budget, cashback, bonus, and Halyk offer labels.
9. User lands on a `Todo-first` trip dashboard.
10. User can replace hotel, replace transport, or manually add place/event items.

### Supported scenarios

- Family with children building an international trip
- Solo traveler building an event-centric trip with `Kino.kz`
- Domestic tourism inside Kazakhstan

### Main screens

- Notifications
- Create Trip
- AI Chat Intake
- Confirm Trip Fields
- Trip Dashboard
- Selection/Edit screens for transport, hotels, and activities
- Embedded AI copilot inside the dashboard

## C4 Architecture

### Context

- `SwiftUI iOS App` is the client
- `Go Backend API` is the orchestration and source-of-truth layer
- `Python AI_Agent` is the planning and enrichment reasoning layer
- `PostgreSQL` exists for the backend baseline and future evolution
- mock providers represent flights, rail, hotels, weather, visa, reviews, and `Kino.kz`

### Container responsibilities

#### SwiftUI App

- starts trip creation
- displays chat, dashboard, and edit flows
- renders app-ready aggregate responses from backend
- owns notification mocks only

#### Go Backend API

- stores trip and chat state
- exposes REST endpoints under `/api/v1`
- calls `AI_Agent`
- enriches plans using mock provider datasets
- calculates budget, cashback, bonus, and `halyk_offer`
- returns `TripDetailsResponse`

#### Python AI_Agent

- runs conversational intake
- normalizes user intent into structured fields
- returns structured itinerary plan JSON
- generates vibe labels, summaries, and reasoning blocks
- does not persist state

#### PostgreSQL

- current infrastructure baseline
- future system of record for persistent trip and chat data

## ERD

### Main entities

- `users`
- `trips`
- `trip_travelers`
- `trip_chat_sessions`
- `trip_chat_messages`
- `trip_transport_options`
- `trip_hotel_options`
- `trip_activity_items`
- `trip_todo_items`
- `trip_budget_snapshots`
- `trip_visa_info`
- `trip_offer_summaries`
- `trip_review_summaries`

## Backend REST API

All endpoints live under `/api/v1`.

- `POST /trips`
- `GET /trips/{tripId}`
- `PATCH /trips/{tripId}`
- `POST /trips/{tripId}/chat/messages`
- `GET /trips/{tripId}/chat/messages`
- `POST /trips/{tripId}/confirm`
- `POST /trips/{tripId}/regenerate`
- `GET /trips/{tripId}/options/transport`
- `POST /trips/{tripId}/options/transport/{optionId}/select`
- `GET /trips/{tripId}/options/hotels`
- `POST /trips/{tripId}/options/hotels/{optionId}/select`
- `POST /trips/{tripId}/activities`
- `GET /trips/{tripId}/budget`
- `GET /trips/{tripId}/visa`
- `GET /trips/{tripId}/reviews`

## AI_Agent Chat Spec

- one universal system prompt
- tool-calling style behavior
- structured JSON output as the primary response
- no long-form free text as the contract between backend and AI

Accepted mock geography:

- Kazakhstan
- Turkey
- UAE
- Japan
