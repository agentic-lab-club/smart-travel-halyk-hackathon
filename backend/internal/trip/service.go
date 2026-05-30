package trip

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/agentic-lab-club/smart-travel-halyk-hackathon/backend/internal/seeder"
	"github.com/agentic-lab-club/smart-travel-halyk-hackathon/backend/pkg/config"
	"github.com/google/uuid"
)

type Service struct {
	repo    *Repository
	planner PlannerClient
	cfg     *config.Config
}

func NewService(repo *Repository, planner PlannerClient, cfg *config.Config) *Service {
	return &Service{repo: repo, planner: planner, cfg: cfg}
}

func (s *Service) CreateTrip(dto CreateTripDTO) (*TripDetailsResponse, error) {
	trip, err := s.repo.CreateTrip(dto.Title)
	if err != nil {
		return nil, fmt.Errorf("failed to create trip: %w", err)
	}
	return s.buildDetails(trip), nil
}

func (s *Service) GetTrip(tripID uuid.UUID) (*TripDetailsResponse, error) {
	trip, err := s.repo.GetTrip(tripID)
	if err != nil {
		return nil, fmt.Errorf("failed to get trip: %w", err)
	}
	if trip == nil {
		return nil, nil
	}
	return s.buildDetails(trip), nil
}

func (s *Service) PatchTrip(tripID uuid.UUID, dto PatchTripDTO) (*TripDetailsResponse, error) {
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
		trip.DestinationCountry = dto.DestinationCountry
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
			trip.Travelers = append(trip.Travelers, Traveler{
				ID:          uuid.New(),
				Type:        t.Type,
				AgeGroup:    t.AgeGroup,
				Name:        t.Name,
				Preferences: append([]string{}, t.Preferences...),
				Notes:       t.Notes,
			})
		}
	}
	trip.Status = StatusCollectingInput
	if err := s.repo.SaveTrip(trip); err != nil {
		return nil, fmt.Errorf("failed to save patched trip: %w", err)
	}
	return s.buildDetails(trip), nil
}

