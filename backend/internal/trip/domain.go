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
	ID                 uuid.UUID         `json:"id" example:"a3f94ada-373a-4816-8a9b-2d0ce79cd55e"`
	Status             string            `json:"status" example:"collecting_input"`
	Title              string            `json:"title" example:"Family trip to Japan in July with budget 900000 from Almaty and Kazakhstan passport"`
	OriginCity         string            `json:"origin_city" example:"Almaty"`
	DestinationCountry string            `json:"destination_country" example:"Japan"`
	DestinationCity    string            `json:"destination_city" example:"Tokyo"`
	StartDate          string            `json:"start_date" example:"2026-07-10"`
	EndDate            string            `json:"end_date" example:"2026-07-17"`
	Budget             int               `json:"budget" example:"900000"`
	TransportType      string            `json:"transport_type" example:"flight"`
	TripPurpose        string            `json:"trip_purpose" example:"family"`
	VibeLabels         []string          `json:"vibe_labels" example:"family,budget,balanced"`
	Citizenship        string            `json:"citizenship" example:"Kazakhstan"`
	HotelPreferences   []string          `json:"hotel_preferences" example:"family-friendly,city-center"`
	EventInterest      bool              `json:"event_interest" example:"false"`
	InsuranceNeeded    bool              `json:"insurance_needed" example:"true"`
	Interests          []string          `json:"interests" example:"culture,food,events"`
	Travelers          []Traveler        `json:"travelers"`
	TodoSections       []TodoSection     `json:"todo_sections"`
	SelectedTransport  *TransportOption  `json:"selected_transport,omitempty"`
	TransportOptions   []TransportOption `json:"transport_options"`
	SelectedHotel      *HotelOption      `json:"selected_hotel,omitempty"`
	HotelOptions       []HotelOption     `json:"hotel_options"`
	Activities         []ActivityItem    `json:"activities"`
	BudgetSummary      BudgetSummary     `json:"budget_summary"`
	VisaInfo           VisaInfo          `json:"visa"`
	ReviewSummaries    []ReviewSummary   `json:"review_summaries"`
	Offers             OfferSummary      `json:"offers"`
	ChatSessionID      uuid.UUID         `json:"chat_session_id" example:"fbc99327-dcb9-4d3e-9367-29c618a5904c"`
	CreatedAt          time.Time         `json:"created_at" example:"2026-05-30T20:11:54Z"`
	UpdatedAt          time.Time         `json:"updated_at" example:"2026-05-30T20:11:54Z"`
}

type Traveler struct {
	ID          uuid.UUID `json:"id" example:"54f0dd78-8c07-4ee6-bc59-e0bd94622b0f"`
	Type        string    `json:"type" example:"child"`
	AgeGroup    string    `json:"age_group" example:"7-12"`
	Name        string    `json:"name,omitempty" example:"Aru"`
	Preferences []string  `json:"preferences,omitempty" example:"anime,parks"`
	Notes       string    `json:"notes,omitempty" example:"Needs stroller-friendly routes"`
}

type TodoSection struct {
	ID    string     `json:"id" example:"activities"`
	Title string     `json:"title" example:"Places and Events"`
	Items []TodoItem `json:"items"`
}

type TodoItem struct {
	ID          uuid.UUID `json:"id" example:"1f7a559a-59a4-40fc-9e8b-290d0df0869d"`
	Kind        string    `json:"kind" example:"event"`
	Title       string    `json:"title" example:"Kino.kz Anime Event Pick"`
	Description string    `json:"description" example:"Optional event-focused option for solo travelers"`
	Status      string    `json:"status" example:"planned"`
	DayLabel    string    `json:"day_label,omitempty" example:"Day 3"`
	Price       int       `json:"price,omitempty" example:"21000"`
	Link        string    `json:"link,omitempty" example:"https://kino.kz"`
}

type TransportOption struct {
	ID          uuid.UUID `json:"id" example:"19798767-f9b0-4ca8-8fe8-5d51706caf92"`
	Mode        string    `json:"mode" example:"flight"`
	Provider    string    `json:"provider" example:"JAL Mock"`
	Title       string    `json:"title" example:"Almaty -> Tokyo"`
	Origin      string    `json:"origin" example:"Almaty"`
	Destination string    `json:"destination" example:"Tokyo"`
	Departure   string    `json:"departure" example:"07:10"`
	Arrival     string    `json:"arrival" example:"16:20"`
	Price       int       `json:"price" example:"395000"`
	Currency    string    `json:"currency" example:"KZT"`
	Selected    bool      `json:"selected" example:"true"`
	Description string    `json:"description" example:"High-comfort long-haul option"`
}

