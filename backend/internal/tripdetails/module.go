package tripdetails

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
	trips.Get("/:tripId", md.ValidateParam[uuid.UUID]("tripId"), handler.GetTrip)
	trips.Get("/:tripId/options/transport", md.ValidateParam[uuid.UUID]("tripId"), handler.GetTransportOptions)
	trips.Post("/:tripId/options/transport/:optionId/select", md.ValidateParam[uuid.UUID]("tripId"), md.ValidateParam[uuid.UUID]("optionId"), handler.SelectTransport)
	trips.Get("/:tripId/options/hotels", md.ValidateParam[uuid.UUID]("tripId"), handler.GetHotelOptions)
	trips.Post("/:tripId/options/hotels/:optionId/select", md.ValidateParam[uuid.UUID]("tripId"), md.ValidateParam[uuid.UUID]("optionId"), handler.SelectHotel)
	trips.Post("/:tripId/activities", md.ValidateParam[uuid.UUID]("tripId"), md.BindAndValidate[ManualActivityDTO](), handler.AddActivity)
	trips.Get("/:tripId/budget", md.ValidateParam[uuid.UUID]("tripId"), handler.GetBudget)
	trips.Get("/:tripId/visa", md.ValidateParam[uuid.UUID]("tripId"), handler.GetVisa)
	trips.Get("/:tripId/reviews", md.ValidateParam[uuid.UUID]("tripId"), handler.GetReviews)
}