func (s *Service) AddChatMessage(ctx context.Context, tripID uuid.UUID, dto ChatMessageDTO) (*ChatResponse, error) {
	trip, session, err := s.loadTripAndSession(tripID)
	if err != nil {
		return nil, err
	}
	if trip == nil {
		return nil, nil
	}
	session.Messages = append(session.Messages, ChatMessage{
		ID:        uuid.New(),
		Role:      "user",
		Content:   dto.Content,
		Action:    dto.Action,
		CreatedAt: time.Now().UTC(),
	})
	plan, err := s.planner.Plan(ctx, AIPlanningRequest{
		TripID:      tripID,
		Action:      normalizeAction(dto.Action, "collect_fields"),
		UserPrompt:  dto.Content,
		CurrentTrip: tripToMap(trip),
		ChatHistory: session.Messages,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to plan chat response: %w", err)
	}
	s.applyAIFields(trip, plan)
	session.Messages = append(session.Messages, ChatMessage{
		ID:      uuid.New(),
		Role:    "assistant",
		Content: plan.AssistantSummary,
		Action:  dto.Action,
		Structured: map[string]any{
			"missing_fields": plan.MissingFields,
			"vibe_labels":    plan.VibeLabels,
		},
		CreatedAt: time.Now().UTC(),
	})
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
	return &ChatResponse{
		SessionID:      session.ID,
		Messages:       session.Messages,
		MissingFields:  plan.MissingFields,
		AssistantHints: append([]string{}, plan.WeatherInsights...),
	}, nil
}

func (s *Service) GetChatMessages(tripID uuid.UUID) (*ChatResponse, error) {
	trip, session, err := s.loadTripAndSession(tripID)
	if err != nil {
		return nil, err
	}
	if trip == nil {
		return nil, nil
	}
	return &ChatResponse{SessionID: session.ID, Messages: session.Messages}, nil
}

func (s *Service) ConfirmTrip(ctx context.Context, tripID uuid.UUID) (*TripDetailsResponse, error) {
	return s.generateTrip(ctx, tripID, "generate_plan")
}

func (s *Service) RegenerateTrip(ctx context.Context, tripID uuid.UUID) (*TripDetailsResponse, error) {
	return s.generateTrip(ctx, tripID, "regenerate_plan")
}

func (s *Service) GetTransportOptions(tripID uuid.UUID) ([]TransportOption, error) {
	trip, err := s.repo.GetTrip(tripID)
	if err != nil || trip == nil {
		return nil, err
	}
	return trip.TransportOptions, nil
}

func (s *Service) SelectTransport(tripID, optionID uuid.UUID) (*TripDetailsResponse, error) {
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
	return s.buildDetails(trip), nil
}

func (s *Service) GetHotelOptions(tripID uuid.UUID) ([]HotelOption, error) {
	trip, err := s.repo.GetTrip(tripID)
	if err != nil || trip == nil {
		return nil, err
	}
	return trip.HotelOptions, nil
}

func (s *Service) SelectHotel(tripID, optionID uuid.UUID) (*TripDetailsResponse, error) {
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
	return s.buildDetails(trip), nil
}

func (s *Service) AddActivity(tripID uuid.UUID, dto ManualActivityDTO) (*TripDetailsResponse, error) {
	trip, err := s.repo.GetTrip(tripID)
	if err != nil {
		return nil, err
	}
	if trip == nil {
		return nil, nil
	}
	trip.Activities = append(trip.Activities, ActivityItem{
		ID:            uuid.New(),
		Kind:          dto.Kind,
		Title:         dto.Title,
		Location:      dto.Location,
		DayLabel:      dto.DayLabel,
		Price:         dto.Price,
		Currency:      "KZT",
		SourceName:    dto.SourceName,
		SourceLink:    dto.SourceLink,
		ManuallyAdded: true,
		Description:   dto.Description,
	})
	trip.Status = StatusEdited
	s.rebuildTodoSections(trip)
	s.recalculateBudget(trip)
	if err := s.repo.SaveTrip(trip); err != nil {
		return nil, err
	}
	return s.buildDetails(trip), nil
}

func (s *Service) GetBudget(tripID uuid.UUID) (*BudgetSummary, error) {
	trip, err := s.repo.GetTrip(tripID)
	if err != nil || trip == nil {
		return nil, err
	}
	return &trip.BudgetSummary, nil
}

func (s *Service) GetVisa(tripID uuid.UUID) (*VisaInfo, error) {
	trip, err := s.repo.GetTrip(tripID)
	if err != nil || trip == nil {
		return nil, err
	}
	return &trip.VisaInfo, nil
}

func (s *Service) GetReviews(tripID uuid.UUID) ([]ReviewSummary, error) {
	trip, err := s.repo.GetTrip(tripID)
	if err != nil || trip == nil {
		return nil, err
	}
	return trip.ReviewSummaries, nil
}

func (s *Service) generateTrip(ctx context.Context, tripID uuid.UUID, action string) (*TripDetailsResponse, error) {
	trip, session, err := s.loadTripAndSession(tripID)
	if err != nil {
		return nil, err
	}
	if trip == nil {
		return nil, nil
	}
	plan, err := s.planner.Plan(ctx, AIPlanningRequest{TripID: tripID, Action: action, CurrentTrip: tripToMap(trip), ChatHistory: session.Messages})
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
	return s.buildDetails(trip), nil
}

func (s *Service) loadTripAndSession(tripID uuid.UUID) (*Trip, *ChatSession, error) {
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

func (s *Service) buildDetails(trip *Trip) *TripDetailsResponse {
	return &TripDetailsResponse{
		Trip:              *trip,
		Travelers:         trip.Travelers,
		TodoSections:      trip.TodoSections,
		SelectedTransport: trip.SelectedTransport,
		SelectedHotel:     trip.SelectedHotel,
		Activities:        trip.Activities,
		Budget:            trip.BudgetSummary,
		Visa:              trip.VisaInfo,
		ReviewSummaries:   trip.ReviewSummaries,
		Offers:            trip.Offers,
		ChatEntrypoints:   []string{"Ask AI to refine the plan", "Ask AI about weather and season", "Ask AI why this hotel fits"},
	}
}

func (s *Service) applyAIFields(trip *Trip, plan *AIPlanningResponse) {
	if plan == nil {
		return
	}
	trip.VibeLabels = append([]string{}, plan.VibeLabels...)
	if value, ok := plan.NormalizedFields["origin_city"].(string); ok && value != "" {
		trip.OriginCity = value
	}
	if value, ok := plan.NormalizedFields["destination_country"].(string); ok && value != "" {
		trip.DestinationCountry = value
	}
	if value, ok := plan.NormalizedFields["destination_city"].(string); ok && value != "" {
		trip.DestinationCity = value
	}
	if value, ok := plan.NormalizedFields["start_date"].(string); ok && value != "" {
		trip.StartDate = value
	}
	if value, ok := plan.NormalizedFields["end_date"].(string); ok && value != "" {
		trip.EndDate = value
	}
	if value, ok := plan.NormalizedFields["transport_type"].(string); ok && value != "" {
		trip.TransportType = value
	}
	if value, ok := plan.NormalizedFields["trip_purpose"].(string); ok && value != "" {
		trip.TripPurpose = value
	}
	if value, ok := plan.NormalizedFields["citizenship"].(string); ok && value != "" {
		trip.Citizenship = value
	}
	switch value := plan.NormalizedFields["budget"].(type) {
	case int:
		if value > 0 {
			trip.Budget = value
		}
	case float64:
		if value > 0 {
			trip.Budget = int(value)
		}
	}
	if trip.Budget == 0 {
		trip.Budget = 750000
	}
	if trip.OriginCity == "" {
		trip.OriginCity = "Almaty"
	}
	if trip.DestinationCountry == "" {
		trip.DestinationCountry = "Turkey"
	}
	if trip.DestinationCity == "" {
		trip.DestinationCity = "Istanbul"
	}
	if trip.StartDate == "" {
		trip.StartDate = "2026-07-10"
	}
	if trip.EndDate == "" {
		trip.EndDate = "2026-07-17"
	}
	if trip.TransportType == "" {
		trip.TransportType = "flight"
	}
	if trip.TripPurpose == "" {
		trip.TripPurpose = "family"
	}
	if trip.Citizenship == "" {
		trip.Citizenship = "Kazakhstan"
	}
}

func (s *Service) enrichTripFromSeed(trip *Trip) {
	seed := seeder.BuildDestinationSeed(trip.DestinationCountry, trip.OriginCity, trip.TransportType)
	trip.DestinationCountry = seed.Country
	if trip.DestinationCity == "" {
		trip.DestinationCity = seed.City
	}
	trip.TransportOptions = make([]TransportOption, 0, len(seed.Transport))
	for _, option := range seed.Transport {
		trip.TransportOptions = append(trip.TransportOptions, TransportOption{
			ID:          uuid.New(),
			Mode:        option.Mode,
			Provider:    option.Provider,
			Title:       option.Title,
			Origin:      option.Origin,
			Destination: option.Destination,
			Departure:   option.Departure,
			Arrival:     option.Arrival,
			Price:       option.Price,
			Currency:    option.Currency,
			Description: option.Description,
		})
	}
	if len(trip.TransportOptions) > 0 {
		trip.TransportOptions[0].Selected = true
		selected := trip.TransportOptions[0]
		trip.SelectedTransport = &selected
	}
	trip.HotelOptions = make([]HotelOption, 0, len(seed.Hotels))
	for _, option := range seed.Hotels {
		trip.HotelOptions = append(trip.HotelOptions, HotelOption{
			ID:          uuid.New(),
			Provider:    option.Provider,
			Name:        option.Name,
			Location:    option.Location,
			Price:       option.Price,
			Currency:    option.Currency,
			Rating:      option.Rating,
			Description: option.Description,
			ReviewLink:  option.ReviewLink,
		})
	}
	if len(trip.HotelOptions) > 0 {
		trip.HotelOptions[0].Selected = true
		selected := trip.HotelOptions[0]
		trip.SelectedHotel = &selected
	}
	trip.Activities = make([]ActivityItem, 0, len(seed.Activities))
	for _, item := range seed.Activities {
		trip.Activities = append(trip.Activities, ActivityItem{
			ID:          uuid.New(),
			Kind:        item.Kind,
			Title:       item.Title,
			Location:    item.Location,
			DayLabel:    item.DayLabel,
			Price:       item.Price,
			Currency:    item.Currency,
			SourceName:  item.SourceName,
			SourceLink:  item.SourceLink,
			Description: item.Description,
		})
	}
	trip.VisaInfo = VisaInfo{
		Country:         seed.Visa.Country,
		Requirement:     seed.Visa.Requirement,
		RecommendedLead: seed.Visa.RecommendedLead,
		Checklist:       append([]string{}, seed.Visa.Checklist...),
		Notes:           seed.Visa.Notes,
	}
	trip.ReviewSummaries = make([]ReviewSummary, 0, len(seed.Reviews))
	for _, item := range seed.Reviews {
		trip.ReviewSummaries = append(trip.ReviewSummaries, ReviewSummary{
			ID:         uuid.New(),
			Kind:       item.Kind,
			TargetName: item.TargetName,
			Summary:    item.Summary,
			SourceName: item.SourceName,
			SourceLink: item.SourceLink,
		})
	}
	trip.BudgetSummary = BudgetSummary{
		TransportTotal:          selectedTransportPrice(trip),
		HotelTotal:              selectedHotelPrice(trip),
		EventsTotal:             activitiesTotal(trip.Activities),
		EstimatedFoodTotal:      seed.FoodEstimate,
		EstimatedLocalTransport: seed.LocalTransport,
		InsuranceEstimate:       seed.InsuranceEstimate,
		Currency:                "KZT",
	}
	s.recalculateBudget(trip)
	s.rebuildTodoSections(trip)
}

func (s *Service) rebuildTodoSections(trip *Trip) {
	transportItems := []TodoItem{}
	if trip.SelectedTransport != nil {
		transportItems = append(transportItems, TodoItem{ID: trip.SelectedTransport.ID, Kind: "transport", Title: trip.SelectedTransport.Title, Description: trip.SelectedTransport.Description, Status: "selected", Price: trip.SelectedTransport.Price})
	}
	hotelItems := []TodoItem{}
	if trip.SelectedHotel != nil {
		hotelItems = append(hotelItems, TodoItem{ID: trip.SelectedHotel.ID, Kind: "hotel", Title: trip.SelectedHotel.Name, Description: trip.SelectedHotel.Description, Status: "selected", Price: trip.SelectedHotel.Price, Link: trip.SelectedHotel.ReviewLink})
	}
	activityItems := make([]TodoItem, 0, len(trip.Activities))
	for _, activity := range trip.Activities {
		activityItems = append(activityItems, TodoItem{ID: activity.ID, Kind: activity.Kind, Title: activity.Title, Description: activity.Description, Status: "planned", DayLabel: activity.DayLabel, Price: activity.Price, Link: activity.SourceLink})
	}
	trip.TodoSections = []TodoSection{
		{ID: "transport", Title: "Transport", Items: transportItems},
		{ID: "hotel", Title: "Hotel", Items: hotelItems},
		{ID: "activities", Title: "Places and Events", Items: activityItems},
		{ID: "trip-info", Title: "Trip Essentials", Items: []TodoItem{{ID: uuid.New(), Kind: "visa", Title: "Visa and documents", Description: trip.VisaInfo.Requirement, Status: "check"}}},
	}
}

func (s *Service) recalculateBudget(trip *Trip) {
	trip.BudgetSummary.TransportTotal = selectedTransportPrice(trip)
	trip.BudgetSummary.HotelTotal = selectedHotelPrice(trip)
	trip.BudgetSummary.EventsTotal = activitiesTotal(trip.Activities)
	trip.BudgetSummary.GrandTotal = trip.BudgetSummary.TransportTotal + trip.BudgetSummary.HotelTotal + trip.BudgetSummary.EventsTotal + trip.BudgetSummary.EstimatedFoodTotal + trip.BudgetSummary.EstimatedLocalTransport + trip.BudgetSummary.InsuranceEstimate
	trip.BudgetSummary.CashbackAmount = int(float64(trip.BudgetSummary.GrandTotal) * 0.05)
	trip.BudgetSummary.BonusAmount = int(float64(trip.BudgetSummary.GrandTotal) * 0.02)
	trip.BudgetSummary.HalykOfferLabel = "Pay fully with Halyk mock card and unlock cashback"
	trip.Offers = OfferSummary{
		CashbackAmount: trip.BudgetSummary.CashbackAmount,
		BonusAmount:    trip.BudgetSummary.BonusAmount,
		HalykOffer:     trip.BudgetSummary.HalykOfferLabel,
		Highlights:     []string{"Mock cashback applied on full Halyk payment", "Bonus estimate included for pitch and UI", "Kino.kz suggestions included where relevant"},
	}
}

func tripToMap(trip *Trip) map[string]any {
	return map[string]any{
		"title":               trip.Title,
		"origin_city":         trip.OriginCity,
		"destination_country": trip.DestinationCountry,
		"destination_city":    trip.DestinationCity,
		"start_date":          trip.StartDate,
		"end_date":            trip.EndDate,
		"budget":              trip.Budget,
		"transport_type":      trip.TransportType,
		"trip_purpose":        trip.TripPurpose,
		"citizenship":         trip.Citizenship,
		"interests":           trip.Interests,
	}
}

func normalizeAction(value, fallback string) string {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return fallback
	}
	return trimmed
}

func selectedTransportPrice(trip *Trip) int {
	if trip.SelectedTransport == nil {
		return 0
	}
	return trip.SelectedTransport.Price
}

func selectedHotelPrice(trip *Trip) int {
	if trip.SelectedHotel == nil {
		return 0
	}
	return trip.SelectedHotel.Price
}

func activitiesTotal(items []ActivityItem) int {
	total := 0
	for _, item := range items {
		total += item.Price
	}
	return total
}
