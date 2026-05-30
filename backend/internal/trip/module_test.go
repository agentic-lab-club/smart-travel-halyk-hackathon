package trip

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/agentic-lab-club/smart-travel-halyk-hackathon/backend/pkg/config"
	"github.com/gofiber/fiber/v3"
	"github.com/rs/zerolog"
)

func TestTripFlowCreateChatConfirm(t *testing.T) {
	app := newTripTestApp(t)

	createResp := performJSONRequest(t, app, http.MethodPost, "/api/v1/trips", map[string]any{"title": "Summer family trip"})
	if createResp.StatusCode != http.StatusCreated {
		t.Fatalf("create trip status = %d; want %d", createResp.StatusCode, http.StatusCreated)
	}

	var created TripDetailsResponse
	decodeTripResponse(t, createResp, &created)
	if created.Trip.ID.String() == "" {
		t.Fatalf("trip id is empty")
	}

	chatResp := performJSONRequest(t, app, http.MethodPost, "/api/v1/trips/"+created.Trip.ID.String()+"/chat/messages", map[string]any{
		"content": "Family trip to Japan in July with budget 900000 and kids",
		"action":  "collect_fields",
	})
	if chatResp.StatusCode != http.StatusOK {
		t.Fatalf("chat status = %d; want %d", chatResp.StatusCode, http.StatusOK)
	}

	confirmResp := performJSONRequest(t, app, http.MethodPost, "/api/v1/trips/"+created.Trip.ID.String()+"/confirm", nil)
	if confirmResp.StatusCode != http.StatusOK {
		t.Fatalf("confirm status = %d; want %d", confirmResp.StatusCode, http.StatusOK)
	}

	var confirmed TripDetailsResponse
	decodeTripResponse(t, confirmResp, &confirmed)
	if confirmed.Trip.Status != StatusGenerated {
		t.Fatalf("trip status = %q; want %q", confirmed.Trip.Status, StatusGenerated)
	}
	if confirmed.SelectedHotel == nil || confirmed.SelectedTransport == nil {
		t.Fatalf("selected items are missing after generation")
	}
	if confirmed.Budget.GrandTotal == 0 {
		t.Fatalf("grand total = 0; want non-zero")
	}
}

func TestCreateTripSeedsDraftFromTitle(t *testing.T) {
	app := newTripTestApp(t)

	createResp := performJSONRequest(t, app, http.MethodPost, "/api/v1/trips", map[string]any{
		"title": "Family trip to Japan in July with budget 900000 from Almaty and Kazakhstan passport",
	})
	if createResp.StatusCode != http.StatusCreated {
		t.Fatalf("create trip status = %d; want %d", createResp.StatusCode, http.StatusCreated)
	}

	var created TripDetailsResponse
	decodeTripResponse(t, createResp, &created)

	if created.Trip.DestinationCountry != "Japan" {
		t.Fatalf("destination_country = %q; want %q", created.Trip.DestinationCountry, "Japan")
	}
	if created.Trip.DestinationCity != "Tokyo" {
		t.Fatalf("destination_city = %q; want %q", created.Trip.DestinationCity, "Tokyo")
	}
	if created.Trip.Budget != 900000 {
		t.Fatalf("budget = %d; want %d", created.Trip.Budget, 900000)
	}
	if created.Trip.Status == StatusDraft {
		t.Fatalf("status = %q; want non-draft initialized state", created.Trip.Status)
	}
}

func newTripTestApp(t *testing.T) *fiber.App {
	t.Helper()
	app := fiber.New()
	app.Use(func(c fiber.Ctx) error {
		logger := zerolog.Nop()
		c.Locals("log", &logger)
		return c.Next()
	})
	RegisterRoutes(app, nil, &config.Config{})
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

func decodeTripResponse(t *testing.T, resp *http.Response, out any) {
	t.Helper()
	defer resp.Body.Close()
	if err := json.NewDecoder(resp.Body).Decode(out); err != nil {
		t.Fatalf("json decode error = %v", err)
	}
}
