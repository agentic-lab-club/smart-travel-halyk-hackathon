# API Response Models

These models are written in TypeScript-style. They can be converted to Swift Codable structs, Kotlin data classes or Dart models.

## Base enums

```ts
type CurrencyCode = "KZT" | "USD" | "EUR" | "TRY" | "GEL" | "AED" | "KRW" | "JOD";
type Confidence = "low" | "medium" | "high";
type TripMode = "economy" | "balanced" | "comfort";
type TransportType = "flight" | "taxi" | "public_transport" | "car" | "walk" | "train" | "bus" | "shuttle" | "rental_car";
type RecommendationType = "similar_to_previous" | "opposite_to_previous" | "seasonal" | "event_based" | "budget_friendly" | "cashback_boosted" | "visa_free" | "weekend_trip";
type VisaStatus = "visa_free" | "visa_on_arrival" | "e_visa" | "visa_required" | "unknown";
type SegmentStatus = "planned" | "recommended" | "optional" | "selected" | "expired" | "unavailable" | "warning";
type SegmentType = "arrival" | "transfer" | "check_in" | "hotel_stay" | "day_itinerary" | "activity" | "restaurant" | "event" | "intercity_movement" | "car_rental" | "free_time" | "checkout" | "departure" | "warning" | "cashback_challenge";
type MarkerType = "airport" | "hotel" | "attraction" | "event" | "restaurant" | "station" | "car_rental" | "transfer_point" | "city_stop" | "custom";
```

## Shared

```ts
interface Money {
  amount: number;
  currency: CurrencyCode;
}

interface EstimatedMoney extends Money {
  confidence: Confidence;
}

interface Coordinates {
  lat: number;
  lng: number;
}
```

## User profile

```ts
interface UserProfileResponse {
  userId: string;
  citizenship: string;
  homeCity: string;
  homeAirport: string;
  currency: CurrencyCode;
  preferredLanguage: "ru" | "kk" | "en";
  travelProfile: TravelProfile;
}

interface TravelProfile {
  budgetLevel: TripMode;
  travelFrequency: "low" | "medium" | "high";
  preferredTripLengthDays: number;
  preferredCategories: string[];
  avoidCategories: string[];
  hotelPreference: "cheapest" | "balanced_location_price" | "central" | "comfort";
  transportPreference: "public_transport" | "mixed" | "taxi" | "rental_car";
}
```

## Recommendations

```ts
interface RecommendationsResponse {
  userId: string;
  generatedAt: string;
  selectedMode: TripMode;
  recommendations: TripRecommendation[];
}

interface TripRecommendation {
  tripId: string;
  destinationTitle: string;
  countryCode: string;
  cityCodes: string[];
  startDate?: string;
  endDate?: string;
  durationDays: number;
  imageUrl?: string;
  estimatedTotalCost: EstimatedMoney;
  cashbackEstimate?: CashbackEstimate;
  mainReason: string;
  reasonLabels: string[];
  recommendationType: RecommendationType;
  score: number;
}

interface CashbackEstimate extends Money {
  percent: number;
}
```

## Full trip response

```ts
interface TripDetailsResponse {
  tripId: string;
  title: string;
  subtitle: string;
  startDate: string;
  endDate: string;
  durationDays: number;
  peopleCount: number;
  currency: CurrencyCode;
  selectedMode: TripMode;
  availableModes: TripMode[];
  summary: TripSummary;
  routeNavigator: RouteStop[];
  map: TripMap;
  segments: ItinerarySegment[];
  budget: BudgetBreakdown;
  modeVariants: Record<TripMode, ModeVariant>;
  visa?: VisaInfo;
  cashback?: CashbackInfo;
  challenges: TravelChallenge[];
  warnings: SmartWarning[];
}
```

## Summary and route navigator

```ts
interface TripSummary {
  estimatedTotalCost: Money;
  estimatedTotalCashback?: Money;
  weatherSummary?: string;
  visaStatus?: VisaStatus;
  mainLabels: string[];
}

interface RouteStop {
  stopId: string;
  title: string;
  startDate: string;
  endDate: string;
  transportToNext?: TransportType;
  coordinates?: Coordinates;
}
```

## Map models

