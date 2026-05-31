package travelcore

import (
	"time"

	"github.com/google/uuid"
)

const (
	StatusDraft                = "draft"
	StatusCollectingInput      = "collecting_input"
	StatusReadyForConfirmation = "ready_for_confirmation"
	StatusConfirmed            = "confirmed"
	StatusGenerated            = "generated"
	StatusEdited               = "edited"
)

type TripState struct {
	ID                 uuid.UUID         `json:"id"`
	Status             string            `json:"status"`
	Title              string            `json:"title"`
	OriginCity         string            `json:"origin_city"`
	DestinationCountry string            `json:"destination_country"`
	DestinationCity    string            `json:"destination_city"`
	StartDate          string            `json:"start_date"`
	EndDate            string            `json:"end_date"`
	Budget             int               `json:"budget"`
	TransportType      string            `json:"transport_type"`
	TripPurpose        string            `json:"trip_purpose"`
	VibeLabels         []string          `json:"vibe_labels"`
	Citizenship        string            `json:"citizenship"`
	HotelPreferences   []string          `json:"hotel_preferences"`
	EventInterest      bool              `json:"event_interest"`
	InsuranceNeeded    bool              `json:"insurance_needed"`
	Interests          []string          `json:"interests"`
	Travelers          []Traveler        `json:"travelers"`
	TodoSections       []TodoSection     `json:"todo_sections"`
	SelectedTransport  *TransportOption  `json:"selected_transport,omitempty"`
	TransportOptions   []TransportOption `json:"transport_options"`
	SelectedHotel      *HotelOption      `json:"selected_hotel,omitempty"`
	HotelOptions       []HotelOption     `json:"hotel_options"`
	Activities         []ActivityItem    `json:"activities"`
	BudgetSummary      BudgetSummary     `json:"budget_summary"`
	VisaInfo           LegacyVisaInfo    `json:"visa"`
	ReviewSummaries    []ReviewSummary   `json:"review_summaries"`
	Offers             OfferSummary      `json:"offers"`
	ChatSessionID      uuid.UUID         `json:"chat_session_id"`
	CreatedAt          time.Time         `json:"created_at"`
	UpdatedAt          time.Time         `json:"updated_at"`
}

type Traveler struct {
	ID          uuid.UUID `json:"id"`
	Type        string    `json:"type"`
	AgeGroup    string    `json:"age_group"`
	Name        string    `json:"name,omitempty"`
	Preferences []string  `json:"preferences,omitempty"`
	Notes       string    `json:"notes,omitempty"`
}

type TodoSection struct {
	ID    string     `json:"id"`
	Title string     `json:"title"`
	Items []TodoItem `json:"items"`
}

type TodoItem struct {
	ID          uuid.UUID `json:"id"`
	Kind        string    `json:"kind"`
	Title       string    `json:"title"`
	Description string    `json:"description"`
	Status      string    `json:"status"`
	DayLabel    string    `json:"day_label,omitempty"`
	Price       int       `json:"price,omitempty"`
	Link        string    `json:"link,omitempty"`
}

type TransportOption struct {
	ID          uuid.UUID `json:"id"`
	Mode        string    `json:"mode"`
	Provider    string    `json:"provider"`
	Title       string    `json:"title"`
	Origin      string    `json:"origin"`
	Destination string    `json:"destination"`
	Departure   string    `json:"departure"`
	Arrival     string    `json:"arrival"`
	Price       int       `json:"price"`
	Currency    string    `json:"currency"`
	Selected    bool      `json:"selected"`
	Description string    `json:"description"`
}

type HotelOption struct {
	ID          uuid.UUID `json:"id"`
	Provider    string    `json:"provider"`
	Name        string    `json:"name"`
	Location    string    `json:"location"`
	Price       int       `json:"price"`
	Currency    string    `json:"currency"`
	Rating      float64   `json:"rating"`
	Selected    bool      `json:"selected"`
	Description string    `json:"description"`
	ReviewLink  string    `json:"review_link"`
}

