# Mock Data Requirements

For the hackathon, do not collect the whole world. Prepare 3–5 high-quality destinations.

## Minimum destinations

- Istanbul
- Tbilisi
- Dubai
- Seoul
- Jordan route: Amman → Wadi Rum → Petra → Dead Sea → Amman

## For each destination

Prepare:
- 1 airport;
- 3–5 hotels:
  - cheap/far;
  - balanced;
  - comfort/central;
- 3 rooms per hotel:
  - economy;
  - balanced;
  - comfort;
- 2–3 rating sources per hotel;
- 3–5 reviews per source;
- summarized hotel review;
- 8–12 attractions/events/restaurants;
- 2–3 day itinerary variants;
- taxi/public transport estimates from airport to hotels;
- weather mock per day;
- visa status for KZ citizenship;
- cashback rules;
- 2–3 smart warnings.

## Internal dataset models

```ts
interface Destination {
  destinationId: string;
  title: string;
  countryCode: string;
  cities: string[];
  tags: string[];
  bestMonths: string[];
  visaByCitizenship: Record<string, VisaStatus>;
}

interface Hotel {
  hotelId: string;
  city: string;
  name: string;
  lat: number;
  lng: number;
  pricePerNight: number;
  currency: CurrencyCode;
  rating?: number;
  stars?: number;
  style: "economy" | "balanced" | "comfort";
  district?: string;
  tags: string[];
}

interface PlaceActivity {
  placeId: string;
  city: string;
  title: string;
  type: "attraction" | "event" | "restaurant" | "shopping" | "viewpoint";
  lat: number;
  lng: number;
  durationMinutes: number;
  estimatedPrice?: number;
  currency?: CurrencyCode;
  tags: string[];
  rating?: number;
}

interface RouteEstimate {
  fromId: string;
  toId: string;
  transportType: TransportType;
  distanceKm: number;
  durationMinutes: number;
  estimatedCost?: number;
  currency?: CurrencyCode;
}
```

## Data person deliverables

1. JSON mock dataset.
2. Recommendation response example.
3. Full trip response example.
4. 3 mode variants for one trip.
5. Map markers and route examples.
6. Budget breakdown.
7. Hotel review examples.
8. Room upgrade/downgrade examples.
9. Cashback/challenge examples.
10. README explaining fields and assumptions.
