package trip

// MobileTripBundle is the consumer-facing read model that matches the mobile app's TripDetailsResponse contract.
// All JSON keys use camelCase to align with the Swift Codable decoder (no key-strategy conversion needed).
type MobileTripBundle struct {
	TripID         string                       `json:"tripId"`
	Title          string                       `json:"title"`
	Subtitle       string                       `json:"subtitle"`
	StartDate      string                       `json:"startDate"`
	EndDate        string                       `json:"endDate"`
	DurationDays   int                          `json:"durationDays"`
	PeopleCount    int                          `json:"peopleCount"`
	Currency       string                       `json:"currency"`
	SelectedMode   string                       `json:"selectedMode"`
	AvailableModes []string                     `json:"availableModes"`
	Summary        MobileSummary                `json:"summary"`
	RouteNavigator []MobileRouteStop            `json:"routeNavigator"`
	Map            MobileTripMap                `json:"map"`
	Segments       []MobileSegment              `json:"segments"`
	Budget         MobileBudgetBreakdown        `json:"budget"`
	ModeVariants   map[string]MobileModeVariant `json:"modeVariants"`
	Visa           *MobileVisa                  `json:"visa"`
	Cashback       *MobileCashback              `json:"cashback"`
	Challenges     []interface{}                `json:"challenges"`
	Warnings       []MobileWarning              `json:"warnings"`
}

type MobileSummary struct {
	EstimatedTotalCost     MobileMoney  `json:"estimatedTotalCost"`
	EstimatedTotalCashback *MobileMoney `json:"estimatedTotalCashback"`
	WeatherSummary         string       `json:"weatherSummary"`
	VisaStatus             string       `json:"visaStatus"`
	MainLabels             []string     `json:"mainLabels"`
}

type MobileMoney struct {
	Amount   float64 `json:"amount"`
	Currency string  `json:"currency"`
}

type MobileEstimatedMoney struct {
	Amount     float64 `json:"amount"`
	Currency   string  `json:"currency"`
	Confidence string  `json:"confidence"`
}

type MobileRouteStop struct {
	StopID          string        `json:"stopId"`
	Title           string        `json:"title"`
	StartDate       string        `json:"startDate"`
	EndDate         string        `json:"endDate"`
	TransportToNext *string       `json:"transportToNext"`
	Coordinates     *MobileCoords `json:"coordinates"`
}

type MobileCoords struct {
	Lat float64 `json:"lat"`
	Lng float64 `json:"lng"`
}

type MobileTripMap struct {
	InitialCamera MobileMapCamera `json:"initialCamera"`
	Markers       []MobileMarker  `json:"markers"`
	Routes        []MobileRoute   `json:"routes"`
}

type MobileMapCamera struct {
	CenterLat float64 `json:"centerLat"`
	CenterLng float64 `json:"centerLng"`
	Zoom      float64 `json:"zoom"`
}

type MobileMarker struct {
	MarkerID  string  `json:"markerId"`
	SegmentID *string `json:"segmentId"`
	Type      string  `json:"type"`
	Title     string  `json:"title"`
	Lat       float64 `json:"lat"`
	Lng       float64 `json:"lng"`
}

type MobileRoute struct {
	RouteID           string           `json:"routeId"`
	FromMarkerID      string           `json:"fromMarkerId"`
	ToMarkerID        string           `json:"toMarkerId"`
	SegmentID         *string          `json:"segmentId"`
	TransportType     string           `json:"transportType"`
	DistanceKm        float64          `json:"distanceKm"`
	DurationMinutes   int              `json:"durationMinutes"`
	EstimatedCost     *MobileMoney     `json:"estimatedCost"`
	AlternativeRoutes []MobileAltRoute `json:"alternativeRoutes"`
}

type MobileAltRoute struct {
	TransportType   string       `json:"transportType"`
	DurationMinutes int          `json:"durationMinutes"`
	EstimatedCost   *MobileMoney `json:"estimatedCost"`
	Reason          string       `json:"reason"`
}

type MobileSegment struct {
	SegmentID       string               `json:"segmentId"`
	Type            string               `json:"type"`
	Title           string               `json:"title"`
	Date            string               `json:"date"`
	DayNumber       int                  `json:"dayNumber"`
	StartTime       *string              `json:"startTime"`
	EndTime         *string              `json:"endTime"`
	Icon            string               `json:"icon"`
	Status          string               `json:"status"`
	LinkedMarkerIDs []string             `json:"linkedMarkerIds"`
	LinkedRouteIDs  []string             `json:"linkedRouteIds"`
	Price           *MobileMoney         `json:"price"`
	Labels          []string             `json:"labels"`
	Description     *string              `json:"description"`
	Details         MobileSegmentDetails `json:"details"`
}

