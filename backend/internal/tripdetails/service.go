package tripdetails

import (
	"github.com/agentic-lab-club/smart-travel-halyk-hackathon/backend/pkg/travelcore"
	"github.com/google/uuid"
)

type Service struct {
	core *travelcore.CoreService
}

func NewService(core *travelcore.CoreService) *Service {
	return &Service{core: core}
}

func (s *Service) GetTrip(tripID uuid.UUID) (*TripDetailsResponse, error) {
	return s.core.GetTripDetails(tripID)
}

func (s *Service) GetTransportOptions(tripID uuid.UUID) ([]TransportOption, error) {
	return s.core.GetTransportOptions(tripID)
}

func (s *Service) SelectTransport(tripID, optionID uuid.UUID) (*TripDetailsResponse, error) {
	return s.core.SelectTransport(tripID, optionID)
}

func (s *Service) GetHotelOptions(tripID uuid.UUID) ([]HotelOption, error) {
	return s.core.GetHotelOptions(tripID)
}

func (s *Service) SelectHotel(tripID, optionID uuid.UUID) (*TripDetailsResponse, error) {
	return s.core.SelectHotel(tripID, optionID)
}

func (s *Service) AddActivity(tripID uuid.UUID, dto ManualActivityDTO) (*TripDetailsResponse, error) {
	return s.core.AddActivity(tripID, dto)
}

func (s *Service) GetBudget(tripID uuid.UUID) (*BudgetBreakdown, error) {
	return s.core.GetBudget(tripID)
}

func (s *Service) GetVisa(tripID uuid.UUID) (*VisaInfo, error) {
	return s.core.GetVisa(tripID)
}

func (s *Service) GetReviews(tripID uuid.UUID) ([]ReviewSummary, error) {
	return s.core.GetReviews(tripID)
}