type ActivityItem struct {
	ID            uuid.UUID `json:"id"`
	Kind          string    `json:"kind"`
	Title         string    `json:"title"`
	Location      string    `json:"location"`
	DayLabel      string    `json:"day_label"`
	Price         int       `json:"price"`
	Currency      string    `json:"currency"`
	SourceName    string    `json:"source_name"`
	SourceLink    string    `json:"source_link"`
	ManuallyAdded bool      `json:"manually_added"`
	Description   string    `json:"description"`
}

type BudgetSummary struct {
	TransportTotal          int    `json:"transport_total"`
	HotelTotal              int    `json:"hotel_total"`
	EventsTotal             int    `json:"events_total"`
	EstimatedFoodTotal      int    `json:"estimated_food_total"`
	EstimatedLocalTransport int    `json:"estimated_local_transport_total"`
	InsuranceEstimate       int    `json:"insurance_estimate"`
	GrandTotal              int    `json:"grand_total"`
	CashbackAmount          int    `json:"cashback_amount"`
	BonusAmount             int    `json:"bonus_amount"`
	HalykOfferLabel         string `json:"halyk_offer_label"`
	Currency                string `json:"currency"`
}

type LegacyVisaInfo struct {
	Country         string   `json:"country"`
	Requirement     string   `json:"requirement"`
	RecommendedLead string   `json:"recommended_lead"`
	Checklist       []string `json:"checklist"`
	Notes           string   `json:"notes"`
}

type ReviewSummary struct {
	ID         uuid.UUID `json:"id"`
	Kind       string    `json:"kind"`
	TargetName string    `json:"target_name"`
	Summary    string    `json:"summary"`
	SourceName string    `json:"source_name"`
	SourceLink string    `json:"source_link"`
}

type OfferSummary struct {
	CashbackAmount int      `json:"cashback_amount"`
	BonusAmount    int      `json:"bonus_amount"`
	HalykOffer     string   `json:"halyk_offer"`
	Highlights     []string `json:"highlights"`
}

type ChatSession struct {
	ID        uuid.UUID     `json:"id"`
	TripID    uuid.UUID     `json:"trip_id"`
	Messages  []ChatMessage `json:"messages"`
	CreatedAt time.Time     `json:"created_at"`
	UpdatedAt time.Time     `json:"updated_at"`
}

type ChatMessage struct {
	ID         uuid.UUID      `json:"id"`
	Role       string         `json:"role"`
	Content    string         `json:"content"`
	Action     string         `json:"action,omitempty"`
	Structured map[string]any `json:"structured,omitempty"`
	CreatedAt  time.Time      `json:"created_at"`
}

type CreateTripDTO struct {
	Title string `json:"title" validate:"required,min=3"`
}

type PatchTripDTO struct {
	OriginCity         string          `json:"origin_city"`
	DestinationCountry string          `json:"destination_country"`
	DestinationCity    string          `json:"destination_city"`
	StartDate          string          `json:"start_date"`
	EndDate            string          `json:"end_date"`
	Budget             int             `json:"budget"`
	TransportType      string          `json:"transport_type"`
	TripPurpose        string          `json:"trip_purpose"`
	Citizenship        string          `json:"citizenship"`
	HotelPreferences   []string        `json:"hotel_preferences"`
	EventInterest      *bool           `json:"event_interest"`
	InsuranceNeeded    *bool           `json:"insurance_needed"`
	Interests          []string        `json:"interests"`
	Travelers          []TravelerInput `json:"travelers"`
}

type TravelerInput struct {
	Type        string   `json:"type" validate:"required"`
	AgeGroup    string   `json:"age_group" validate:"required"`
	Name        string   `json:"name"`
	Preferences []string `json:"preferences"`
	Notes       string   `json:"notes"`
}

type ChatMessageDTO struct {
	Content string `json:"content" validate:"required,min=2"`
	Action  string `json:"action"`
}

type ManualActivityDTO struct {
	Kind        string `json:"kind" validate:"required"`
	Title       string `json:"title" validate:"required"`
	Location    string `json:"location" validate:"required"`
	DayLabel    string `json:"day_label" validate:"required"`
	Price       int    `json:"price"`
	SourceName  string `json:"source_name"`
	SourceLink  string `json:"source_link"`
	Description string `json:"description"`
}

