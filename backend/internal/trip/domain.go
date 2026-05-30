package trip

import (
	"time"

	"github.com/google/uuid"
)

const (
	StatusDraft                = "draft"
	StatusCollectingInput      = "collecting_input"
	StatusReadyForConfirmation = "ready_for_confirmation"
	StatusGenerated            = "generated"
	StatusEdited               = "edited"
)

type Trip struct {
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
	BudgetSummary      BudgetSummary     `json:"budget"`
	VisaInfo           VisaInfo          `json:"visa"`
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

type VisaInfo struct {
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

type TripDetailsResponse struct {
	Trip              Trip             `json:"trip"`
	Travelers         []Traveler       `json:"travelers"`
	TodoSections      []TodoSection    `json:"todo_sections"`
	SelectedTransport *TransportOption `json:"selected_transport,omitempty"`
	SelectedHotel     *HotelOption     `json:"selected_hotel,omitempty"`
	Activities        []ActivityItem   `json:"activities"`
	Budget            BudgetSummary    `json:"budget"`
	Visa              VisaInfo         `json:"visa"`
	ReviewSummaries   []ReviewSummary  `json:"review_summaries"`
	Offers            OfferSummary     `json:"offers"`
	ChatEntrypoints   []string         `json:"chat_entrypoints"`
}

type ChatResponse struct {
	SessionID      uuid.UUID     `json:"session_id"`
	Messages       []ChatMessage `json:"messages"`
	MissingFields  []string      `json:"missing_fields"`
	AssistantHints []string      `json:"assistant_hints"`
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
	VisaInsights     VisaInfo        `json:"visa_insights"`
	WeatherInsights  []string        `json:"weather_insights"`
	ReviewSummaries  []ReviewSummary `json:"review_summaries"`
	AssistantSummary string          `json:"assistant_summary"`
}