// MobileSegmentDetails uses the kind/payload envelope required by the mobile SegmentDetails decoder.
type MobileSegmentDetails struct {
	Kind    string      `json:"kind"`
	Payload interface{} `json:"payload"`
}

// Segment payload types — field names must exactly match the corresponding Swift Codable structs.

type MobileFlightInfo struct {
	FromAirport     string       `json:"fromAirport"`
	ToAirport       string       `json:"toAirport"`
	Airline         *string      `json:"airline"`
	FlightNumber    *string      `json:"flightNumber"`
	DepartureTime   string       `json:"departureTime"`
	ArrivalTime     string       `json:"arrivalTime"`
	DurationMinutes int          `json:"durationMinutes"`
	Stops           int          `json:"stops"`
	CabinClass      string       `json:"cabinClass"`
	Price           *MobileMoney `json:"price"`
}

type MobileArrivalPayload struct {
	Flight MobileFlightInfo `json:"flight"`
}

type MobileDeparturePayload struct {
	Flight                    MobileFlightInfo `json:"flight"`
	CheckoutTime              *string          `json:"checkoutTime"`
	RecommendedLeaveHotelTime *string          `json:"recommendedLeaveHotelTime"`
}

type MobileTransferPayload struct {
	From                    string                         `json:"from"`
	To                      string                         `json:"to"`
	RecommendedTransport    string                         `json:"recommendedTransport"`
	DistanceKm              float64                        `json:"distanceKm"`
	DurationMinutes         int                            `json:"durationMinutes"`
	TaxiEstimate            *MobileMoney                   `json:"taxiEstimate"`
	PublicTransportEstimate *MobilePublicTransportEstimate `json:"publicTransportEstimate"`
	Reason                  string                         `json:"reason"`
}

type MobilePublicTransportEstimate struct {
	Amount          float64 `json:"amount"`
	Currency        string  `json:"currency"`
	DurationMinutes int     `json:"durationMinutes"`
}

type MobileHotelPayload struct {
	HotelID                 string       `json:"hotelId"`
	Name                    string       `json:"name"`
	District                *string      `json:"district"`
	Stars                   *int         `json:"stars"`
	Rating                  *float64     `json:"rating"`
	RatingLabel             *string      `json:"ratingLabel"`
	ReviewShortSummary      *string      `json:"reviewShortSummary"`
	SelectedRoomID          *string      `json:"selectedRoomId"`
	SelectedRoomName        *string      `json:"selectedRoomName"`
	PricePerNight           MobileMoney  `json:"pricePerNight"`
	Nights                  int          `json:"nights"`
	DowngradeLabel          *string      `json:"downgradeLabel"`
	UpgradeLabel            *string      `json:"upgradeLabel"`
	DistanceToMainClusterKm *float64     `json:"distanceToMainClusterKm"`
	AverageTaxiToActivities *MobileMoney `json:"averageTaxiToActivities"`
	LocationScore           *float64     `json:"locationScore"`
	PriceScore              *float64     `json:"priceScore"`
	Reason                  string       `json:"reason"`
}

type MobileDayItineraryPayload struct {
	City            string               `json:"city"`
	ExperienceCount int                  `json:"experienceCount"`
	Weather         *MobileWeatherInfo   `json:"weather"`
	Pace            string               `json:"pace"`
	OverloadScore   float64              `json:"overloadScore"`
	Activities      []MobileActivityItem `json:"activities"`
}

type MobileWeatherInfo struct {
	TemperatureC      int  `json:"temperatureC"`
	Condition         string `json:"condition"`
	RainChancePercent *int   `json:"rainChancePercent"`
	WindKph           *int   `json:"windKph"`
}

type MobileActivityItem struct {
	ActivityID      string       `json:"activityId"`
	Title           string       `json:"title"`
	Type            string       `json:"type"`
	StartTime       *string      `json:"startTime"`
	DurationMinutes int          `json:"durationMinutes"`
	Price           *MobileMoney `json:"price"`
	MarkerID        *string      `json:"markerId"`
	Reason          *string      `json:"reason"`
}

type MobileBudgetBreakdown struct {
	Total MobileEstimatedMoney `json:"total"`
	Items []MobileBudgetItem   `json:"items"`
}

type MobileBudgetItem struct {
	Category string  `json:"category"`
	Title    string  `json:"title"`
	Amount   float64 `json:"amount"`
	Currency string  `json:"currency"`
}