type AIPlanningRequest struct {
	TripID      uuid.UUID      `json:"trip_id"`
	Action      string         `json:"action"`
	UserPrompt  string         `json:"user_prompt"`
	CurrentTrip map[string]any `json:"current_trip"`
	ChatHistory []ChatMessage  `json:"chat_history"`
}

type AIPlanningResponse struct {
	MissingFields    []string        `json:"missing_fields"`
	NormalizedFields map[string]any  `json:"normalized_fields"`
	VibeLabels       []string        `json:"vibe_labels"`
	VisaInsights     LegacyVisaInfo  `json:"visa_insights"`
	WeatherInsights  []string        `json:"weather_insights"`
	ReviewSummaries  []ReviewSummary `json:"review_summaries"`
	AssistantSummary string          `json:"assistant_summary"`
}

type MissingField struct {
	Key    string `json:"key"`
	Label  string `json:"label"`
	Prompt string `json:"prompt"`
}

type PlanningTripResponse struct {
	TripID               uuid.UUID      `json:"trip_id"`
	Status               string         `json:"status"`
	Title                string         `json:"title"`
	NormalizedFields     map[string]any `json:"normalized_fields"`
	MissingFields        []MissingField `json:"missing_fields"`
	ReadyForConfirmation bool           `json:"ready_for_confirmation"`
	ChatEntrypoints      []string       `json:"chat_entrypoints"`
	UpdatedAt            time.Time      `json:"updated_at"`
}

type PlanningMessage struct {
	ID         uuid.UUID      `json:"id"`
	Role       string         `json:"role"`
	Content    string         `json:"content"`
	Action     string         `json:"action,omitempty"`
	Structured map[string]any `json:"structured,omitempty"`
	CreatedAt  time.Time      `json:"created_at"`
}

type PlanningChatResponse struct {
	Trip           PlanningTripResponse `json:"trip"`
	SessionID      uuid.UUID            `json:"session_id"`
	Messages       []PlanningMessage    `json:"messages"`
	AssistantHints []string             `json:"assistant_hints"`
}

type UserProfileResponse struct {
	UserID            string        `json:"userId"`
	Citizenship       string        `json:"citizenship"`
	HomeCity          string        `json:"homeCity"`
	HomeAirport       string        `json:"homeAirport"`
	Currency          string        `json:"currency"`
	PreferredLanguage string        `json:"preferredLanguage"`
	TravelProfile     TravelProfile `json:"travelProfile"`
}

type TravelProfile struct {
	BudgetLevel             string   `json:"budgetLevel"`
	TravelFrequency         string   `json:"travelFrequency"`
	PreferredTripLengthDays int      `json:"preferredTripLengthDays"`
	PreferredCategories     []string `json:"preferredCategories"`
	AvoidCategories         []string `json:"avoidCategories"`
	HotelPreference         string   `json:"hotelPreference"`
	TransportPreference     string   `json:"transportPreference"`
}

type RecommendationsResponse struct {
	UserID          string               `json:"userId"`
	GeneratedAt     string               `json:"generatedAt"`
	SelectedMode    string               `json:"selectedMode"`
	Recommendations []TripRecommendation `json:"recommendations"`
}

type TripRecommendation struct {
	TripID             string            `json:"tripId"`
	DestinationTitle   string            `json:"destinationTitle"`
	CountryCode        string            `json:"countryCode"`
	CityCodes          []string          `json:"cityCodes"`
	StartDate          string            `json:"startDate,omitempty"`
	EndDate            string            `json:"endDate,omitempty"`
	DurationDays       int               `json:"durationDays"`
	ImageURL           string            `json:"imageUrl,omitempty"`
	EstimatedTotalCost EstimatedMoney    `json:"estimatedTotalCost"`
	CashbackEstimate   *CashbackEstimate `json:"cashbackEstimate,omitempty"`
	MainReason         string            `json:"mainReason"`
	ReasonLabels       []string          `json:"reasonLabels"`
	RecommendationType string            `json:"recommendationType"`
	Score              float64           `json:"score"`
}

