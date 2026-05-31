package hoteldetails

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

// GetHotelDetails godoc
// @Summary Get hotel details
// @Description Returns the full hotel details model expected by mobile.
// @Tags @hoteldetails
// @Produce json
// @Param hotelId path string true "Hotel ID"
// @Success 200 {object} HotelDetailsFull
// @Failure 404 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/hotels/{hotelId} [get]
func (h *Handler) GetHotelDetails(c fiber.Ctx) error {
	data, err := h.service.GetHotelDetails(c.Params("hotelId"))
	if err != nil {
		return respond.ErrorStatus(c, err, fiber.StatusInternalServerError)
	}
	if data == nil {
		return respond.WithStatus(c, fiber.Map{"error": "not found"}, nil, fiber.StatusNotFound)
	}
	return respond.OK(c, data, nil)
}
