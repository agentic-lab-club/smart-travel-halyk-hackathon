package trip

import (
	"github.com/agentic-lab-club/smart-travel-halyk-hackathon/backend/pkg/config"
	"github.com/agentic-lab-club/smart-travel-halyk-hackathon/backend/pkg/database"
	md "github.com/agentic-lab-club/smart-travel-halyk-hackathon/backend/pkg/http/middlewares"
	"github.com/gofiber/fiber/v3"
	"github.com/google/uuid"
)

func Init(server *fiber.App, db *database.TrackedDB, cfg *config.Config) {
	RegisterRoutes(server, db, cfg)
}

func RegisterRoutes(server *fiber.App, db *database.TrackedDB, cfg *config.Config) {
	repo := NewRepository(db)
	service := NewService(repo, NewPlannerClient(cfg), cfg)
	handler := NewHandler(service)

	// Consumer read-model endpoints (user profile, recommendations, hotel details)
	consumer := server.Group("/api/v1")
	consumer.Get("/user-profile", GetUserProfile)
	consumer.Get("/recommendations", GetRecommendations)
	consumer.Get("/hotels/:hotelId", GetHotelDetails)

	trips := server.Group("/api/v1/trips")
	trips.Post("/", md.BindAndValidate[CreateTripDTO](), handler.CreateTrip)
	trips.Get("/:tripId", md.ValidateParam[uuid.UUID]("tripId"), handler.GetTrip)
	trips.Patch("/:tripId", md.ValidateParam[uuid.UUID]("tripId"), md.BindAndValidate[PatchTripDTO](), handler.PatchTrip)
	trips.Post("/:tripId/chat/messages", md.ValidateParam[uuid.UUID]("tripId"), md.BindAndValidate[ChatMessageDTO](), handler.AddChatMessage)
	trips.Get("/:tripId/chat/messages", md.ValidateParam[uuid.UUID]("tripId"), handler.GetChatMessages)
	trips.Post("/:tripId/confirm", md.ValidateParam[uuid.UUID]("tripId"), handler.ConfirmTrip)
	trips.Post("/:tripId/regenerate", md.ValidateParam[uuid.UUID]("tripId"), handler.RegenerateTrip)
	trips.Get("/:tripId/options/transport", md.ValidateParam[uuid.UUID]("tripId"), handler.GetTransportOptions)
	trips.Post("/:tripId/options/transport/:optionId/select", md.ValidateParam[uuid.UUID]("tripId"), md.ValidateParam[uuid.UUID]("optionId"), handler.SelectTransport)
	trips.Get("/:tripId/options/hotels", md.ValidateParam[uuid.UUID]("tripId"), handler.GetHotelOptions)
	trips.Post("/:tripId/options/hotels/:optionId/select", md.ValidateParam[uuid.UUID]("tripId"), md.ValidateParam[uuid.UUID]("optionId"), handler.SelectHotel)
	trips.Post("/:tripId/activities", md.ValidateParam[uuid.UUID]("tripId"), md.BindAndValidate[ManualActivityDTO](), handler.AddActivity)
	trips.Get("/:tripId/budget", md.ValidateParam[uuid.UUID]("tripId"), handler.GetBudget)
	trips.Get("/:tripId/visa", md.ValidateParam[uuid.UUID]("tripId"), handler.GetVisa)
	trips.Get("/:tripId/reviews", md.ValidateParam[uuid.UUID]("tripId"), handler.GetReviews)
}