type TripDetailsResponse struct {
	TripID         string                 `json:"tripId"`
	Title          string                 `json:"title"`
	Subtitle       string                 `json:"subtitle"`
	StartDate      string                 `json:"startDate"`
	EndDate        string                 `json:"endDate"`
	DurationDays   int                    `json:"durationDays"`
	PeopleCount    int                    `json:"peopleCount"`
	Currency       string                 `json:"currency"`
	SelectedMode   string                 `json:"selectedMode"`
	AvailableModes []string               `json:"availableModes"`
	Summary        TripSummary            `json:"summary"`
	RouteNavigator []RouteStop            `json:"routeNavigator"`
	Map            TripMap                `json:"map"`
	Segments       []ItinerarySegment     `json:"segments"`
	Budget         BudgetBreakdown        `json:"budget"`
	ModeVariants   map[string]ModeVariant `json:"modeVariants"`
	Visa           *VisaInfo              `json:"visa,omitempty"`
	Cashback       *CashbackInfo          `json:"cashback,omitempty"`
	Challenges     []TravelChallenge      `json:"challenges"`
	Warnings       []SmartWarning         `json:"warnings"`
}

type TripSummary struct {
	EstimatedTotalCost     Money    `json:"estimatedTotalCost"`
	EstimatedTotalCashback *Money   `json:"estimatedTotalCashback,omitempty"`
	WeatherSummary         string   `json:"weatherSummary,omitempty"`
	VisaStatus             string   `json:"visaStatus,omitempty"`
	MainLabels             []string `json:"mainLabels"`
}

type RouteStop struct {
	StopID          string       `json:"stopId"`
	Title           string       `json:"title"`
	StartDate       string       `json:"startDate"`
	EndDate         string       `json:"endDate"`
	TransportToNext string       `json:"transportToNext,omitempty"`
	Coordinates     *Coordinates `json:"coordinates,omitempty"`
}

type TripMap struct {
	InitialCamera MapCamera   `json:"initialCamera"`
	Markers       []MapMarker `json:"markers"`
	Routes        []MapRoute  `json:"routes"`
}

type MapCamera struct {
	CenterLat float64 `json:"centerLat"`
	CenterLng float64 `json:"centerLng"`
	Zoom      float64 `json:"zoom"`
}

type MapMarker struct {
	MarkerID  string         `json:"markerId"`
	SegmentID string         `json:"segmentId,omitempty"`
	Type      string         `json:"type"`
	Title     string         `json:"title"`
	Subtitle  string         `json:"subtitle,omitempty"`
	Lat       float64        `json:"lat"`
	Lng       float64        `json:"lng"`
	Icon      string         `json:"icon,omitempty"`
	Price     *MoneyWithUnit `json:"price,omitempty"`
	Labels    []string       `json:"labels,omitempty"`
}

type MapRoute struct {
	RouteID           string             `json:"routeId"`
	FromMarkerID      string             `json:"fromMarkerId"`
	ToMarkerID        string             `json:"toMarkerId"`
	SegmentID         string             `json:"segmentId,omitempty"`
	TransportType     string             `json:"transportType"`
	DistanceKm        float64            `json:"distanceKm"`
	DurationMinutes   int                `json:"durationMinutes"`
	EstimatedCost     *Money             `json:"estimatedCost,omitempty"`
	Polyline          string             `json:"polyline,omitempty"`
	AlternativeRoutes []AlternativeRoute `json:"alternativeRoutes,omitempty"`
}

type AlternativeRoute struct {
	TransportType   string `json:"transportType"`
	DurationMinutes int    `json:"durationMinutes"`
	EstimatedCost   *Money `json:"estimatedCost,omitempty"`
	Reason          string `json:"reason"`
}

type ItinerarySegment struct {
	SegmentID       string         `json:"segmentId"`
	Type            string         `json:"type"`
	Title           string         `json:"title"`
	Date            string         `json:"date"`
	DayNumber       int            `json:"dayNumber"`
	StartTime       string         `json:"startTime,omitempty"`
	EndTime         string         `json:"endTime,omitempty"`
	Icon            string         `json:"icon"`
	Status          string         `json:"status"`
	LinkedMarkerIDs []string       `json:"linkedMarkerIds"`
	LinkedRouteIDs  []string       `json:"linkedRouteIds"`
	Price           *Money         `json:"price,omitempty"`
	Labels          []string       `json:"labels"`
	Description     string         `json:"description,omitempty"`
	Details         SegmentDetails `json:"details"`
}

