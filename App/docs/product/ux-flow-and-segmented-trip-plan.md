# UX Flow and Segmented Trip Plan

## Main user flow

### 1. Entry

User opens Halyk Travel and sees 6–10 ready destination cards.

Each card shows:
- city/country;
- dates or best period;
- approximate budget;
- cashback;
- short reason:
  - cheap and visa-free;
  - similar to your previous beach trips;
  - seasonal event period;
  - direct flight.

### 2. Lightweight preference input

Instead of a long survey:
- people count;
- approximate dates;
- 1–2 preference chips:
  - beach;
  - mountains;
  - culture;
  - nightlife;
  - quiet;
  - shopping;
- budget style:
  - economy;
  - balanced;
  - comfort.

### 3. Selected trip page

User opens a trip and sees:
- total cost;
- cost breakdown;
- weather;
- map;
- districts;
- events;
- places;
- hotel and room options;
- transport options;
- cashback and travel challenge.

## Segmented Trip Plan UI

The plan is a vertical timeline where every step of the trip is a segment.

The user sees the trip as a ready scenario:

`arrival → transfer → check-in → walk/activity → event → intercity movement → departure`

## UI pattern

### Timeline / itinerary list

- vertical line on the left;
- segment icon:
  - flight;
  - hotel;
  - car;
  - transfer;
  - food;
  - attraction;
  - event;
  - depart;
- date and day number;
- segment card on the right;
- card content:
  - title;
  - time;
  - cost;
  - weather badge;
  - smart labels.

### Map layer

- map shows all trip points;
- selected segment highlights a marker or route;
- routes between cities or objects are shown as lines;
- full map can be opened.

## Segment types

### Arrival

Shows:
- arrival airport/station;
- flight;
- arrival time;
- baggage/layover if available;
- next step: transfer to hotel.

### Transfer

Shows:
- airport to hotel;
- distance;
- duration;
- taxi cost;
- public transport alternative;
- warning if transfer is expensive or long.

### Check-in / Hotel

Shows:
- hotel;
- district;
- rating;
- selected room;
- price per night;
- distance to main objects;
- summarized reviews;
- upgrade/downgrade options;
- reason why this hotel/room was selected.

### Day itinerary

Shows:
- trip day;
- experiences count;
- weather;
- places and events;
- overload score.

### Intercity movement

Shows:
- city A to city B;
- transport:
  - car;
  - train;
  - bus;
  - flight;
- duration;
- approximate cost;
- reason for this transport.

### Departure

Shows:
- checkout;
- hotel to airport transfer;
- flight home;
- final cost;
- reminders:
  - documents;
  - baggage;
  - when to leave.

## Top horizontal route navigator

For multi-city trips:

`Amman → Wadi Rum → Petra → Dead Sea → Amman → Berlin`

Each stop is a pill/card.
Between stops, show the transport icon.
Tap on a stop scrolls to the relevant day and focuses the map.

## Interaction model

- Tap timeline segment → map focuses on the location/route.
- Tap map marker → timeline scrolls to the segment.
- Change trip mode → hotel, room, transfer, route and total cost update together.
- Expand segment → details, alternatives and reasons.
