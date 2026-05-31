package travelcore

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/agentic-lab-club/smart-travel-halyk-hackathon/backend/pkg/config"
	"github.com/agentic-lab-club/smart-travel-halyk-hackathon/backend/pkg/database"
	"github.com/google/uuid"
	"github.com/lib/pq"
)

type PlannerClient interface {
	Plan(ctx context.Context, req AIPlanningRequest) (*AIPlanningResponse, error)
}

type CoreService struct {
	repo    *Repository
	planner PlannerClient
	cfg     *config.Config
}

func NewCoreService(db *database.TrackedDB, cfg *config.Config) *CoreService {
	repo := NewRepository(db)
	return &CoreService{repo: repo, planner: NewPlannerClient(cfg), cfg: cfg}
}

type Repository struct {
	db       *database.TrackedDB
	mu       sync.RWMutex
	trips    map[uuid.UUID]*TripState
	sessions map[uuid.UUID]*ChatSession
}

func NewRepository(db *database.TrackedDB) *Repository {
	return &Repository{db: db, trips: make(map[uuid.UUID]*TripState), sessions: make(map[uuid.UUID]*ChatSession)}
}

func (r *Repository) CreateTrip(title string) (*TripState, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	now := time.Now().UTC()
	tripID := uuid.New()
	sessionID := uuid.New()
	trip := &TripState{ID: tripID, Status: StatusDraft, Title: title, ChatSessionID: sessionID, BudgetSummary: BudgetSummary{Currency: "KZT"}, CreatedAt: now, UpdatedAt: now}
	session := &ChatSession{ID: sessionID, TripID: tripID, Messages: []ChatMessage{}, CreatedAt: now, UpdatedAt: now}
	r.trips[tripID] = trip
	r.sessions[sessionID] = session
	return cloneTrip(trip), nil
}

func (r *Repository) GetTrip(id uuid.UUID) (*TripState, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	trip, ok := r.trips[id]
	if !ok {
		return nil, nil
	}
	return cloneTrip(trip), nil
}

func (r *Repository) SaveTrip(trip *TripState) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if trip == nil {
		return fmt.Errorf("failed to save trip: trip is nil")
	}
	cp := cloneTrip(trip)
	cp.UpdatedAt = time.Now().UTC()
	r.trips[cp.ID] = cp
	return nil
}

func (r *Repository) GetSessionByTripID(tripID uuid.UUID) (*ChatSession, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	trip, ok := r.trips[tripID]
	if !ok {
		return nil, nil
	}
	session, ok := r.sessions[trip.ChatSessionID]
	if !ok {
		return nil, nil
	}
	return cloneSession(session), nil
}

func (r *Repository) SaveSession(session *ChatSession) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if session == nil {
		return fmt.Errorf("failed to save session: session is nil")
	}
	cp := cloneSession(session)
	cp.UpdatedAt = time.Now().UTC()
	r.sessions[cp.ID] = cp
	return nil
}

func (r *Repository) FindTripByHotelID(hotelID string) (*TripState, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	for _, trip := range r.trips {
		if trip.SelectedHotel != nil && trip.SelectedHotel.ID.String() == hotelID {
			return cloneTrip(trip), nil
		}
		for _, option := range trip.HotelOptions {
			if option.ID.String() == hotelID {
				return cloneTrip(trip), nil
			}
		}
	}
	return nil, nil
}

type recommendationSeedRow struct {
	TripID             string         `db:"trip_id"`
	DestinationName    string         `db:"destination_name"`
	DestinationTitle   string         `db:"destination_title"`
	CountryCode        string         `db:"country_code"`
	CityCodes          pq.StringArray `db:"city_codes"`
	StartDate          string         `db:"start_date"`
	EndDate            string         `db:"end_date"`
	DurationDays       int            `db:"duration_days"`
	ImageURL           string         `db:"image_url"`
	EstimatedTotalCost float64        `db:"estimated_total_cost"`
	Currency           string         `db:"currency"`
	Confidence         string         `db:"confidence"`
	CashbackAmount     float64        `db:"cashback_amount"`
	CashbackPercent    float64        `db:"cashback_percent"`
	MainReason         string         `db:"main_reason"`
	ReasonLabels       pq.StringArray `db:"reason_labels"`
	RecommendationType string         `db:"recommendation_type"`
	Score              float64        `db:"score"`
}

