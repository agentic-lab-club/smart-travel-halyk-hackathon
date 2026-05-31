package recommendations

import "github.com/agentic-lab-club/smart-travel-halyk-hackathon/backend/pkg/travelcore"

type Service struct {
	core *travelcore.CoreService
}

func NewService(core *travelcore.CoreService) *Service {
	return &Service{core: core}
}

func (s *Service) GetRecommendations() *RecommendationsResponse {
	return s.core.GetRecommendations()
}
