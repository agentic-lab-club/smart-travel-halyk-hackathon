package trip

import (
	"context"
	"fmt"
	"strings"
	"time"

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