func (r *Repository) ListRecommendationSeeds() ([]TripRecommendation, error) {
	if r == nil || r.db == nil {
		return nil, nil
	}

	rows := []recommendationSeedRow{}
	err := r.db.TrackedSelect(&rows, `
		SELECT
			trip_id,
			destination_name,
			destination_title,
			country_code,
			city_codes,
			COALESCE(start_date::text, '') AS start_date,
			COALESCE(end_date::text, '') AS end_date,
			duration_days,
			COALESCE(image_url, '') AS image_url,
			estimated_total_cost,
			currency,
			confidence,
			COALESCE(cashback_amount, 0) AS cashback_amount,
			COALESCE(cashback_percent, 0) AS cashback_percent,
			main_reason,
			reason_labels,
			recommendation_type,
			score
		FROM travel_trip_recommendations
		ORDER BY
			CASE recommendation_type
				WHEN 'similar_to_previous' THEN 1
				WHEN 'opposite_to_previous' THEN 2
				WHEN 'seasonal' THEN 3
				WHEN 'event_based' THEN 4
				ELSE 5
			END,
			score DESC,
			destination_title;
	`)
	if err != nil {
		return nil, err
	}

	recommendations := make([]TripRecommendation, 0, len(rows))
	for _, row := range rows {
		var cashback *CashbackEstimate
		if row.CashbackAmount > 0 || row.CashbackPercent > 0 {
			cashback = &CashbackEstimate{
				Amount:   row.CashbackAmount,
				Currency: row.Currency,
				Percent:  row.CashbackPercent,
			}
		}
		recommendations = append(recommendations, TripRecommendation{
			TripID:             row.TripID,
			DestinationName:    row.DestinationName,
			DestinationTitle:   row.DestinationTitle,
			CountryCode:        row.CountryCode,
			CityCodes:          append([]string{}, row.CityCodes...),
			StartDate:          row.StartDate,
			EndDate:            row.EndDate,
			DurationDays:       row.DurationDays,
			ImageURL:           row.ImageURL,
			EstimatedTotalCost: EstimatedMoney{Amount: row.EstimatedTotalCost, Currency: row.Currency, Confidence: row.Confidence},
			CashbackEstimate:   cashback,
			MainReason:         row.MainReason,
			ReasonLabels:       append([]string{}, row.ReasonLabels...),
			RecommendationType: row.RecommendationType,
			Score:              row.Score,
		})
	}
	return recommendations, nil
}

func (s *CoreService) CreateTrip(ctx context.Context, dto CreateTripDTO) (*PlanningTripResponse, error) {
	trip, err := s.repo.CreateTrip(dto.Title)
	if err != nil {
		return nil, fmt.Errorf("failed to create trip: %w", err)
	}
	session, err := s.repo.GetSessionByTripID(trip.ID)
	if err != nil {
		return nil, fmt.Errorf("failed to load chat session for trip draft: %w", err)
	}
	if session == nil {
		return nil, fmt.Errorf("failed to load chat session for trip draft: session missing")
	}
	if titlePrompt := strings.TrimSpace(dto.Title); titlePrompt != "" {
		session.Messages = append(session.Messages, ChatMessage{ID: uuid.New(), Role: "user", Content: titlePrompt, Action: "collect_fields", CreatedAt: time.Now().UTC()})
		plan, planErr := s.planner.Plan(ctx, AIPlanningRequest{TripID: trip.ID, Action: "collect_fields", UserPrompt: titlePrompt, CurrentTrip: tripToMap(trip), ChatHistory: session.Messages})
		if planErr == nil && plan != nil {
			s.applyAIFields(trip, plan)
			session.Messages = append(session.Messages, ChatMessage{ID: uuid.New(), Role: "assistant", Content: plan.AssistantSummary, Action: "collect_fields", Structured: map[string]any{"missing_fields": plan.MissingFields, "vibe_labels": plan.VibeLabels}, CreatedAt: time.Now().UTC()})
			if len(plan.MissingFields) == 0 {
				trip.Status = StatusReadyForConfirmation
			} else {
				trip.Status = StatusCollectingInput
			}
		}
	}
	if err := s.repo.SaveTrip(trip); err != nil {
		return nil, fmt.Errorf("failed to save created trip: %w", err)
	}
	if err := s.repo.SaveSession(session); err != nil {
		return nil, fmt.Errorf("failed to save created trip session: %w", err)
	}
	response := s.buildPlanningTripResponse(trip)
	return &response, nil
}

