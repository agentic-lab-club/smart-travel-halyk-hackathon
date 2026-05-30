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

func (h *Handler) CreateTrip(c fiber.Ctx) error {
	c.Locals("log").(*zerolog.Logger).Info().Str("event", "trip_create_start").Msg("Create trip started")
	dto := c.Locals("body").(CreateTripDTO)
	data, err := h.service.CreateTrip(dto)
	if err != nil {
		return respond.ErrorStatus(c, err, fiber.StatusInternalServerError)
	}
	return respond.Created(c, data, nil)
}

func (h *Handler) GetTrip(c fiber.Ctx) error {
	data, err := h.service.GetTrip(c.Locals("tripId").(uuid.UUID))
	return h.tripDetails(c, data, err)
}
func (h *Handler) PatchTrip(c fiber.Ctx) error {
	data, err := h.service.PatchTrip(c.Locals("tripId").(uuid.UUID), c.Locals("body").(PatchTripDTO))
	return h.tripDetails(c, data, err)
}
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
func (h *Handler) ConfirmTrip(c fiber.Ctx) error {
	data, err := h.service.ConfirmTrip(c.Context(), c.Locals("tripId").(uuid.UUID))
	return h.tripDetails(c, data, err)
}

func (h *Handler) RegenerateTrip(c fiber.Ctx) error {
	data, err := h.service.RegenerateTrip(c.Context(), c.Locals("tripId").(uuid.UUID))
	return h.tripDetails(c, data, err)
}

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

func (h *Handler) SelectTransport(c fiber.Ctx) error {
	data, err := h.service.SelectTransport(c.Locals("tripId").(uuid.UUID), c.Locals("optionId").(uuid.UUID))
	return h.tripDetails(c, data, err)
}

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

func (h *Handler) SelectHotel(c fiber.Ctx) error {
	data, err := h.service.SelectHotel(c.Locals("tripId").(uuid.UUID), c.Locals("optionId").(uuid.UUID))
	return h.tripDetails(c, data, err)
}

func (h *Handler) AddActivity(c fiber.Ctx) error {
	data, err := h.service.AddActivity(c.Locals("tripId").(uuid.UUID), c.Locals("body").(ManualActivityDTO))
	return h.tripDetails(c, data, err)
}

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
