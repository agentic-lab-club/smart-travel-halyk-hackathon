package trip

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
// @Description Creates a new trip draft and initializes chat session state.
// @Tags @trip
// @Accept json
// @Produce json
// @Param request body CreateTripDTO true "Trip draft payload"
// @Success 201 {object} TripDetailsResponse
// @Failure 400 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/trips [post]
func (h *Handler) CreateTrip(c fiber.Ctx) error {
	c.Locals("log").(*zerolog.Logger).Info().Str("event", "trip_create_start").Msg("Create trip started")
	dto := c.Locals("body").(CreateTripDTO)
	data, err := h.service.CreateTrip(dto)
	if err != nil {
		return respond.ErrorStatus(c, err, fiber.StatusInternalServerError)
	}
	return respond.Created(c, data, nil)
}

// GetTrip godoc
// @Summary Get trip details
// @Description Returns the aggregate trip response for dashboard rendering.
// @Tags @trip
// @Produce json
// @Param tripId path string true "Trip ID"
// @Success 200 {object} TripDetailsResponse
// @Failure 404 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/trips/{tripId} [get]
func (h *Handler) GetTrip(c fiber.Ctx) error {
	data, err := h.service.GetTrip(c.Locals("tripId").(uuid.UUID))
	return h.tripDetails(c, data, err)
}

// PatchTrip godoc
// @Summary Update trip draft fields
// @Description Updates trip-level fields collected before confirmation and generation.
// @Tags @trip
// @Accept json
// @Produce json
// @Param tripId path string true "Trip ID"
// @Param request body PatchTripDTO true "Trip patch payload"
// @Success 200 {object} TripDetailsResponse
// @Failure 400 {object} map[string]interface{}
// @Failure 404 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/trips/{tripId} [patch]
func (h *Handler) PatchTrip(c fiber.Ctx) error {
	data, err := h.service.PatchTrip(c.Locals("tripId").(uuid.UUID), c.Locals("body").(PatchTripDTO))
	return h.tripDetails(c, data, err)
}

// AddChatMessage godoc
// @Summary Send planning chat message
// @Description Adds a user message to the trip planning session and returns AI chat output.
// @Tags @trip
// @Accept json
// @Produce json
// @Param tripId path string true "Trip ID"
// @Param request body ChatMessageDTO true "Chat message payload"
// @Success 200 {object} ChatResponse
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
// @Summary Get trip chat history
// @Description Returns the current chat history attached to a trip planning session.
// @Tags @trip
// @Produce json
// @Param tripId path string true "Trip ID"
// @Success 200 {object} ChatResponse
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
// @Summary Confirm trip and generate plan
// @Description Confirms collected fields and generates the master-plan dashboard response.
// @Tags @trip
// @Produce json
// @Param tripId path string true "Trip ID"
// @Success 200 {object} TripDetailsResponse
// @Failure 404 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/trips/{tripId}/confirm [post]
func (h *Handler) ConfirmTrip(c fiber.Ctx) error {
	data, err := h.service.ConfirmTrip(c.Context(), c.Locals("tripId").(uuid.UUID))
	return h.tripDetails(c, data, err)
}

// RegenerateTrip godoc
// @Summary Regenerate trip plan
// @Description Regenerates trip details from current stored state and chat context.
// @Tags @trip
// @Produce json
// @Param tripId path string true "Trip ID"
// @Success 200 {object} TripDetailsResponse
// @Failure 404 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/trips/{tripId}/regenerate [post]
func (h *Handler) RegenerateTrip(c fiber.Ctx) error {
	data, err := h.service.RegenerateTrip(c.Context(), c.Locals("tripId").(uuid.UUID))
	return h.tripDetails(c, data, err)
}

// GetTransportOptions godoc
// @Summary Get transport options
// @Description Returns selected and alternative transport options for a trip.
// @Tags @trip
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
// @Description Replaces the currently selected transport option and recalculates budget.
// @Tags @trip
// @Produce json
// @Param tripId path string true "Trip ID"
// @Param optionId path string true "Transport option ID"
// @Success 200 {object} TripDetailsResponse
// @Failure 404 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/trips/{tripId}/options/transport/{optionId}/select [post]
func (h *Handler) SelectTransport(c fiber.Ctx) error {
	data, err := h.service.SelectTransport(c.Locals("tripId").(uuid.UUID), c.Locals("optionId").(uuid.UUID))
	return h.tripDetails(c, data, err)
}

// GetHotelOptions godoc
// @Summary Get hotel options
// @Description Returns selected and alternative hotel options for a trip.
// @Tags @trip
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
// @Description Replaces the currently selected hotel option and recalculates budget.
// @Tags @trip
// @Produce json
// @Param tripId path string true "Trip ID"
// @Param optionId path string true "Hotel option ID"
// @Success 200 {object} TripDetailsResponse
// @Failure 404 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/v1/trips/{tripId}/options/hotels/{optionId}/select [post]
func (h *Handler) SelectHotel(c fiber.Ctx) error {
	data, err := h.service.SelectHotel(c.Locals("tripId").(uuid.UUID), c.Locals("optionId").(uuid.UUID))
	return h.tripDetails(c, data, err)
}

// AddActivity godoc
// @Summary Add activity manually
// @Description Adds a place or event item to the trip and updates dashboard state.
// @Tags @trip
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
	return h.tripDetails(c, data, err)
}

// GetBudget godoc
// @Summary Get budget summary
// @Description Returns aggregate trip costs, cashback, bonus, and offer fields.
// @Tags @trip
// @Produce json
// @Param tripId path string true "Trip ID"
// @Success 200 {object} BudgetSummary
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
// @Summary Get visa info
// @Description Returns visa assistant information for the selected destination.
// @Tags @trip
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
// @Description Returns AI-produced review summaries and source links for hotels, places, and events.
// @Tags @trip
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

func (h *Handler) tripDetails(c fiber.Ctx, data *TripDetailsResponse, err error) error {
	if err != nil {
		return respond.ErrorStatus(c, err, fiber.StatusInternalServerError)
	}
	if data == nil {
		return respond.WithStatus(c, fiber.Map{"error": "not found"}, nil, fiber.StatusNotFound)
	}
	return respond.OK(c, data, nil)
}