func (s *CoreService) GetPlanningTrip(tripID uuid.UUID) (*PlanningTripResponse, error) {
	trip, err := s.repo.GetTrip(tripID)
	if err != nil {
		return nil, fmt.Errorf("failed to get planning trip: %w", err)
	}
	if trip == nil {
		return nil, nil
	}
	response := s.buildPlanningTripResponse(trip)
	return &response, nil
}

func (s *CoreService) PatchTrip(tripID uuid.UUID, dto PatchTripDTO) (*PlanningTripResponse, error) {
	trip, err := s.repo.GetTrip(tripID)
	if err != nil {
		return nil, fmt.Errorf("failed to get trip for patch: %w", err)
	}
	if trip == nil {
		return nil, nil
	}
	if dto.OriginCity != "" {
		trip.OriginCity = dto.OriginCity
	}
	if dto.DestinationCountry != "" {
		trip.DestinationCountry = normalizeCountry(dto.DestinationCountry)
	}
	if dto.DestinationCity != "" {
		trip.DestinationCity = dto.DestinationCity
	}
	if dto.StartDate != "" {
		trip.StartDate = dto.StartDate
	}
	if dto.EndDate != "" {
		trip.EndDate = dto.EndDate
	}
	if dto.Budget > 0 {
		trip.Budget = dto.Budget
	}
	if dto.TransportType != "" {
		trip.TransportType = dto.TransportType
	}
	if dto.TripPurpose != "" {
		trip.TripPurpose = dto.TripPurpose
	}
	if dto.Citizenship != "" {
		trip.Citizenship = dto.Citizenship
	}
	if len(dto.HotelPreferences) > 0 {
		trip.HotelPreferences = dto.HotelPreferences
	}
	if dto.EventInterest != nil {
		trip.EventInterest = *dto.EventInterest
	}
	if dto.InsuranceNeeded != nil {
		trip.InsuranceNeeded = *dto.InsuranceNeeded
	}
	if len(dto.Interests) > 0 {
		trip.Interests = dto.Interests
	}
	if len(dto.Travelers) > 0 {
		trip.Travelers = make([]Traveler, 0, len(dto.Travelers))
		for _, t := range dto.Travelers {
			trip.Travelers = append(trip.Travelers, Traveler{ID: uuid.New(), Type: t.Type, AgeGroup: t.AgeGroup, Name: t.Name, Preferences: append([]string{}, t.Preferences...), Notes: t.Notes})
		}
	}
	trip.Status = StatusCollectingInput
	if err := s.repo.SaveTrip(trip); err != nil {
		return nil, fmt.Errorf("failed to save patched trip: %w", err)
	}
	response := s.buildPlanningTripResponse(trip)
	return &response, nil
}

func (s *CoreService) AddChatMessage(ctx context.Context, tripID uuid.UUID, dto ChatMessageDTO) (*PlanningChatResponse, error) {
	trip, session, err := s.loadTripAndSession(tripID)
	if err != nil {
		return nil, err
	}
	if trip == nil {
		return nil, nil
	}
	session.Messages = append(session.Messages, ChatMessage{ID: uuid.New(), Role: "user", Content: dto.Content, Action: dto.Action, CreatedAt: time.Now().UTC()})
	plan, err := s.planner.Plan(ctx, AIPlanningRequest{TripID: tripID, Action: normalizeAction(dto.Action, "collect_fields"), UserPrompt: dto.Content, CurrentTrip: tripToMap(trip), ChatHistory: session.Messages})
	if err != nil {
		return nil, fmt.Errorf("failed to plan chat response: %w", err)
	}
	s.applyAIFields(trip, plan)
	session.Messages = append(session.Messages, ChatMessage{ID: uuid.New(), Role: "assistant", Content: plan.AssistantSummary, Action: dto.Action, Structured: map[string]any{"missing_fields": plan.MissingFields, "vibe_labels": plan.VibeLabels}, CreatedAt: time.Now().UTC()})
	if len(plan.MissingFields) == 0 {
		trip.Status = StatusReadyForConfirmation
	} else {
		trip.Status = StatusCollectingInput
	}
	if err := s.repo.SaveTrip(trip); err != nil {
		return nil, fmt.Errorf("failed to save trip after chat: %w", err)
	}
	if err := s.repo.SaveSession(session); err != nil {
		return nil, fmt.Errorf("failed to save session after chat: %w", err)
	}
	return &PlanningChatResponse{Trip: s.buildPlanningTripResponse(trip), SessionID: session.ID, Messages: planningMessages(session.Messages), AssistantHints: append([]string{}, plan.WeatherInsights...)}, nil
}