type MobileModeVariant struct {
	TotalCost                   float64  `json:"totalCost"`
	HotelStrategy               string   `json:"hotelStrategy"`
	TransportStrategy           string   `json:"transportStrategy"`
	EstimatedTravelTimeMinutes  int      `json:"estimatedTravelTimeMinutes"`
	SavingsComparedToBalanced   *float64 `json:"savingsComparedToBalanced,omitempty"`
	ExtraCostComparedToBalanced *float64 `json:"extraCostComparedToBalanced,omitempty"`
	TradeoffLabel               string   `json:"tradeoffLabel"`
}

// MobileVisa matches the Swift VisaInfo Codable contract exactly.
type MobileVisa struct {
	Citizenship        string   `json:"citizenship"`
	DestinationCountry string   `json:"destinationCountry"`
	Status             string   `json:"status"`
	Required           bool     `json:"required"`
	EstimatedCost      *MobileMoney `json:"estimatedCost"`
	ProcessingTimeDays *int     `json:"processingTimeDays"`
	Notes              *string  `json:"notes"`
	Confidence         string   `json:"confidence"`
}

type MobileCashback struct {
	EstimatedTotal MobileMoney   `json:"estimatedTotal"`
	BasePercent    float64       `json:"basePercent"`
	BoostedPercent *float64      `json:"boostedPercent"`
	Items          []interface{} `json:"items"`
}

type MobileWarning struct {
	Type      string  `json:"type"`
	Severity  string  `json:"severity"`
	SegmentID *string `json:"segmentId"`
	Message   string  `json:"message"`
}

// PlanningResponse is returned by create/patch endpoints — gives mobile the tripId and planning state.
type PlanningResponse struct {
	TripID               string   `json:"tripId"`
	Status               string   `json:"status"`
	MissingFields        []string `json:"missingFields"`
	ReadyForConfirmation bool     `json:"readyForConfirmation"`
}

// UserProfileResponse is the mobile-compatible user profile read model.
type UserProfileResponse struct {
	UserID            string              `json:"userId"`
	Name              string              `json:"name"`
	Citizenship       string              `json:"citizenship"`
	HomeCity          string              `json:"homeCity"`
	HomeAirport       string              `json:"homeAirport"`
	Currency          string              `json:"currency"`
	PreferredLanguage string              `json:"preferredLanguage"`
	TravelProfile     MobileTravelProfile `json:"travelProfile"`
}

type MobileTravelProfile struct {
	BudgetLevel             string   `json:"budgetLevel"`
	TravelFrequency         string   `json:"travelFrequency"`
	PreferredTripLengthDays int      `json:"preferredTripLengthDays"`
	PreferredCategories     []string `json:"preferredCategories"`
	AvoidCategories         []string `json:"avoidCategories"`
	HotelPreference         string   `json:"hotelPreference"`
	TransportPreference     string   `json:"transportPreference"`
}

// RecommendationsResponse is the mobile-compatible recommendations feed read model.
type RecommendationsResponse struct {
	UserID          string                     `json:"userId"`
	GeneratedAt     string                     `json:"generatedAt"`
	SelectedMode    string                     `json:"selectedMode"`
	Recommendations []MobileTripRecommendation `json:"recommendations"`
}

type MobileTripRecommendation struct {
	TripID             string                  `json:"tripId"`
	DestinationName    string                  `json:"destinationName"`
	DestinationTitle   string                  `json:"destinationTitle"`
	CountryCode        string                  `json:"countryCode"`
	CityCodes          []string                `json:"cityCodes"`
	StartDate          *string                 `json:"startDate"`
	EndDate            *string                 `json:"endDate"`
	DurationDays       int                     `json:"durationDays"`
	ImageURL           *string                 `json:"imageUrl"`
	EstimatedTotalCost MobileEstimatedMoney    `json:"estimatedTotalCost"`
	CashbackEstimate   *MobileCashbackEstimate `json:"cashbackEstimate"`
	MainReason         string                  `json:"mainReason"`
	ReasonLabels       []string                `json:"reasonLabels"`
	RecommendationType string                  `json:"recommendationType"`
	Score              float64                 `json:"score"`
}

type MobileCashbackEstimate struct {
	Amount   float64 `json:"amount"`
	Currency string  `json:"currency"`
	Percent  float64 `json:"percent"`
}

