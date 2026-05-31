package travelcore

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"math"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/agentic-lab-club/smart-travel-halyk-hackathon/backend/pkg/config"
	"github.com/agentic-lab-club/smart-travel-halyk-hackathon/backend/pkg/database"
	"github.com/google/uuid"
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
	recommendations := []TripRecommendation{}
	type seed struct {
		country string
		title   string
		typ     string
		score   float64
		image   string
	}
	seeds := []seed{
		{country: "Japan", title: "Tokyo Family Week", typ: "similar_to_previous", score: 0.91, image: "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf"},
		{country: "Germany", title: "Berlin Smart Escape", typ: "cashback_boosted", score: 0.84, image: "https://images.unsplash.com/photo-1560969184-10fe8719e047"},
		{country: "Kazakhstan", title: "Almaty Weekend", typ: "weekend_trip", score: 0.8, image: "https://images.unsplash.com/photo-1574493620335-39f03c7f7f2d"},
	}
	createdAt := time.Now().UTC().Format(time.RFC3339)
	for idx, item := range seeds {
		ref := fallbackDestinationReference(item.country, "")
		total := estimateTripTotal(ref.CountryName)
		recommendations = append(recommendations, TripRecommendation{
			TripID:           fmt.Sprintf("rec-%d", idx+1),
			DestinationTitle: item.title,
			CountryCode:      countryCodeForCountry(ref.CountryName),
			CityCodes:        []string{strings.ToUpper(firstN(ref.CityName, 3))},
			StartDate:        "2026-07-10",
			EndDate:          "2026-07-17",
			DurationDays:     7,
			ImageURL:         item.image,
			EstimatedTotalCost: EstimatedMoney{
				Amount:     float64(total),
				Currency:   "KZT",
				Confidence: "medium",
			},
			CashbackEstimate:   &CashbackEstimate{Amount: math.Round(float64(total) * 0.05), Currency: "KZT", Percent: 5},
			MainReason:         "Pre-assembled recommendation based on travel profile, cost fit, and destination style.",
			ReasonLabels:       []string{"Direct path", "Family fit", "Smart cashback"},
			RecommendationType: item.typ,
			Score:              item.score,
		})
	}
	return &RecommendationsResponse{UserID: "halyk-user-001", GeneratedAt: createdAt, SelectedMode: "balanced", Recommendations: recommendations}
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