func (s *CoreService) GetChatMessages(tripID uuid.UUID) (*PlanningChatResponse, error) {
	trip, session, err := s.loadTripAndSession(tripID)
	if err != nil {
		return nil, err
	}
	if trip == nil {
		return nil, nil
	}
	return &PlanningChatResponse{Trip: s.buildPlanningTripResponse(trip), SessionID: session.ID, Messages: planningMessages(session.Messages)}, nil
}

func (s *CoreService) ConfirmTrip(ctx context.Context, tripID uuid.UUID) (*TripDetailsResponse, error) {
	trip, session, err := s.loadTripAndSession(tripID)
	if err != nil {
		return nil, err
	}
	if trip == nil {
		return nil, nil
	}
	if len(requiredMissing(tripToMap(trip))) > 0 {
		return nil, fmt.Errorf("failed to confirm trip: required fields are still missing")
	}
	trip.Status = StatusConfirmed
	if err := s.repo.SaveTrip(trip); err != nil {
		return nil, err
	}
	return s.generateTrip(ctx, trip, session, "generate_plan")
}

func (s *CoreService) RegenerateTrip(ctx context.Context, tripID uuid.UUID) (*TripDetailsResponse, error) {
	trip, session, err := s.loadTripAndSession(tripID)
	if err != nil {
		return nil, err
	}
	if trip == nil {
		return nil, nil
	}
	return s.generateTrip(ctx, trip, session, "regenerate_plan")
}

func (s *CoreService) GetTripDetails(tripID uuid.UUID) (*TripDetailsResponse, error) {
	trip, err := s.repo.GetTrip(tripID)
	if err != nil {
		return nil, fmt.Errorf("failed to get trip: %w", err)
	}
	if trip == nil {
		return nil, nil
	}
	if trip.Status != StatusGenerated && trip.Status != StatusEdited {
		return nil, fmt.Errorf("failed to get trip details: trip is not generated yet")
	}
	data := s.buildTripDetailsResponse(trip)
	return &data, nil
}

func (s *CoreService) GetTransportOptions(tripID uuid.UUID) ([]TransportOption, error) {
	trip, err := s.repo.GetTrip(tripID)
	if err != nil || trip == nil {
		return nil, err
	}
	return trip.TransportOptions, nil
}

func (s *CoreService) SelectTransport(tripID, optionID uuid.UUID) (*TripDetailsResponse, error) {
	trip, err := s.repo.GetTrip(tripID)
	if err != nil {
		return nil, err
	}
	if trip == nil {
		return nil, nil
	}
	for i := range trip.TransportOptions {
		trip.TransportOptions[i].Selected = trip.TransportOptions[i].ID == optionID
		if trip.TransportOptions[i].Selected {
			selected := trip.TransportOptions[i]
			trip.SelectedTransport = &selected
		}
	}
	s.recalculateBudget(trip)
	trip.Status = StatusEdited
	if err := s.repo.SaveTrip(trip); err != nil {
		return nil, err
	}
	response := s.buildTripDetailsResponse(trip)
	return &response, nil
}

func (s *CoreService) GetHotelOptions(tripID uuid.UUID) ([]HotelOption, error) {
	trip, err := s.repo.GetTrip(tripID)
	if err != nil || trip == nil {
		return nil, err
	}
	return trip.HotelOptions, nil
}

func (s *CoreService) SelectHotel(tripID, optionID uuid.UUID) (*TripDetailsResponse, error) {
	trip, err := s.repo.GetTrip(tripID)
	if err != nil {
		return nil, err
	}
	if trip == nil {
		return nil, nil
	}
	for i := range trip.HotelOptions {
		trip.HotelOptions[i].Selected = trip.HotelOptions[i].ID == optionID
		if trip.HotelOptions[i].Selected {
			selected := trip.HotelOptions[i]
			trip.SelectedHotel = &selected
		}
	}
	s.recalculateBudget(trip)
	trip.Status = StatusEdited
	if err := s.repo.SaveTrip(trip); err != nil {
		return nil, err
	}
	response := s.buildTripDetailsResponse(trip)
	return &response, nil
}