type HotelOption struct {
	ID          uuid.UUID `json:"id" example:"314ffcbe-5599-4865-aa43-95e5f6f9845a"`
	Provider    string    `json:"provider" example:"Booking Mock"`
	Name        string    `json:"name" example:"Tokyo Family Smart Hotel"`
	Location    string    `json:"location" example:"Shinjuku"`
	Price       int       `json:"price" example:"355000"`
	Currency    string    `json:"currency" example:"KZT"`
	Rating      float64   `json:"rating" example:"4.8"`
	Selected    bool      `json:"selected" example:"true"`
	Description string    `json:"description" example:"Central stay for family and solo travelers"`
	ReviewLink  string    `json:"review_link" example:"https://maps.google.com/?q=Shinjuku+hotel"`
}

type ActivityItem struct {
	ID            uuid.UUID `json:"id" example:"f42f0f73-f08d-4ca6-a74f-e15a028ef70e"`
	Kind          string    `json:"kind" example:"place"`
	Title         string    `json:"title" example:"Asakusa and Senso-ji"`
	Location      string    `json:"location" example:"Tokyo"`
	DayLabel      string    `json:"day_label" example:"Day 1"`
	Price         int       `json:"price" example:"16000"`
	Currency      string    `json:"currency" example:"KZT"`
	SourceName    string    `json:"source_name" example:"Google Maps"`
	SourceLink    string    `json:"source_link" example:"https://maps.google.com/?q=Sensoji"`
	ManuallyAdded bool      `json:"manually_added" example:"false"`
	Description   string    `json:"description" example:"Cultural first-day itinerary stop"`
}

type BudgetSummary struct {
	TransportTotal          int    `json:"transport_total" example:"395000"`
	HotelTotal              int    `json:"hotel_total" example:"355000"`
	EventsTotal             int    `json:"events_total" example:"37000"`
	EstimatedFoodTotal      int    `json:"estimated_food_total" example:"84000"`
	EstimatedLocalTransport int    `json:"estimated_local_transport_total" example:"36000"`
	InsuranceEstimate       int    `json:"insurance_estimate" example:"22000"`
	GrandTotal              int    `json:"grand_total" example:"929000"`
	CashbackAmount          int    `json:"cashback_amount" example:"46450"`
	BonusAmount             int    `json:"bonus_amount" example:"18580"`
	HalykOfferLabel         string `json:"halyk_offer_label" example:"Pay fully with Halyk mock card and unlock cashback"`
	Currency                string `json:"currency" example:"KZT"`
}

type VisaInfo struct {
	Country         string   `json:"country" example:"Japan"`
	Requirement     string   `json:"requirement" example:"Prototype shows a visa-assistant style checklist"`
	RecommendedLead string   `json:"recommended_lead" example:"Begin visa preparation 30 days before departure"`
	Checklist       []string `json:"checklist" example:"Passport,Application form,Hotel proof,Trip itinerary,Insurance"`
	Notes           string   `json:"notes" example:"Mock data for the hackathon prototype"`
}

type ReviewSummary struct {
	ID         uuid.UUID `json:"id" example:"9c0b3bb5-42fc-4ae8-8db2-1aa02d9a20e0"`
	Kind       string    `json:"kind" example:"hotel"`
	TargetName string    `json:"target_name" example:"Tokyo Family Smart Hotel"`
	Summary    string    `json:"summary" example:"Review summary highlights cleanliness, transit access, and family room comfort."`
	SourceName string    `json:"source_name" example:"Tripadvisor"`
	SourceLink string    `json:"source_link" example:"https://tripadvisor.com"`
}

type OfferSummary struct {
	CashbackAmount int      `json:"cashback_amount" example:"46450"`
	BonusAmount    int      `json:"bonus_amount" example:"18580"`
	HalykOffer     string   `json:"halyk_offer" example:"Pay fully with Halyk mock card and unlock cashback"`
	Highlights     []string `json:"highlights" example:"Mock cashback applied on full Halyk payment,Bonus estimate included for pitch and UI,Kino.kz suggestions included where relevant"`
}

