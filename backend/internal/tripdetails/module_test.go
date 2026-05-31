package tripdetails

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/agentic-lab-club/smart-travel-halyk-hackathon/backend/internal/tripplanning"
	"github.com/agentic-lab-club/smart-travel-halyk-hackathon/backend/pkg/config"
	"github.com/agentic-lab-club/smart-travel-halyk-hackathon/backend/pkg/travelcore"
	"github.com/gofiber/fiber/v3"
	"github.com/rs/zerolog"
)

func TestGeneratedTripDetailsMatchMobileShape(t *testing.T) {
	core := travelcore.NewCoreService(nil, &config.Config{})
	app := fiber.New()
	app.Use(func(c fiber.Ctx) error {
		logger := zerolog.Nop()
		c.Locals("log", &logger)
		return c.Next()
	})
	tripplanning.Init(app, core)
	Init(app, core)

	tripID := createAndConfirmTrip(t, app)

	resp := performJSONRequest(t, app, http.MethodGet, "/api/v1/trips/"+tripID, nil)
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("get trip status = %d; want %d", resp.StatusCode, http.StatusOK)
	}

	var trip TripDetailsResponse
	decodeJSON(t, resp, &trip)
	if trip.TripID == "" || len(trip.Segments) == 0 || len(trip.Map.Markers) == 0 {
		t.Fatalf("trip details response is missing required mobile fields")
	}
	if trip.Segments[0].Details.Kind == "" {
		t.Fatalf("segment details envelope kind is empty")
	}
}

func createAndConfirmTrip(t *testing.T, app *fiber.App) string {
	t.Helper()
	var created struct {
		TripID string `json:"trip_id"`
	}
	createResp := performJSONRequest(t, app, http.MethodPost, "/api/v1/trips", map[string]any{"title": "Family trip to Japan"})
	decodeJSON(t, createResp, &created)
	performJSONRequest(t, app, http.MethodPost, "/api/v1/trips/"+created.TripID+"/chat/messages", map[string]any{
		"content": "From Almaty to Tokyo on 2026-07-10 until 2026-07-17 with 900000 budget and Kazakhstan citizenship",
		"action":  "collect_fields",
	})
	confirmResp := performJSONRequest(t, app, http.MethodPost, "/api/v1/trips/"+created.TripID+"/confirm", nil)
	if confirmResp.StatusCode != http.StatusOK {
		t.Fatalf("confirm status = %d; want %d", confirmResp.StatusCode, http.StatusOK)
	}
	var trip TripDetailsResponse
	decodeJSON(t, confirmResp, &trip)
	return trip.TripID
}

func performJSONRequest(t *testing.T, app *fiber.App, method, path string, payload any) *http.Response {
	t.Helper()
	var body []byte
	if payload != nil {
		var err error
		body, err = json.Marshal(payload)
		if err != nil {
			t.Fatalf("json marshal error = %v", err)
		}
	}
	req := httptest.NewRequest(method, path, bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	resp, err := app.Test(req, fiber.TestConfig{Timeout: 0})
	if err != nil {
		t.Fatalf("%s %s request error = %v", method, path, err)
	}
	return resp
}

func decodeJSON(t *testing.T, resp *http.Response, out any) {
	t.Helper()
	defer resp.Body.Close()
	if err := json.NewDecoder(resp.Body).Decode(out); err != nil {
		t.Fatalf("json decode error = %v", err)
	}
}