func (s *CoreService) AddActivity(tripID uuid.UUID, dto ManualActivityDTO) (*TripDetailsResponse, error) {
	trip, err := s.repo.GetTrip(tripID)
	if err != nil {
		return nil, err
	}
	if trip == nil {
		return nil, nil
	}
	trip.Activities = append(trip.Activities, ActivityItem{ID: uuid.New(), Kind: dto.Kind, Title: dto.Title, Location: dto.Location, DayLabel: dto.DayLabel, Price: dto.Price, Currency: "KZT", SourceName: dto.SourceName, SourceLink: dto.SourceLink, ManuallyAdded: true, Description: dto.Description})
	trip.Status = StatusEdited
	s.rebuildTodoSections(trip)
	s.recalculateBudget(trip)
	if err := s.repo.SaveTrip(trip); err != nil {
		return nil, err
	}
	response := s.buildTripDetailsResponse(trip)
	return &response, nil
}

func (s *CoreService) GetBudget(tripID uuid.UUID) (*BudgetBreakdown, error) {
	trip, err := s.repo.GetTrip(tripID)
	if err != nil || trip == nil {
		return nil, err
	}
	response := buildBudgetBreakdown(trip)
	return &response, nil
}

func (s *CoreService) GetVisa(tripID uuid.UUID) (*VisaInfo, error) {
	trip, err := s.repo.GetTrip(tripID)
	if err != nil || trip == nil {
		return nil, err
	}
	response := buildVisaInfo(trip)
	return &response, nil
}

func (s *CoreService) GetReviews(tripID uuid.UUID) ([]ReviewSummary, error) {
	trip, err := s.repo.GetTrip(tripID)
	if err != nil || trip == nil {
		return nil, err
	}
	return trip.ReviewSummaries, nil
}

func (s *CoreService) GetProfile() *UserProfileResponse {
	return &UserProfileResponse{
		UserID:            "halyk-user-001",
		Citizenship:       "Kazakhstan",
		HomeCity:          "Almaty",
		HomeAirport:       "ALA",
		Currency:          "KZT",
		PreferredLanguage: "en",
		TravelProfile: TravelProfile{
			BudgetLevel:             "balanced",
			TravelFrequency:         "medium",
			PreferredTripLengthDays: 5,
			PreferredCategories:     []string{"culture", "food", "family"},
			AvoidCategories:         []string{"nightlife"},
			HotelPreference:         "balanced_location_price",
			TransportPreference:     "mixed",
		},
	}
}

func (s *CoreService) GetRecommendations() *RecommendationsResponse {
	createdAt := time.Now().UTC().Format(time.RFC3339)
	if recommendations, err := s.repo.ListRecommendationSeeds(); err == nil && len(recommendations) > 0 {
		return &RecommendationsResponse{UserID: "halyk-user-001", GeneratedAt: createdAt, SelectedMode: "balanced", Recommendations: recommendations}
	}

	recommendations := fallbackRecommendations()
	return &RecommendationsResponse{UserID: "halyk-user-001", GeneratedAt: createdAt, SelectedMode: "balanced", Recommendations: recommendations}
}