```ts
interface TripMap {
  initialCamera: MapCamera;
  markers: MapMarker[];
  routes: MapRoute[];
}

interface MapCamera {
  centerLat: number;
  centerLng: number;
  zoom: number;
}

interface MapMarker {
  markerId: string;
  segmentId?: string;
  type: MarkerType;
  title: string;
  subtitle?: string;
  lat: number;
  lng: number;
  icon?: string;
  price?: MoneyWithUnit;
  labels?: string[];
}

interface MoneyWithUnit extends Money {
  unit?: "person" | "night" | "ride" | "day" | "total";
}

interface MapRoute {
  routeId: string;
  fromMarkerId: string;
  toMarkerId: string;
  segmentId?: string;
  transportType: TransportType;
  distanceKm: number;
  durationMinutes: number;
  estimatedCost?: Money;
  polyline?: string;
  alternativeRoutes?: AlternativeRoute[];
}

interface AlternativeRoute {
  transportType: TransportType;
  durationMinutes: number;
  estimatedCost?: Money;
  reason: string;
}
```

## Itinerary segment

```ts
interface ItinerarySegment {
  segmentId: string;
  type: SegmentType;
  title: string;
  date: string;
  dayNumber: number;
  startTime?: string;
  endTime?: string;
  icon: string;
  status: SegmentStatus;
  linkedMarkerIds: string[];
  linkedRouteIds: string[];
  price?: Money | null;
  labels: string[];
  description?: string;
  details: SegmentDetails;
}

type SegmentDetails =
  | ArrivalDetails
  | DepartureDetails
  | TransferDetails
  | HotelDetails
  | DayItineraryDetails
  | ActivityDetails
  | IntercityMovementDetails
  | CarRentalDetails
  | WarningDetails
  | CashbackChallengeDetails
  | Record<string, unknown>;
```

## Segment details

```ts
interface ArrivalDetails {
  flight: FlightInfo;
}

interface DepartureDetails {
  flight: FlightInfo;
  checkoutTime?: string;
  recommendedLeaveHotelTime?: string;
}

interface FlightInfo {
  fromAirport: string;
  toAirport: string;
  airline?: string;
  flightNumber?: string;
  departureTime: string;
  arrivalTime: string;
  durationMinutes: number;
  stops: number;
  cabinClass: "economy" | "business" | "first";
  price?: Money;
}

interface TransferDetails {
  from: string;
  to: string;
  recommendedTransport: TransportType;
  distanceKm: number;
  durationMinutes: number;
  taxiEstimate?: Money;
  publicTransportEstimate?: Money & { durationMinutes: number };
  reason: string;
}

interface HotelDetails {
  hotelId: string;
  name: string;
  district?: string;
  stars?: number;
  rating?: number;
  ratingLabel?: string;
  reviewShortSummary?: string;
  selectedRoomId?: string;
  selectedRoomName?: string;
  pricePerNight: Money;
  nights: number;
  downgradeLabel?: string;
  upgradeLabel?: string;
  distanceToMainClusterKm?: number;
  averageTaxiToActivities?: Money;
  locationScore?: number;
  priceScore?: number;
  reason: string;
}

interface DayItineraryDetails {
  city: string;
  experienceCount: number;
  weather?: WeatherInfo;
  pace: "slow" | "medium" | "fast";
  overloadScore: number;
  activities: ActivityItem[];
}

interface WeatherInfo {
  temperatureC: number;
  condition: "sunny" | "cloudy" | "rain" | "snow" | "windy" | "unknown";
  rainChancePercent?: number;
  windKph?: number;
}

interface ActivityItem {
  activityId: string;
  title: string;
  type: "attraction" | "event" | "restaurant" | "shopping" | "free_time";
  startTime?: string;
  durationMinutes: number;
  price?: Money;
  markerId?: string;
  reason?: string;
}

interface IntercityMovementDetails {
  fromCity: string;
  toCity: string;
  transportType: TransportType;
  distanceKm: number;
  durationMinutes: number;
  estimatedCost?: Money;
  reason: string;
}

interface CarRentalDetails {
  provider?: string;
  carName: string;
  carClass?: string;
  transmission?: "manual" | "automatic";
  seats?: number;
  pricePerDay: Money;
  days: number;
  pickupLocation: string;
  dropoffLocation?: string;
  reason?: string;
}

interface WarningDetails {
  message: string;
}

interface CashbackChallengeDetails {
  challengeId: string;
}
```

## Hotel full model