type ChatSession struct {
	ID        uuid.UUID     `json:"id" example:"fbc99327-dcb9-4d3e-9367-29c618a5904c"`
	TripID    uuid.UUID     `json:"trip_id" example:"a3f94ada-373a-4816-8a9b-2d0ce79cd55e"`
	Messages  []ChatMessage `json:"messages"`
	CreatedAt time.Time     `json:"created_at" example:"2026-05-30T20:11:54Z"`
	UpdatedAt time.Time     `json:"updated_at" example:"2026-05-30T20:11:54Z"`
}

type ChatMessage struct {
	ID         uuid.UUID      `json:"id" example:"6dcdb6a0-c86c-4d1d-8d03-1201f2fbe19f"`
	Role       string         `json:"role" example:"assistant"`
	Content    string         `json:"content" example:"I collected part of the family trip context. I still need a few fields before building the full plan."`
	Action     string         `json:"action,omitempty" example:"collect_fields"`
	Structured map[string]any `json:"structured,omitempty"`
	CreatedAt  time.Time      `json:"created_at" example:"2026-05-30T20:11:54Z"`
}

type CreateTripDTO struct {
	Title string `json:"title" validate:"required,min=3" example:"Family trip to Japan in July with budget 900000 from Almaty and Kazakhstan passport"`
}

type PatchTripDTO struct {
	OriginCity         string          `json:"origin_city" example:"Almaty"`
	DestinationCountry string          `json:"destination_country" example:"Japan"`
	DestinationCity    string          `json:"destination_city" example:"Tokyo"`
	StartDate          string          `json:"start_date" example:"2026-07-10"`
	EndDate            string          `json:"end_date" example:"2026-07-17"`
	Budget             int             `json:"budget" example:"900000"`
	TransportType      string          `json:"transport_type" example:"flight"`
	TripPurpose        string          `json:"trip_purpose" example:"family"`
	Citizenship        string          `json:"citizenship" example:"Kazakhstan"`
	HotelPreferences   []string        `json:"hotel_preferences" example:"family-friendly,city-center"`
	EventInterest      *bool           `json:"event_interest" example:"true"`
	InsuranceNeeded    *bool           `json:"insurance_needed" example:"true"`
	Interests          []string        `json:"interests" example:"culture,food,events"`
	Travelers          []TravelerInput `json:"travelers"`
}

type TravelerInput struct {
	Type        string   `json:"type" validate:"required" example:"child"`
	AgeGroup    string   `json:"age_group" validate:"required" example:"7-12"`
	Name        string   `json:"name" example:"Aru"`
	Preferences []string `json:"preferences" example:"anime,parks"`
	Notes       string   `json:"notes" example:"Needs stroller-friendly routes"`
}

type ChatMessageDTO struct {
	Content string `json:"content" validate:"required,min=2" example:"Change the hotel to a more budget-friendly option near Shinjuku."`
	Action  string `json:"action" example:"collect_fields"`
}

type ManualActivityDTO struct {
	Kind        string `json:"kind" validate:"required" example:"event"`
	Title       string `json:"title" validate:"required" example:"Kino.kz Anime Event Pick"`
	Location    string `json:"location" validate:"required" example:"Tokyo"`
	DayLabel    string `json:"day_label" validate:"required" example:"Day 3"`
	Price       int    `json:"price" example:"21000"`
	SourceName  string `json:"source_name" example:"Kino.kz"`
	SourceLink  string `json:"source_link" example:"https://kino.kz"`
	Description string `json:"description" example:"Manual event insertion from the selection screen"`
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
	ChatEntrypoints   []string         `json:"chat_entrypoints" example:"Ask AI to refine the plan,Ask AI about weather and season,Ask AI why this hotel fits"`
}

type ChatResponse struct {
	SessionID      uuid.UUID     `json:"session_id" example:"fbc99327-dcb9-4d3e-9367-29c618a5904c"`
	Messages       []ChatMessage `json:"messages"`
	MissingFields  []string      `json:"missing_fields" example:"start_date,end_date"`
	AssistantHints []string      `json:"assistant_hints" example:"Weather and seasonality are shown as guidance, not real-time facts.,AI suggestions should be checked again closer to departure."`
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