func fallbackRecommendations() []TripRecommendation {
	type seed struct {
		id          string
		name        string
		title       string
		countryCode string
		cityCodes   []string
		start       string
		end         string
		days        int
		image       string
		total       float64
		cashback    float64
		percent     float64
		reason      string
		labels      []string
		typ         string
		score       float64
	}

	seeds := []seed{
		{"rec-similar-tokyo-001", "Tokyo, Japan", "Tokyo family food and culture week", "JP", []string{"TYO"}, "2026-07-10", "2026-07-17", 8, "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf", 905000, 45250, 5.0, "Close to prior culture and food patterns with a family-safe city route.", []string{"Culture", "Food", "Family fit", "Direct path"}, "similar_to_previous", 0.97},
		{"rec-similar-kyoto-002", "Kyoto, Japan", "Kyoto temples and quiet lanes", "JP", []string{"KIX", "UKY"}, "2026-09-12", "2026-09-18", 7, "https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e", 845000, 38025, 4.5, "Matches the user preference for history, walkable days, and calm food districts.", []string{"History", "Quiet", "Walkable", "Seasonal color"}, "similar_to_previous", 0.94},
		{"rec-similar-istanbul-003", "Istanbul, Turkey", "Istanbul markets and Bosphorus food route", "TR", []string{"IST"}, "2026-06-12", "2026-06-16", 5, "https://images.unsplash.com/photo-1524231757912-21f4fe3a7200", 742000, 31500, 4.2, "Visa-free, direct flight from Almaty, strong food and history match.", []string{"Visa-free", "Food match", "History", "Cashback boost"}, "similar_to_previous", 0.92},
		{"rec-similar-tbilisi-004", "Tbilisi, Georgia", "Tbilisi old town and wine route", "GE", []string{"TBS"}, "2026-06-20", "2026-06-24", 5, "https://images.unsplash.com/photo-1565008576549-57569a49371d", 586000, 18000, 3.0, "Short flight, familiar cuisine, and easy old town walking days.", []string{"Budget friendly", "Food", "Mountains", "Old town"}, "similar_to_previous", 0.89},
		{"rec-similar-almaty-005", "Almaty, Kazakhstan", "Almaty mountain reset weekend", "KZ", []string{"ALA"}, "2026-06-27", "2026-06-29", 3, "https://images.unsplash.com/photo-1596367407372-5af9a8b8d67e", 180000, 5500, 3.0, "No visa, no flight stress, and a strong mountain-and-food fit.", []string{"No visa", "Mountains", "Weekend getaway", "Food"}, "similar_to_previous", 0.86},
		{"rec-new-dubai-001", "Dubai, UAE", "Dubai beach, shopping and desert contrast", "AE", []string{"DXB"}, "2026-07-04", "2026-07-09", 6, "https://images.unsplash.com/photo-1512453979798-5ea266f8880c", 890000, 32000, 3.5, "A brighter luxury-and-desert style that contrasts with prior city history trips.", []string{"Beach", "Shopping", "Desert", "New style"}, "opposite_to_previous", 0.95},
		{"rec-new-baku-002", "Baku, Azerbaijan", "Baku Caspian design and old city break", "AZ", []string{"GYD"}, "2026-08-08", "2026-08-13", 6, "https://images.unsplash.com/photo-1581007341315-6d53c1f9f7fb", 640000, 22400, 3.5, "Mixes seaside walks, modern architecture, and old city streets in a new pattern.", []string{"Sea", "Architecture", "Old city", "Direct flight"}, "opposite_to_previous", 0.91},
		{"rec-new-batumi-003", "Batumi, Georgia", "Batumi Black Sea family coast", "GE", []string{"BUS"}, "2026-08-15", "2026-08-20", 6, "https://images.unsplash.com/photo-1565008576549-57569a49371d", 520000, 15600, 3.0, "A sea-first option for a user whose profile is usually city and culture led.", []string{"Sea", "Family", "Budget friendly", "Relaxed"}, "opposite_to_previous", 0.88},
		{"rec-new-doha-004", "Doha, Qatar", "Doha museums, souq and warm winter sun", "QA", []string{"DOH"}, "2026-11-05", "2026-11-10", 6, "https://images.unsplash.com/photo-1629126791508-92c68ba0e8d2", 820000, 28700, 3.5, "A polished Gulf city route with a different climate, pace, and museum style.", []string{"Museums", "Warm weather", "Souq", "New style"}, "opposite_to_previous", 0.85},
		{"rec-new-seoul-005", "Seoul, South Korea", "Seoul pop culture and palaces route", "KR", []string{"SEL"}, "2026-10-03", "2026-10-09", 7, "https://images.unsplash.com/photo-1538485399081-7191377e8241", 965000, 38600, 4.0, "Adds a trendier city-energy route with shopping, media culture, and palace walks.", []string{"Shopping", "Culture", "Food", "City energy"}, "opposite_to_previous", 0.82},
		{"rec-seasonal-sapporo-001", "Sapporo, Japan", "Sapporo snow festival and winter food", "JP", []string{"CTS"}, "2026-02-05", "2026-02-11", 7, "https://images.unsplash.com/photo-1516563670759-299070f0dc54", 930000, 37200, 4.0, "Timed around winter festival energy, snow scenery, and regional comfort food.", []string{"Seasonal", "Winter", "Food", "Festival"}, "seasonal", 0.96},
		{"rec-seasonal-munich-002", "Munich, Germany", "Munich autumn parks and museum week", "DE", []string{"MUC"}, "2026-09-19", "2026-09-25", 7, "https://images.unsplash.com/photo-1595867818082-083862f3d630", 870000, 34800, 4.0, "Autumn timing fits parks, museums, and calmer family city days.", []string{"Seasonal", "Autumn", "Museums", "Parks"}, "seasonal", 0.92},
		{"rec-seasonal-astana-003", "Astana, Kazakhstan", "Astana summer architecture weekend", "KZ", []string{"NQZ"}, "2026-07-18", "2026-07-21", 4, "https://images.unsplash.com/photo-1577086664693-894d8405334a", 240000, 7200, 3.0, "Best in warmer months for river walks, modern architecture, and short domestic travel.", []string{"Seasonal", "Weekend", "No visa", "Architecture"}, "seasonal", 0.88},
		{"rec-event-berlin-004", "Berlin, Germany", "Berlin summer museums and open-air events", "DE", []string{"BER"}, "2026-08-01", "2026-08-07", 7, "https://images.unsplash.com/photo-1560969184-10fe8719e047", 835000, 33400, 4.0, "Event-friendly summer timing with museums, public squares, and evening culture.", []string{"Events", "Museums", "Summer", "Culture"}, "event_based", 0.85},
		{"rec-event-almaty-005", "Almaty, Kazakhstan", "Almaty concerts and mountain day plan", "KZ", []string{"ALA"}, "2026-08-22", "2026-08-25", 4, "https://images.unsplash.com/photo-1596367407372-5af9a8b8d67e", 220000, 8800, 4.0, "Combines likely city events with an easy mountain day for a timely local plan.", []string{"Events", "Mountains", "No visa", "Weekend"}, "event_based", 0.82},
	}

	recommendations := make([]TripRecommendation, 0, len(seeds))
	for _, item := range seeds {
		recommendations = append(recommendations, TripRecommendation{
			TripID:             item.id,
			DestinationName:    item.name,
			DestinationTitle:   item.title,
			CountryCode:        item.countryCode,
			CityCodes:          item.cityCodes,
			StartDate:          item.start,
			EndDate:            item.end,
			DurationDays:       item.days,
			ImageURL:           item.image,
			EstimatedTotalCost: EstimatedMoney{Amount: item.total, Currency: "KZT", Confidence: "medium"},
			CashbackEstimate:   &CashbackEstimate{Amount: item.cashback, Currency: "KZT", Percent: item.percent},
			MainReason:         item.reason,
			ReasonLabels:       item.labels,
			RecommendationType: item.typ,
			Score:              item.score,
		})
	}
	return recommendations
}

