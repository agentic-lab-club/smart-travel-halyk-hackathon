package tripdetails

import (
	"github.com/gofiber/fiber/v3"
	"github.com/google/uuid"

	respond "github.com/agentic-lab-club/smart-travel-halyk-hackathon/backend/pkg/http/responder"
)

type Handler struct {
	service *Service
}

func NewHandler(service *Service) *Handler {
	return &Handler{service: service}
}

// GetTrip godoc
// @Summary Get generated trip details
// @Description Returns the final mobile-ready trip bundle for a generated trip.
// @Tags @tripdetails
// @Produce json
// @Param tripId path string true "Trip ID"
// @Success 200 {object} TripDetailsResponse
// @Failure 404 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/trips/{tripId} [get]
func (h *Handler) GetTrip(c fiber.Ctx) error {
	data, err := h.service.GetTrip(c.Locals("tripId").(uuid.UUID))
	return tripDetails(c, data, err)
}

// GetTransportOptions godoc
// @Summary Get transport options
// @Description Returns selected and alternative transport options for a generated trip.
// @Tags @tripdetails
// @Produce json
// @Param tripId path string true "Trip ID"
// @Success 200 {array} TransportOption
// @Failure 404 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/trips/{tripId}/options/transport [get]
func (h *Handler) GetTransportOptions(c fiber.Ctx) error {
	data, err := h.service.GetTransportOptions(c.Locals("tripId").(uuid.UUID))
	if err != nil {
		return respond.ErrorStatus(c, err, fiber.StatusInternalServerError)
	}
	if data == nil {
		return respond.WithStatus(c, fiber.Map{"error": "not found"}, nil, fiber.StatusNotFound)
	}
	return respond.OK(c, data, nil)
}

// SelectTransport godoc
// @Summary Select transport option
// @Description Updates the generated trip using a different transport option.
// @Tags @tripdetails
// @Produce json
// @Param tripId path string true "Trip ID"
// @Param optionId path string true "Transport option ID"
// @Success 200 {object} TripDetailsResponse
// @Failure 404 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/trips/{tripId}/options/transport/{optionId}/select [post]
func (h *Handler) SelectTransport(c fiber.Ctx) error {
	data, err := h.service.SelectTransport(c.Locals("tripId").(uuid.UUID), c.Locals("optionId").(uuid.UUID))
	return tripDetails(c, data, err)
}

// GetHotelOptions godoc
// @Summary Get hotel options
// @Description Returns selected and alternative hotel options for a generated trip.
// @Tags @tripdetails
// @Produce json
// @Param tripId path string true "Trip ID"
// @Success 200 {array} HotelOption
// @Failure 404 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/trips/{tripId}/options/hotels [get]
func (h *Handler) GetHotelOptions(c fiber.Ctx) error {
	data, err := h.service.GetHotelOptions(c.Locals("tripId").(uuid.UUID))
	if err != nil {
		return respond.ErrorStatus(c, err, fiber.StatusInternalServerError)
	}
	if data == nil {
		return respond.WithStatus(c, fiber.Map{"error": "not found"}, nil, fiber.StatusNotFound)
	}
	return respond.OK(c, data, nil)
}

// SelectHotel godoc
// @Summary Select hotel option
// @Description Updates the generated trip using a different hotel option.
// @Tags @tripdetails
// @Produce json
// @Param tripId path string true "Trip ID"
// @Param optionId path string true "Hotel option ID"
// @Success 200 {object} TripDetailsResponse
// @Failure 404 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/trips/{tripId}/options/hotels/{optionId}/select [post]
func (h *Handler) SelectHotel(c fiber.Ctx) error {
	data, err := h.service.SelectHotel(c.Locals("tripId").(uuid.UUID), c.Locals("optionId").(uuid.UUID))
	return tripDetails(c, data, err)
}

// AddActivity godoc
// @Summary Add activity manually
// @Description Adds a new manual activity into the generated trip bundle.
// @Tags @tripdetails
// @Accept json
// @Produce json
// @Param tripId path string true "Trip ID"
// @Param request body ManualActivityDTO true "Manual activity payload"
// @Success 200 {object} TripDetailsResponse
// @Failure 400 {object} map[string]interface{}
// @Failure 404 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/trips/{tripId}/activities [post]
func (h *Handler) AddActivity(c fiber.Ctx) error {
	data, err := h.service.AddActivity(c.Locals("tripId").(uuid.UUID), c.Locals("body").(ManualActivityDTO))
	return tripDetails(c, data, err)
}

// GetBudget godoc
// @Summary Get budget breakdown
// @Description Returns the budget breakdown in mobile contract format.
// @Tags @tripdetails
// @Produce json
// @Param tripId path string true "Trip ID"
// @Success 200 {object} BudgetBreakdown
// @Failure 404 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/trips/{tripId}/budget [get]
func (h *Handler) GetBudget(c fiber.Ctx) error {
	data, err := h.service.GetBudget(c.Locals("tripId").(uuid.UUID))
	if err != nil {
		return respond.ErrorStatus(c, err, fiber.StatusInternalServerError)
	}
	if data == nil {
		return respond.WithStatus(c, fiber.Map{"error": "not found"}, nil, fiber.StatusNotFound)
	}
	return respond.OK(c, data, nil)
}

// GetVisa godoc
// @Summary Get visa summary
// @Description Returns the trip visa summary in mobile contract format.
// @Tags @tripdetails
// @Produce json
// @Param tripId path string true "Trip ID"
// @Success 200 {object} VisaInfo
// @Failure 404 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/trips/{tripId}/visa [get]
func (h *Handler) GetVisa(c fiber.Ctx) error {
	data, err := h.service.GetVisa(c.Locals("tripId").(uuid.UUID))
	if err != nil {
		return respond.ErrorStatus(c, err, fiber.StatusInternalServerError)
	}
	if data == nil {
		return respond.WithStatus(c, fiber.Map{"error": "not found"}, nil, fiber.StatusNotFound)
	}
	return respond.OK(c, data, nil)
}

// GetReviews godoc
// @Summary Get review summaries
// @Description Returns lightweight review summaries linked to the trip bundle.
// @Tags @tripdetails
// @Produce json
// @Param tripId path string true "Trip ID"
// @Success 200 {array} ReviewSummary
// @Failure 404 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/trips/{tripId}/reviews [get]
func (h *Handler) GetReviews(c fiber.Ctx) error {
	data, err := h.service.GetReviews(c.Locals("tripId").(uuid.UUID))
	if err != nil {
		return respond.ErrorStatus(c, err, fiber.StatusInternalServerError)
	}
	if data == nil {
		return respond.WithStatus(c, fiber.Map{"error": "not found"}, nil, fiber.StatusNotFound)
	}
	return respond.OK(c, data, nil)
}

func tripDetails(c fiber.Ctx, data *TripDetailsResponse, err error) error {
	if err != nil {
		return respond.ErrorStatus(c, err, fiber.StatusInternalServerError)
	}
	if data == nil {
		return respond.WithStatus(c, fiber.Map{"error": "not found"}, nil, fiber.StatusNotFound)
	}
	return respond.OK(c, data, nil)
}
