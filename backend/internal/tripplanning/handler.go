package tripplanning

import (
	"github.com/gofiber/fiber/v3"
	"github.com/google/uuid"
	"github.com/rs/zerolog"

	respond "github.com/agentic-lab-club/smart-travel-halyk-hackathon/backend/pkg/http/responder"
)

type Handler struct {
	service *Service
}

func NewHandler(service *Service) *Handler {
	return &Handler{service: service}
}

// CreateTrip godoc
// @Summary Create trip draft
// @Description Creates a new trip draft and returns planning-state JSON for mobile.
// @Tags @tripplanning
// @Accept json
// @Produce json
// @Param request body CreateTripDTO true "Trip draft payload"
// @Success 201 {object} PlanningTripResponse
// @Failure 400 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/trips [post]
func (h *Handler) CreateTrip(c fiber.Ctx) error {
	c.Locals("log").(*zerolog.Logger).Info().Str("event", "tripplanning_create_start").Msg("Create planning trip started")
	data, err := h.service.CreateTrip(c.Context(), c.Locals("body").(CreateTripDTO))
	if err != nil {
		return respond.ErrorStatus(c, err, fiber.StatusInternalServerError)
	}
	return respond.Created(c, data, nil)
}

// GetPlanningTrip godoc
// @Summary Get planning state
// @Description Returns current draft, normalized fields, and missing fields for a trip.
// @Tags @tripplanning
// @Produce json
// @Param tripId path string true "Trip ID"
// @Success 200 {object} PlanningTripResponse
// @Failure 404 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/trips/{tripId}/planning [get]
func (h *Handler) GetPlanningTrip(c fiber.Ctx) error {
	data, err := h.service.GetPlanningTrip(c.Locals("tripId").(uuid.UUID))
	return planningTrip(c, data, err)
}

// PatchTrip godoc
// @Summary Patch planning fields
// @Description Updates normalized planning fields before final confirmation.
// @Tags @tripplanning
// @Accept json
// @Produce json
// @Param tripId path string true "Trip ID"
// @Param request body PatchTripDTO true "Trip patch payload"
// @Success 200 {object} PlanningTripResponse
// @Failure 400 {object} map[string]interface{}
// @Failure 404 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/trips/{tripId} [patch]
func (h *Handler) PatchTrip(c fiber.Ctx) error {
	data, err := h.service.PatchTrip(c.Locals("tripId").(uuid.UUID), c.Locals("body").(PatchTripDTO))
	return planningTrip(c, data, err)
}

// AddChatMessage godoc
// @Summary Send planning chat message
// @Description Sends a planning prompt or missing-field answer and returns updated planning chat state.
// @Tags @tripplanning
// @Accept json
// @Produce json
// @Param tripId path string true "Trip ID"
// @Param request body ChatMessageDTO true "Chat message payload"
// @Success 200 {object} PlanningChatResponse
// @Failure 400 {object} map[string]interface{}
// @Failure 404 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/trips/{tripId}/chat/messages [post]
func (h *Handler) AddChatMessage(c fiber.Ctx) error {
	data, err := h.service.AddChatMessage(c.Context(), c.Locals("tripId").(uuid.UUID), c.Locals("body").(ChatMessageDTO))
	if err != nil {
		return respond.ErrorStatus(c, err, fiber.StatusInternalServerError)
	}
	if data == nil {
		return respond.WithStatus(c, fiber.Map{"error": "not found"}, nil, fiber.StatusNotFound)
	}
	return respond.OK(c, data, nil)
}

// GetChatMessages godoc
// @Summary Get planning chat history
// @Description Returns planning chat history together with the current planning state.
// @Tags @tripplanning
// @Produce json
// @Param tripId path string true "Trip ID"
// @Success 200 {object} PlanningChatResponse
// @Failure 404 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/trips/{tripId}/chat/messages [get]
func (h *Handler) GetChatMessages(c fiber.Ctx) error {
	data, err := h.service.GetChatMessages(c.Locals("tripId").(uuid.UUID))
	if err != nil {
		return respond.ErrorStatus(c, err, fiber.StatusInternalServerError)
	}
	if data == nil {
		return respond.WithStatus(c, fiber.Map{"error": "not found"}, nil, fiber.StatusNotFound)
	}
	return respond.OK(c, data, nil)
}

// ConfirmTrip godoc
// @Summary Confirm trip and generate final bundle
// @Description Confirms collected fields and returns the generated mobile-ready trip bundle.
// @Tags @tripplanning
// @Produce json
// @Param tripId path string true "Trip ID"
// @Success 200 {object} TripDetailsResponse
// @Failure 404 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/trips/{tripId}/confirm [post]
func (h *Handler) ConfirmTrip(c fiber.Ctx) error {
	data, err := h.service.ConfirmTrip(c.Context(), c.Locals("tripId").(uuid.UUID))
	return tripDetails(c, data, err)
}

// RegenerateTrip godoc
// @Summary Regenerate final trip bundle
// @Description Rebuilds the final trip bundle from the current confirmed planning state.
// @Tags @tripplanning
// @Produce json
// @Param tripId path string true "Trip ID"
// @Success 200 {object} TripDetailsResponse
// @Failure 404 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/trips/{tripId}/regenerate [post]
func (h *Handler) RegenerateTrip(c fiber.Ctx) error {
	data, err := h.service.RegenerateTrip(c.Context(), c.Locals("tripId").(uuid.UUID))
	return tripDetails(c, data, err)
}

func planningTrip(c fiber.Ctx, data *PlanningTripResponse, err error) error {
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