func (s *CoreService) GetHotelDetails(hotelID string) (*HotelDetailsFull, error) {
	trip, err := s.repo.FindTripByHotelID(hotelID)
	if err != nil {
		return nil, fmt.Errorf("failed to find hotel details: %w", err)
	}
	if trip == nil {
		trip = &TripState{DestinationCountry: "Japan", DestinationCity: "Tokyo", StartDate: "2026-07-10", EndDate: "2026-07-17"}
		ref := fallbackDestinationReference("Japan", "Tokyo")
		trip.HotelOptions = hotelOptionsFromReference(ref)
		trip.SelectedHotel = &trip.HotelOptions[0]
		trip.ReviewSummaries = reviewSummariesFromReference(ref)
	}
	response := buildHotelDetailsFull(trip, hotelID)
	return &response, nil
}

func (s *CoreService) generateTrip(ctx context.Context, trip *TripState, session *ChatSession, action string) (*TripDetailsResponse, error) {
	plan, err := s.planner.Plan(ctx, AIPlanningRequest{TripID: trip.ID, Action: action, CurrentTrip: tripToMap(trip), ChatHistory: session.Messages})
	if err != nil {
		return nil, fmt.Errorf("failed to generate trip: %w", err)
	}
	s.applyAIFields(trip, plan)
	s.enrichTripFromSeed(trip)
	trip.Status = StatusGenerated
	session.Messages = append(session.Messages, ChatMessage{ID: uuid.New(), Role: "assistant", Content: plan.AssistantSummary, Action: action, CreatedAt: time.Now().UTC()})
	if err := s.repo.SaveTrip(trip); err != nil {
		return nil, err
	}
	if err := s.repo.SaveSession(session); err != nil {
		return nil, err
	}
	response := s.buildTripDetailsResponse(trip)
	return &response, nil
}

func (s *CoreService) loadTripAndSession(tripID uuid.UUID) (*TripState, *ChatSession, error) {
	trip, err := s.repo.GetTrip(tripID)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to get trip: %w", err)
	}
	if trip == nil {
		return nil, nil, nil
	}
	session, err := s.repo.GetSessionByTripID(tripID)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to get session: %w", err)
	}
	if session == nil {
		return nil, nil, fmt.Errorf("failed to get session: session missing")
	}
	return trip, session, nil
}