type SegmentDetails struct {
	Kind    string `json:"kind"`
	Payload any    `json:"payload"`
}

type HotelDetailsFull struct {
	HotelID         string                    `json:"hotelId"`
	Name            string                    `json:"name"`
	City            string                    `json:"city"`
	District        string                    `json:"district,omitempty"`
	Address         string                    `json:"address,omitempty"`
	Lat             float64                   `json:"lat"`
	Lng             float64                   `json:"lng"`
	Stars           *int                      `json:"stars,omitempty"`
	MainImageURL    string                    `json:"mainImageUrl,omitempty"`
	Rating          HotelRating               `json:"rating"`
	SourceRatings   []HotelSourceRating       `json:"sourceRatings"`
	ReviewSummary   HotelReviewSummary        `json:"reviewSummary"`
	ReviewsBySource []HotelReviewsSourceGroup `json:"reviewsBySource"`
	Rooms           []HotelRoom               `json:"rooms"`
	SelectedRoomID  string                    `json:"selectedRoomId"`
	RoomOptions     HotelRoomOptions          `json:"roomOptions"`
	LocationInfo    HotelLocationInfo         `json:"locationInfo"`
	Reason          string                    `json:"reason"`
}

type HotelRating struct {
	Overall     float64 `json:"overall"`
	Scale       float64 `json:"scale"`
	Label       string  `json:"label,omitempty"`
	ReviewCount int     `json:"reviewCount"`
}

type HotelSourceRating struct {
	Source      string  `json:"source"`
	Rating      float64 `json:"rating"`
	Scale       float64 `json:"scale"`
	ReviewCount int     `json:"reviewCount"`
	URL         string  `json:"url,omitempty"`
}

type HotelReviewsSourceGroup struct {
	Source        string        `json:"source"`
	TotalReviews  int           `json:"totalReviews"`
	AverageRating float64       `json:"averageRating"`
	Scale         float64       `json:"scale"`
	Reviews       []HotelReview `json:"reviews"`
}

type HotelReview struct {
	ReviewID   string   `json:"reviewId"`
	AuthorName string   `json:"authorName,omitempty"`
	Rating     float64  `json:"rating"`
	Scale      float64  `json:"scale"`
	Date       string   `json:"date,omitempty"`
	Language   string   `json:"language,omitempty"`
	Title      string   `json:"title,omitempty"`
	Text       string   `json:"text"`
	Pros       []string `json:"pros,omitempty"`
	Cons       []string `json:"cons,omitempty"`
}

type HotelReviewSummary struct {
	ShortSummary   string   `json:"shortSummary"`
	PositivePoints []string `json:"positivePoints"`
	NegativePoints []string `json:"negativePoints"`
	BestFor        []string `json:"bestFor"`
	NotIdealFor    []string `json:"notIdealFor"`
	Confidence     string   `json:"confidence"`
	BasedOnSources []string `json:"basedOnSources"`
}

type HotelRoom struct {
	RoomID            string   `json:"roomId"`
	Name              string   `json:"name"`
	Description       string   `json:"description,omitempty"`
	ImageURL          string   `json:"imageUrl,omitempty"`
	Capacity          int      `json:"capacity"`
	BedType           string   `json:"bedType,omitempty"`
	AreaSqm           float64  `json:"areaSqm,omitempty"`
	Refundable        *bool    `json:"refundable,omitempty"`
	BreakfastIncluded *bool    `json:"breakfastIncluded,omitempty"`
	PricePerNight     Money    `json:"pricePerNight"`
	TotalPrice        Money    `json:"totalPrice"`
	Labels            []string `json:"labels"`
	TradeoffLabel     string   `json:"tradeoffLabel,omitempty"`
}

type HotelRoomOptions struct {
	SelectedRoomID  string `json:"selectedRoomId"`
	DowngradeRoomID string `json:"downgradeRoomId,omitempty"`
	UpgradeRoomID   string `json:"upgradeRoomId,omitempty"`
	SelectedReason  string `json:"selectedReason"`
	DowngradeLabel  string `json:"downgradeLabel,omitempty"`
	UpgradeLabel    string `json:"upgradeLabel,omitempty"`
}

