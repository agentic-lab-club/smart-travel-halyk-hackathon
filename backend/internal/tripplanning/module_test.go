package tripplanning

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/agentic-lab-club/smart-travel-halyk-hackathon/backend/pkg/config"
	"github.com/agentic-lab-club/smart-travel-halyk-hackathon/backend/pkg/travelcore"
	"github.com/gofiber/fiber/v3"
	"github.com/rs/zerolog"
)

func TestTripPlanningFlow(t *testing.T) {
	app := newTestApp()

	createResp := performJSONRequest(t, app, http.MethodPost, "/api/v1/trips", map[string]any{"title": "Family trip to Japan"})
	if createResp.StatusCode != http.StatusCreated {
		t.Fatalf("create status = %d; want %d", createResp.StatusCode, http.StatusCreated)
	}

	var created PlanningTripResponse
	decodeJSON(t, createResp, &created)
	if created.TripID.String() == "" {
		t.Fatalf("trip id is empty")
	}
	if len(created.MissingFields) == 0 {
		t.Fatalf("missing_fields must not be empty for an incomplete title-only prompt")
	}

	chatResp := performJSONRequest(t, app, http.MethodPost, "/api/v1/trips/"+created.TripID.String()+"/chat/messages", map[string]any{
		"content": "From Almaty to Tokyo on 2026-07-10 until 2026-07-17 with 900000 budget and Kazakhstan citizenship",
		"action":  "collect_fields",
	})
	if chatResp.StatusCode != http.StatusOK {
		t.Fatalf("chat status = %d; want %d", chatResp.StatusCode, http.StatusOK)
	}

	var planned PlanningChatResponse
	decodeJSON(t, chatResp, &planned)
	if !planned.Trip.ReadyForConfirmation {
		t.Fatalf("trip should be ready for confirmation after providing missing fields")
	}
}

func newTestApp() *fiber.App {
	app := fiber.New()
	app.Use(func(c fiber.Ctx) error {
		logger := zerolog.Nop()
		c.Locals("log", &logger)
		return c.Next()
	})
	Init(app, travelcore.NewCoreService(nil, &config.Config{}))
	return app
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
