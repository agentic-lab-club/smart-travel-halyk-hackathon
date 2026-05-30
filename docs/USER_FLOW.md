# User Flow

## Primary Flow

```text
Create Trip
-> AI Chat Intake
-> Confirm Trip Fields
-> Generate Master-Plan
-> Trip Dashboard
-> Manual Edit Actions
```

## Step-by-Step Flow

### 1. Notifications

- mock promotional entry points
- examples:
  - family international trip suggestion
  - event-driven solo trip suggestion

### 2. Create Trip

- user starts a new trip draft
- trip exists before the final plan is generated

### 3. AI Chat Intake

The AI collects:

- origin
- destination
- dates
- traveler composition
- budget
- transport type
- trip purpose
- citizenship
- hotel preferences
- event interest
- insurance need

### 4. Confirm Trip Fields

- user validates normalized fields
- system prevents silent planning from incomplete assumptions

### 5. Generate Master-Plan

Backend requests structured plan data from AI_Agent and then enriches it with mock travel data.

### 6. Trip Dashboard

Main dashboard is `todo-first`.

Sections:

- transport
- hotel
- places and events
- budget and offers
- visa and reviews
- AI copilot

### 7. Manual Edit Actions

Implemented MVP actions:

- replace hotel
- replace transport
- add place or event manually

## Primary Demo Path

### Family trip

1. Create trip
2. AI intake
3. Confirm fields
4. See generated dashboard
5. Replace hotel
6. Replace transport
7. Add activity

## Secondary Demo Path

### Solo event trip

1. Create trip
2. Ask for event-friendly city trip
3. Receive event block with source link
4. See budget and travel sections together
