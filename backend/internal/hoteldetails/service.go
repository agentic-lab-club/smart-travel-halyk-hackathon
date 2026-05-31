package hoteldetails

import "github.com/agentic-lab-club/smart-travel-halyk-hackathon/backend/pkg/travelcore"

type Service struct {
	core *travelcore.CoreService
}

func NewService(core *travelcore.CoreService) *Service {
	return &Service{core: core}
}

func (s *Service) GetHotelDetails(hotelID string) (*HotelDetailsFull, error) {
	return s.core.GetHotelDetails(hotelID)
}