type HTTPPlannerClient struct {
	baseURL  string
	client   *http.Client
	fallback PlannerClient
}

type agentParseTripRequest struct {
	Text string `json:"text"`
}

type agentParseTripResponse struct {
	Parsed struct {
		Country       string `json:"country"`
		DepartureDate string `json:"departure_date"`
		ArrivalDate   string `json:"arrival_date"`
		City          string `json:"city"`
		Theme         string `json:"theme"`
		Cost          int    `json:"cost"`
		PeopleCount   int    `json:"people_count"`
	} `json:"parsed"`
	RawText string `json:"raw_text"`
}

func NewPlannerClient(cfg *config.Config) PlannerClient {
	fallback := &LocalPlannerClient{}
	if cfg != nil && strings.TrimSpace(cfg.AIAgent.URL) != "" {
		return &HTTPPlannerClient{baseURL: strings.TrimRight(cfg.AIAgent.URL, "/"), client: &http.Client{Timeout: 15 * time.Second}, fallback: fallback}
	}
	return fallback
}

func (c *HTTPPlannerClient) Plan(ctx context.Context, req AIPlanningRequest) (*AIPlanningResponse, error) {
	response, err := c.parseTrip(ctx, req)
	if err != nil {
		return c.fallback.Plan(ctx, req)
	}
	return buildAIPlanningResponse(req, response), nil
}

func (c *HTTPPlannerClient) parseTrip(ctx context.Context, req AIPlanningRequest) (*agentParseTripResponse, error) {
	body, err := json.Marshal(agentParseTripRequest{Text: buildAgentPrompt(req)})
	if err != nil {
		return nil, fmt.Errorf("marshal parse-trip request: %w", err)
	}
	for _, endpoint := range []string{"/parse-trip", "/parser-trip"} {
		httpReq, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+endpoint, bytes.NewReader(body))
		if err != nil {
			return nil, fmt.Errorf("create parse-trip request: %w", err)
		}
		httpReq.Header.Set("Content-Type", "application/json")
		resp, err := c.client.Do(httpReq)
		if err != nil {
			continue
		}
		var parsed agentParseTripResponse
		decodeErr := json.NewDecoder(resp.Body).Decode(&parsed)
		resp.Body.Close()
		if resp.StatusCode >= 400 || decodeErr != nil {
			continue
		}
		return &parsed, nil
	}
	return nil, fmt.Errorf("agent parse-trip endpoints unavailable")
}

type LocalPlannerClient struct{}

func (c *LocalPlannerClient) Plan(_ context.Context, req AIPlanningRequest) (*AIPlanningResponse, error) {
	prompt := strings.ToLower(req.UserPrompt)
	startDate, endDate := inferPromptDates(prompt)
	normalized := map[string]any{
		"origin_city":         stringValue(req.CurrentTrip["origin_city"], inferOriginCity(prompt)),
		"destination_country": stringValue(req.CurrentTrip["destination_country"], inferCountry(prompt)),
		"destination_city":    stringValue(req.CurrentTrip["destination_city"], inferCity(prompt)),
		"start_date":          stringValue(req.CurrentTrip["start_date"], startDate),
		"end_date":            stringValue(req.CurrentTrip["end_date"], endDate),
		"transport_type":      stringValue(req.CurrentTrip["transport_type"], inferTransport(prompt)),
		"trip_purpose":        stringValue(req.CurrentTrip["trip_purpose"], inferPurpose(prompt)),
		"citizenship":         stringValue(req.CurrentTrip["citizenship"], inferCitizenship(prompt)),
		"budget":              intValue(req.CurrentTrip["budget"], inferExplicitBudget(prompt)),
	}
	country := stringValue(normalized["destination_country"], "")
	return &AIPlanningResponse{
		MissingFields:    requiredMissing(normalized),
		NormalizedFields: normalized,
		VibeLabels:       buildVibeLabels(prompt, normalized["trip_purpose"].(string), ""),
		VisaInsights:     legacyVisaInsightsForCountry(country),
		WeatherInsights:  weatherInsightsForCountry(country),
		ReviewSummaries:  reviewSummariesForCountry(country),
		AssistantSummary: assistantSummaryForPlan(normalized, normalized["trip_purpose"].(string)),
	}, nil
}
