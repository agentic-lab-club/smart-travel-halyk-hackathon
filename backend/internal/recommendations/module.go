package recommendations

import (
	"github.com/agentic-lab-club/smart-travel-halyk-hackathon/backend/pkg/travelcore"
	"github.com/gofiber/fiber/v3"
)

func Init(server *fiber.App, core *travelcore.CoreService) {
	server.Get("/api/v1/recommendations", NewHandler(NewService(core)).GetRecommendations)
}
