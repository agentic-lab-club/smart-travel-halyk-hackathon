package tripplanning

import (
	md "github.com/agentic-lab-club/smart-travel-halyk-hackathon/backend/pkg/http/middlewares"
	"github.com/agentic-lab-club/smart-travel-halyk-hackathon/backend/pkg/travelcore"
	"github.com/gofiber/fiber/v3"
	"github.com/google/uuid"
)

func Init(server *fiber.App, core *travelcore.CoreService) {
	RegisterRoutes(server, core)
}

func RegisterRoutes(server *fiber.App, core *travelcore.CoreService) {
	handler := NewHandler(NewService(core))
	trips := server.Group("/api/v1/trips")
	trips.Post("/", md.BindAndValidate[CreateTripDTO](), handler.CreateTrip)
	trips.Get("/:tripId/planning", md.ValidateParam[uuid.UUID]("tripId"), handler.GetPlanningTrip)
	trips.Patch("/:tripId", md.ValidateParam[uuid.UUID]("tripId"), md.BindAndValidate[PatchTripDTO](), handler.PatchTrip)
	trips.Post("/:tripId/chat/messages", md.ValidateParam[uuid.UUID]("tripId"), md.BindAndValidate[ChatMessageDTO](), handler.AddChatMessage)
	trips.Get("/:tripId/chat/messages", md.ValidateParam[uuid.UUID]("tripId"), handler.GetChatMessages)
	trips.Post("/:tripId/confirm", md.ValidateParam[uuid.UUID]("tripId"), handler.ConfirmTrip)
	trips.Post("/:tripId/regenerate", md.ValidateParam[uuid.UUID]("tripId"), handler.RegenerateTrip)
}
