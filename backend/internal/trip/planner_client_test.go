package trip

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/agentic-lab-club/smart-travel-halyk-hackathon/backend/pkg/config"
)

func TestHTTPPlannerClientMapsParseTripResponse(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/parse-trip" {
			t.Fatalf("unexpected path %q", r.URL.Path)
		}
		_ = json.NewEncoder(w).Encode(map[string]any{
			"parsed": map[string]any{
				"country":        "Japan",
				"departure_date": "2026-07-10",
				"arrival_date":   "2026-07-17",
				"city":           "Tokyo",
				"theme":          "Family",
				"cost":           900000,
				"people_count":   4,
			},
			"raw_text": "ok",
		})
	}))
	defer server.Close()

	client := NewPlannerClient(&config.Config{AIAgent: config.AIAgentConfig{URL: server.URL}})
	plan, err := client.Plan(context.Background(), AIPlanningRequest{
		UserPrompt: "Family trip to Japan in July with budget 900000",
		CurrentTrip: map[string]any{
			"origin_city": "Almaty",
			"citizenship": "Kazakhstan",
		},
	})
	if err != nil {
		t.Fatalf("plan error = %v", err)
	}

	if got := stringValue(plan.NormalizedFields["destination_country"], ""); got != "Japan" {
		t.Fatalf("destination_country = %q; want Japan", got)
	}
	if got := stringValue(plan.NormalizedFields["destination_city"], ""); got != "Tokyo" {
		t.Fatalf("destination_city = %q; want Tokyo", got)
	}
	if plan.AssistantSummary == "" {
		t.Fatalf("assistant summary is empty")
	}
}

func TestHTTPPlannerClientFallsBackWhenAgentUnavailable(t *testing.T) {
	client := NewPlannerClient(&config.Config{AIAgent: config.AIAgentConfig{URL: "http://127.0.0.1:1"}})
	plan, err := client.Plan(context.Background(), AIPlanningRequest{
		UserPrompt: "Solo event trip to Dubai with budget 500000",
		CurrentTrip: map[string]any{
			"origin_city": "Almaty",
			"citizenship": "Kazakhstan",
		},
	})
	if err != nil {
		t.Fatalf("plan error = %v", err)
	}

	if got := stringValue(plan.NormalizedFields["destination_country"], ""); got != "UAE" {
		t.Fatalf("destination_country = %q; want UAE", got)
	}
	if len(plan.VibeLabels) == 0 {
		t.Fatalf("vibe labels are empty")
	}
}
