package recommendations

import (
	"github.com/gofiber/fiber/v3"

	respond "github.com/agentic-lab-club/smart-travel-halyk-hackathon/backend/pkg/http/responder"
)

type Handler struct {
	service *Service
}

func NewHandler(service *Service) *Handler {
	return &Handler{service: service}
}

// GetRecommendations godoc
// @Summary Get recommendations
// @Description Returns recommendation cards formatted for the mobile entry flow.
// @Tags @recommendations
// @Produce json
// @Success 200 {object} RecommendationsResponse
// @Router /api/v1/recommendations [get]
func (h *Handler) GetRecommendations(c fiber.Ctx) error {
	return respond.OK(c, h.service.GetRecommendations(), nil)
}
