# Smart Travel Companion PRD

## Product Summary

`Smart Travel Companion` is a travel planning product inside the Halyk ecosystem. It turns `Halyk Travel` from a ticket purchase surface into a trip control center.

The MVP is not a full OTA and not a full Booking.com competitor. It is a trip planner that combines:

- AI-assisted trip creation
- transport and hotel selection
- route and event planning
- trip budget visibility
- Halyk-style mock cashback and bonus logic
- trip checklist and trip dashboard

The core idea is:

> everything in one place: smart trip planner + financial travel assistant

## Problem

Today a user plans a trip across too many disconnected tools:

- airline or rail search
- hotel aggregators
- maps
- weather tools
- visa information pages
- reviews
- event platforms
- budgeting tools

This creates:

- decision fatigue
- fragmented planning
- poor budget visibility
- weak family coordination
- extra effort for finding relevant events and places

## Product Vision

Halyk should become the place where the user manages the trip, not just buys one part of it.

The prototype vision is:

- one trip = one master-plan
- AI is the primary entry point for planning
- the plan becomes editable and actionable
- the user sees costs, suggestions, visa info, reviews, and event links in one dashboard

## Target Users

### Primary

- family with children planning an international trip

### Secondary

- solo traveler who wants events and places, including `Kino.kz`-style event discovery
- users exploring domestic tourism inside Kazakhstan

## User Scenarios

### Family international trip

A family creates a trip, uses AI chat to define destination, dates, children count, interests, and budget, then confirms the result and receives a full dashboard with transport, hotel, activities, visa hints, reviews, and budget.

### Solo event-driven trip

A solo traveler creates a trip around city exploration and events, receives suggested transport, hotel, attractions, and an event block with a source link.

### Domestic tourism

A user plans a local trip in Kazakhstan with a lighter visa flow and stronger emphasis on route, local attractions, and value.

## Value Proposition

The product should help the user:

- plan the trip in one place
- reduce planning friction
- get structured suggestions instead of hundreds of options
- understand total trip cost
- see mock Halyk cashback, bonus, and travel offer value
- edit the plan without starting over

## Key Differentiation

The main differentiation is not raw AI chat.

The differentiation is:

- trip planning + budget visibility + offer visibility in one flow
- a control-center model instead of a search-only model
- a todo-first dashboard with travel components already assembled

For the prototype, Halyk ecosystem logic is shown through:

- UI positioning
- mock fields in API
- cashback, bonus, and `halyk_offer`

There is no real Halyk integration in the MVP.

## MVP Scope

### In scope

- create trip
- AI chat intake
- trip field confirmation
- trip dashboard
- transport options
- hotel options
- places and events
- weather and seasonality hints
- visa assistant mock
- AI review summary with source links
- budget summary
- cashback / bonus / offer mock values
- manual edits:
  - replace hotel
  - replace transport
  - add place or event manually

### Out of scope

- live booking
- real payment
- shared family wallet
- split payment
- post-trip analytics
- real event integration
- installment logic
- real partner APIs

## Product Flow

Main flow:

1. User opens app
2. User enters `Create Trip`
3. User starts AI chat intake
4. AI collects required fields
5. User confirms trip fields
6. Backend generates trip master-plan
7. User lands on trip dashboard
8. User can replace hotel, replace transport, or add place/event manually

## Required Input Fields

The MVP AI intake must be able to collect:

- origin city
- destination country and city
- travel dates
- adults count
- children count
- child age groups
- budget
- transport type
- interests
- trip purpose / vibe
- citizenship / passport country
- hotel preferences
- event interest
- insurance needed

## Main Pages

### Notifications

- mock only
- used to show campaign / trip suggestion examples

### Create Trip

- starting point for trip creation
- CTA to launch AI planning

### AI Chat Intake

- primary planning interface
- asks structured questions
- derives vibe labels
- proposes travel direction

### Confirm Trip Fields

- user verifies normalized fields before generation

### Trip Dashboard

- todo-first structure
- main sections:
  - transport
  - hotel
  - places and events
  - budget and offers
  - visa and reviews
  - AI copilot

### Selection / Edit Surfaces

- transport replacement
- hotel replacement
- manual place / event add

## UX Principles

- AI is the primary entry point into planning
- the user must still explicitly confirm the plan inputs
- the dashboard should be easier to scan than a long itinerary chat
- the product should feel like a trip control center, not just a prompt box

## Business Value

For hackathon framing, the product creates value through:

- higher attach potential beyond ticket purchase
- more travel-related transactions inside one journey
- stronger story for Halyk ecosystem expansion
- better superapp positioning for travel planning

## Success Criteria for MVP Demo

The prototype is successful if it can clearly show:

- chat-first trip planning
- a generated trip dashboard
- transport, hotel, route, event, visa, review, and budget blocks
- Halyk-style mock cashback and offer logic
- manual plan editing without collapsing the trip flow

## Demo Scenarios

### Primary demo

- family builds an international trip

### Secondary demo

- solo traveler builds an event-oriented trip with `Kino.kz`-style event block

## Risks

- AI-only output without structure becomes unstable for frontend rendering
- too many scope items can dilute demo quality
- real provider integration would slow the prototype significantly

## Product Assumptions

- backend returns already assembled trip data, not raw disconnected inventory
- AI output is structured JSON, not free-form text only
- external services remain mocked
- Halyk financial logic is represented as mock fields and mock rules
