# API Data Requirements

## Core API idea

Frontend should receive a ready trip object, not raw disconnected hotel/flight/place data.

The API should provide:
- recommendations for the main screen;
- selected trip with itinerary segments;
- smart map with markers and routes;
- budget;
- trip mode variants;
- hotel details, reviews and rooms;
- reasons and smart labels;
- cashback and challenges.

## Required endpoints

### GET /user-profile

Returns user profile for personalization.

Used for:
- visa constraints;
- budget;
- previous travel patterns;
- recommendation scoring.

### GET /recommendations

Returns destination cards for the main screen.

Query params:

```txt
userId
startDate optional
endDate optional
peopleCount optional
mode optional: economy | balanced | comfort
visaFilter optional: visa_free_only | any
```

### GET /trips/{tripId}

Main endpoint for selected trip.

Returns:
- timeline;
- map;
- budget;
- hotels;
- transport;
- events;
- cashback;
- warnings.

Top-level shape:

```json
{
  "tripId": "trip_jordan_001",
  "title": "Jordan Highlights",
  "subtitle": "Amman → Wadi Rum → Petra → Dead Sea → Amman",
  "startDate": "2026-05-01",
  "endDate": "2026-05-09",
  "durationDays": 9,
  "peopleCount": 2,
  "currency": "KZT",
  "selectedMode": "balanced",
  "availableModes": ["economy", "balanced", "comfort"],
  "summary": {},
  "routeNavigator": [],
  "map": {},
  "segments": [],
  "budget": {},
  "modeVariants": {},
  "visa": {},
  "cashback": {},
  "challenges": [],
  "warnings": []
}
```

## Required linked IDs

To synchronize timeline and map:
- every segment has `segmentId`;
- every marker has `markerId`;
- every route has `routeId`;
- marker/route can reference `segmentId`;
- segment can contain `linkedMarkerIds` and `linkedRouteIds`.

## Recommendation object

```json
{
  "tripId": "trip_istanbul_001",
  "destinationTitle": "Istanbul Weekend",
  "countryCode": "TR",
  "cityCodes": ["IST"],
  "startDate": "2026-06-12",
  "endDate": "2026-06-16",
  "durationDays": 4,
  "imageUrl": "https://example.com/image.jpg",
  "estimatedTotalCost": {
    "amount": 285000,
    "currency": "KZT",
    "confidence": "medium"
  },
  "cashbackEstimate": {
    "amount": 18000,
    "currency": "KZT",
    "percent": 7
  },
  "mainReason": "Похоже на ваши прошлые культурные поездки",
  "reasonLabels": ["Без визы", "Прямой рейс", "Сезон событий"],
  "recommendationType": "similar_to_previous",
  "score": 0.87
}
```

## Map marker

```json
{
  "markerId": "marker_hotel_001",
  "segmentId": "seg_hotel_001",
  "type": "hotel",
  "title": "Four Seasons Hotel Amman",
  "subtitle": "Selected hotel · Balanced mode",
  "lat": 31.9454,
  "lng": 35.8802,
  "icon": "hotel",
  "price": {
    "amount": 62000,
    "currency": "KZT",
    "unit": "night"
  },
  "labels": ["Ближе к маршруту", "Высокий рейтинг"]
}
```

## Map route

```json
{
  "routeId": "route_airport_hotel",
  "fromMarkerId": "marker_airport_amm",
  "toMarkerId": "marker_hotel_001",
  "segmentId": "seg_transfer_001",
  "transportType": "taxi",
  "distanceKm": 36.4,
  "durationMinutes": 45,
  "estimatedCost": {
    "amount": 9000,
    "currency": "KZT"
  },
  "polyline": "optional_encoded_polyline",
  "alternativeRoutes": [
    {
      "transportType": "public_transport",
      "durationMinutes": 70,
      "estimatedCost": {
        "amount": 900,
        "currency": "KZT"
      },
      "reason": "Дешевле, но дольше"
    }
  ]
}
```

## Itinerary segment

```json
{
  "segmentId": "seg_arrival_001",
  "type": "arrival",
  "title": "Arrival in Amman",
  "date": "2026-05-01",
  "dayNumber": 1,
  "startTime": "14:20",
  "endTime": "15:00",
  "icon": "flight",
  "status": "planned",
  "linkedMarkerIds": ["marker_airport_amm"],
  "linkedRouteIds": [],
  "price": null,
  "labels": ["1 stop", "Economy class"],
  "description": "Flight arrival at Queen Alia International Airport.",
  "details": {}
}
```

## Mode variants

```json
{
  "modeVariants": {
    "economy": {
      "totalCost": 760000,
      "hotelStrategy": "farther_but_cheaper",
      "transportStrategy": "public_transport_first",
      "estimatedTravelTimeMinutes": 920,
      "savingsComparedToBalanced": 160000,
      "tradeoffLabel": "Дешевле, но больше времени в дороге"
    },
    "balanced": {
      "totalCost": 920000,
      "hotelStrategy": "balanced_location_price",
      "transportStrategy": "mixed",
      "estimatedTravelTimeMinutes": 720,
      "tradeoffLabel": "Баланс цены и удобства"
    },
    "comfort": {
      "totalCost": 1180000,
      "hotelStrategy": "closer_to_activities",
      "transportStrategy": "taxi_and_direct_routes",
      "estimatedTravelTimeMinutes": 540,
      "extraCostComparedToBalanced": 260000,
      "tradeoffLabel": "Дороже, но меньше дороги и пересадок"
    }
  }
}
```

## Hotel requirements

For every hotel API should provide:
- base hotel info;
- map coordinates;
- overall rating;
- ratings by source;
- reviews grouped by source;
- summarized review;
- available rooms;
- selected room;
- upgrade/downgrade options;
- location info;
- reason why this hotel and room were selected.

See:
- `docs/data/hotel-reviews-room-selection.md`
- `docs/api/api-response-models.md`

## Important implementation notes

- All prices must include `currency`.
- All map points must include `lat` and `lng`.
- All timeline segments must include `segmentId`.
- All map markers/routes should reference `segmentId` when related.
- All smart labels should be short.
- Approximate prices should include `confidence`.
- Mock data is acceptable for hackathon, but the structure should look production-ready.
