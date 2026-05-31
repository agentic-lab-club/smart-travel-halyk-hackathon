package profile

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

// GetProfile godoc
// @Summary Get user profile
// @Description Returns the mobile personalization profile used for recommendations and planning defaults.
// @Tags @profile
// @Produce json
// @Success 200 {object} UserProfileResponse
// @Router /api/v1/user-profile [get]
func (h *Handler) GetProfile(c fiber.Ctx) error {
	return respond.OK(c, h.service.GetProfile(), nil)
}
