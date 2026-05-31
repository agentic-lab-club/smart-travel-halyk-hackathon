package tripplanning

import (
	"context"

	"github.com/agentic-lab-club/smart-travel-halyk-hackathon/backend/pkg/travelcore"
	"github.com/google/uuid"
)

type Service struct {
	core *travelcore.CoreService
}

func NewService(core *travelcore.CoreService) *Service {
	return &Service{core: core}
}

func (s *Service) CreateTrip(ctx context.Context, dto CreateTripDTO) (*PlanningTripResponse, error) {
	return s.core.CreateTrip(ctx, dto)
}

func (s *Service) GetPlanningTrip(tripID uuid.UUID) (*PlanningTripResponse, error) {
	return s.core.GetPlanningTrip(tripID)
}

func (s *Service) PatchTrip(tripID uuid.UUID, dto PatchTripDTO) (*PlanningTripResponse, error) {
	return s.core.PatchTrip(tripID, dto)
}

func (s *Service) AddChatMessage(ctx context.Context, tripID uuid.UUID, dto ChatMessageDTO) (*PlanningChatResponse, error) {
	return s.core.AddChatMessage(ctx, tripID, dto)
}

func (s *Service) GetChatMessages(tripID uuid.UUID) (*PlanningChatResponse, error) {
	return s.core.GetChatMessages(tripID)
}

func (s *Service) ConfirmTrip(ctx context.Context, tripID uuid.UUID) (*TripDetailsResponse, error) {
	return s.core.ConfirmTrip(ctx, tripID)
}

func (s *Service) RegenerateTrip(ctx context.Context, tripID uuid.UUID) (*TripDetailsResponse, error) {
	return s.core.RegenerateTrip(ctx, tripID)
}