// HotelDetailsFullResponse is the mobile-compatible hotel full details read model.
// Field names must exactly match the Swift HotelDetailsFull Codable contract.
type HotelDetailsFullResponse struct {
	HotelID         string                            `json:"hotelId"`
	Name            string                            `json:"name"`
	City            string                            `json:"city"`
	District        *string                           `json:"district"`
	Address         *string                           `json:"address"`
	Lat             float64                           `json:"lat"`
	Lng             float64                           `json:"lng"`
	Stars           *int                              `json:"stars"`
	MainImageURL    *string                           `json:"mainImageUrl"`
	Rating          HotelRatingResponse               `json:"rating"`
	SourceRatings   []HotelSourceRatingResponse       `json:"sourceRatings"`
	ReviewSummary   HotelReviewSummaryResponse        `json:"reviewSummary"`
	ReviewsBySource []HotelReviewsSourceGroupResponse `json:"reviewsBySource"`
	Rooms           []HotelRoomResponse               `json:"rooms"`
	SelectedRoomID  string                            `json:"selectedRoomId"`
	RoomOptions     HotelRoomOptionsResponse          `json:"roomOptions"`
	LocationInfo    HotelLocationInfoResponse         `json:"locationInfo"`
	Reason          string                            `json:"reason"`
}

type HotelRatingResponse struct {
	Overall     float64 `json:"overall"`
	Scale       float64 `json:"scale"`
	Label       *string `json:"label"`
	ReviewCount int     `json:"reviewCount"`
}

// HotelSourceRatingResponse source must match HotelReviewSource raw values:
// "Booking.com", "Google Hotels", "Tripadvisor", "Expedia", "Agoda", "Other"
type HotelSourceRatingResponse struct {
	Source      string  `json:"source"`
	Rating      float64 `json:"rating"`
	Scale       float64 `json:"scale"`
	ReviewCount int     `json:"reviewCount"`
	URL         *string `json:"url"`
}

type HotelReviewSummaryResponse struct {
	ShortSummary   string   `json:"shortSummary"`
	PositivePoints []string `json:"positivePoints"`
	NegativePoints []string `json:"negativePoints"`
	BestFor        []string `json:"bestFor"`
	NotIdealFor    []string `json:"notIdealFor"`
	Confidence     string   `json:"confidence"`
	BasedOnSources []string `json:"basedOnSources"`
}

type HotelReviewsSourceGroupResponse struct {
	Source        string                `json:"source"`
	TotalReviews  int                   `json:"totalReviews"`
	AverageRating float64               `json:"averageRating"`
	Scale         float64               `json:"scale"`
	Reviews       []HotelReviewResponse `json:"reviews"`
}

type HotelReviewResponse struct {
	ReviewID   string  `json:"reviewId"`
	AuthorName *string `json:"authorName"`
	Rating     float64 `json:"rating"`
	Scale      float64 `json:"scale"`
	Text       string  `json:"text"`
	Date       *string `json:"date"`
}

type HotelRoomResponse struct {
	RoomID            string      `json:"roomId"`
	Name              string      `json:"name"`
	Description       *string     `json:"description"`
	ImageURL          *string     `json:"imageUrl"`
	Capacity          int         `json:"capacity"`
	BedType           *string     `json:"bedType"`
	AreaSqm           *float64    `json:"areaSqm"`
	Refundable        *bool       `json:"refundable"`
	BreakfastIncluded *bool       `json:"breakfastIncluded"`
	PricePerNight     MobileMoney `json:"pricePerNight"`
	TotalPrice        MobileMoney `json:"totalPrice"`
	Labels            []string    `json:"labels"`
	TradeoffLabel     *string     `json:"tradeoffLabel"`
}

type HotelRoomOptionsResponse struct {
	SelectedRoomID  string  `json:"selectedRoomId"`
	DowngradeRoomID *string `json:"downgradeRoomId"`
	UpgradeRoomID   *string `json:"upgradeRoomId"`
	SelectedReason  string  `json:"selectedReason"`
	DowngradeLabel  *string `json:"downgradeLabel"`
	UpgradeLabel    *string `json:"upgradeLabel"`
}

type HotelLocationInfoResponse struct {
	DistanceToAirportKm     *float64     `json:"distanceToAirportKm"`
	TaxiFromAirport         *MobileMoney `json:"taxiFromAirport"`
	DistanceToMainClusterKm *float64     `json:"distanceToMainClusterKm"`
	DistanceToBeachKm       *float64     `json:"distanceToBeachKm"`
	AverageTaxiToActivities *MobileMoney `json:"averageTaxiToActivities"`
	WalkablePlacesCount     *int         `json:"walkablePlacesCount"`
	LocationScore           *float64     `json:"locationScore"`
	PriceScore              *float64     `json:"priceScore"`
	ConvenienceScore        *float64     `json:"convenienceScore"`
}