```ts
interface HotelDetailsFull {
  hotelId: string;
  name: string;
  city: string;
  district?: string;
  address?: string;
  lat: number;
  lng: number;
  stars?: number;
  mainImageUrl?: string;
  rating: HotelRating;
  sourceRatings: HotelSourceRating[];
  reviewSummary: HotelReviewSummary;
  reviewsBySource: HotelReviewsSourceGroup[];
  rooms: HotelRoom[];
  selectedRoomId: string;
  roomOptions: HotelRoomOptions;
  locationInfo: HotelLocationInfo;
  reason: string;
}

interface HotelRating {
  overall: number;
  scale: number;
  label?: string;
  reviewCount: number;
}

interface HotelSourceRating {
  source: "Booking.com" | "Google Hotels" | "Tripadvisor" | "Expedia" | "Agoda" | "Other";
  rating: number;
  scale: number;
  reviewCount: number;
  url?: string;
}

interface HotelReviewsSourceGroup {
  source: "Booking.com" | "Google Hotels" | "Tripadvisor" | "Expedia" | "Agoda" | "Other";
  totalReviews: number;
  averageRating: number;
  scale: number;
  reviews: HotelReview[];
}

interface HotelReview {
  reviewId: string;
  authorName?: string;
  rating: number;
  scale: number;
  date?: string;
  language?: string;
  title?: string;
  text: string;
  pros?: string[];
  cons?: string[];
}

interface HotelReviewSummary {
  shortSummary: string;
  positivePoints: string[];
  negativePoints: string[];
  bestFor: string[];
  notIdealFor: string[];
  confidence: Confidence;
  basedOnSources: string[];
}

interface HotelRoom {
  roomId: string;
  name: string;
  description?: string;
  imageUrl?: string;
  capacity: number;
  bedType?: "single" | "double" | "queen" | "king" | "twin" | "multiple";
  areaSqm?: number;
  refundable?: boolean;
  breakfastIncluded?: boolean;
  pricePerNight: Money;
  totalPrice: Money;
  labels: string[];
  tradeoffLabel?: string;
}

interface HotelRoomOptions {
  selectedRoomId: string;
  downgradeRoomId?: string;
  upgradeRoomId?: string;
  selectedReason: string;
  downgradeLabel?: string;
  upgradeLabel?: string;
}

interface HotelLocationInfo {
  distanceToAirportKm?: number;
  taxiFromAirport?: Money;
  distanceToMainClusterKm?: number;
  averageTaxiToActivities?: Money;
  walkablePlacesCount?: number;
  locationScore?: number;
  priceScore?: number;
  convenienceScore?: number;
}
```

## Budget

```ts
interface BudgetBreakdown {
  total: EstimatedMoney;
  items: BudgetItem[];
}

type BudgetCategory =
  | "flights"
  | "hotels"
  | "local_transport"
  | "intercity_transport"
  | "food"
  | "activities"
  | "events"
  | "visa"
  | "insurance"
  | "souvenirs"
  | "buffer"
  | "cashback_discount";

interface BudgetItem extends Money {
  category: BudgetCategory;
  title: string;
}
```

## Mode variants

```ts
interface ModeVariant {
  totalCost: number;
  hotelStrategy: "farther_but_cheaper" | "balanced_location_price" | "closer_to_activities";
  transportStrategy: "public_transport_first" | "mixed" | "taxi_and_direct_routes";
  estimatedTravelTimeMinutes: number;
  savingsComparedToBalanced?: number;
  extraCostComparedToBalanced?: number;
  tradeoffLabel: string;
}
```

## Visa, cashback, challenges and warnings

```ts
interface VisaInfo {
  citizenship: string;
  destinationCountry: string;
  status: VisaStatus;
  required: boolean;
  estimatedCost?: Money;
  processingTimeDays?: number;
  notes?: string;
  confidence: Confidence;
}

interface CashbackInfo {
  estimatedTotal: Money;
  basePercent: number;
  boostedPercent?: number;
  items: CashbackItem[];
}

interface CashbackItem {
  category: "hotel" | "flight" | "transport" | "activity" | "insurance" | "other";
  amount: number;
  currency: CurrencyCode;
  condition: string;
}

interface TravelChallenge {
  challengeId: string;
  title: string;
  description: string;
  reward: ChallengeReward;
  progress: ChallengeProgress;
  deadline?: string;
  difficulty: "easy" | "medium" | "hard";
  reason: string;
}

interface ChallengeReward {
  type: "cashback_boost" | "fixed_cashback" | "discount" | "level_points";
  valuePercent?: number;
  amount?: Money;
}

interface ChallengeProgress {
  current: number;
  target: number;
  unit: "KZT" | "points" | "payments";
}

interface SmartWarning {
  type: WarningType;
  severity: "low" | "medium" | "high";
  segmentId?: string;
  message: string;
}

type WarningType =
  | "route_overloaded"
  | "airport_far_from_hotel"
  | "expensive_transfer"
  | "visa_uncertain"
  | "weather_risk"
  | "hotel_far_from_activities"
  | "low_confidence_price"
  | "not_enough_time_between_segments";
```