type HotelLocationInfo struct {
	DistanceToAirportKm     *float64 `json:"distanceToAirportKm,omitempty"`
	TaxiFromAirport         *Money   `json:"taxiFromAirport,omitempty"`
	DistanceToMainClusterKm *float64 `json:"distanceToMainClusterKm,omitempty"`
	AverageTaxiToActivities *Money   `json:"averageTaxiToActivities,omitempty"`
	WalkablePlacesCount     *int     `json:"walkablePlacesCount,omitempty"`
	LocationScore           *float64 `json:"locationScore,omitempty"`
	PriceScore              *float64 `json:"priceScore,omitempty"`
	ConvenienceScore        *float64 `json:"convenienceScore,omitempty"`
}

type BudgetBreakdown struct {
	Total EstimatedMoney `json:"total"`
	Items []BudgetItem   `json:"items"`
}

type BudgetItem struct {
	Amount   float64 `json:"amount"`
	Currency string  `json:"currency"`
	Category string  `json:"category"`
	Title    string  `json:"title"`
}

type ModeVariant struct {
	TotalCost                   int    `json:"totalCost"`
	HotelStrategy               string `json:"hotelStrategy"`
	TransportStrategy           string `json:"transportStrategy"`
	EstimatedTravelTimeMinutes  int    `json:"estimatedTravelTimeMinutes"`
	SavingsComparedToBalanced   *int   `json:"savingsComparedToBalanced,omitempty"`
	ExtraCostComparedToBalanced *int   `json:"extraCostComparedToBalanced,omitempty"`
	TradeoffLabel               string `json:"tradeoffLabel"`
}

type VisaInfo struct {
	Citizenship        string `json:"citizenship"`
	DestinationCountry string `json:"destinationCountry"`
	Status             string `json:"status"`
	Required           bool   `json:"required"`
	EstimatedCost      *Money `json:"estimatedCost,omitempty"`
	ProcessingTimeDays *int   `json:"processingTimeDays,omitempty"`
	Notes              string `json:"notes,omitempty"`
	Confidence         string `json:"confidence"`
}

type CashbackInfo struct {
	EstimatedTotal Money          `json:"estimatedTotal"`
	BasePercent    float64        `json:"basePercent"`
	BoostedPercent *float64       `json:"boostedPercent,omitempty"`
	Items          []CashbackItem `json:"items"`
}

type CashbackItem struct {
	Category  string  `json:"category"`
	Amount    float64 `json:"amount"`
	Currency  string  `json:"currency"`
	Condition string  `json:"condition"`
}

type TravelChallenge struct {
	ChallengeID string            `json:"challengeId"`
	Title       string            `json:"title"`
	Description string            `json:"description"`
	Reward      ChallengeReward   `json:"reward"`
	Progress    ChallengeProgress `json:"progress"`
	Deadline    string            `json:"deadline,omitempty"`
	Difficulty  string            `json:"difficulty"`
	Reason      string            `json:"reason"`
}

type ChallengeReward struct {
	Type         string   `json:"type"`
	ValuePercent *float64 `json:"valuePercent,omitempty"`
	Amount       *Money   `json:"amount,omitempty"`
}

type ChallengeProgress struct {
	Current float64 `json:"current"`
	Target  float64 `json:"target"`
	Unit    string  `json:"unit"`
}

type SmartWarning struct {
	Type      string `json:"type"`
	Severity  string `json:"severity"`
	SegmentID string `json:"segmentId,omitempty"`
	Message   string `json:"message"`
}

type Money struct {
	Amount   float64 `json:"amount"`
	Currency string  `json:"currency"`
}

type EstimatedMoney struct {
	Amount     float64 `json:"amount"`
	Currency   string  `json:"currency"`
	Confidence string  `json:"confidence"`
}

type CashbackEstimate struct {
	Amount   float64 `json:"amount"`
	Currency string  `json:"currency"`
	Percent  float64 `json:"percent"`
}

type MoneyWithUnit struct {
	Amount   float64 `json:"amount"`
	Currency string  `json:"currency"`
	Unit     string  `json:"unit,omitempty"`
}

type Coordinates struct {
	Lat float64 `json:"lat"`
	Lng float64 `json:"lng"`
}
