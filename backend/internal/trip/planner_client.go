package trip

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/agentic-lab-club/smart-travel-halyk-hackathon/backend/pkg/config"
	"github.com/google/uuid"
)

type PlannerClient interface {
	Plan(ctx context.Context, req AIPlanningRequest) (*AIPlanningResponse, error)
}

type HTTPPlannerClient struct {
	baseURL string
	client  *http.Client
}

func NewPlannerClient(cfg *config.Config) PlannerClient {
	if cfg != nil && strings.TrimSpace(cfg.AIAgent.URL) != "" {
		return &HTTPPlannerClient{
			baseURL: strings.TrimRight(cfg.AIAgent.URL, "/"),
			client:  &http.Client{Timeout: 10 * time.Second},
		}
	}
	return &LocalPlannerClient{}
}

func (c *HTTPPlannerClient) Plan(ctx context.Context, req AIPlanningRequest) (*AIPlanningResponse, error) {
	body, err := json.Marshal(req)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal planning request: %w", err)
	}
	httpReq, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+"/plan", bytes.NewReader(body))
	if err != nil {
		return nil, fmt.Errorf("failed to create planning request: %w", err)
	}
	httpReq.Header.Set("Content-Type", "application/json")
	resp, err := c.client.Do(httpReq)
	if err != nil || resp.StatusCode >= 400 {
		return (&LocalPlannerClient{}).Plan(ctx, req)
	}
	defer resp.Body.Close()
	var out AIPlanningResponse
	if err := json.NewDecoder(resp.Body).Decode(&out); err != nil {
		return nil, fmt.Errorf("failed to decode planning response: %w", err)
	}
	return &out, nil
}

type LocalPlannerClient struct{}

func (c *LocalPlannerClient) Plan(_ context.Context, req AIPlanningRequest) (*AIPlanningResponse, error) {
	prompt := strings.ToLower(req.UserPrompt)
	normalized := map[string]any{
		"origin_city":         stringValue(req.CurrentTrip["origin_city"], "Almaty"),
		"destination_country": stringValue(req.CurrentTrip["destination_country"], inferCountry(prompt)),
		"destination_city":    stringValue(req.CurrentTrip["destination_city"], inferCity(prompt)),
		"start_date":          stringValue(req.CurrentTrip["start_date"], "2026-07-10"),
		"end_date":            stringValue(req.CurrentTrip["end_date"], "2026-07-17"),
		"transport_type":      stringValue(req.CurrentTrip["transport_type"], inferTransport(prompt)),
		"trip_purpose":        stringValue(req.CurrentTrip["trip_purpose"], inferPurpose(prompt)),
		"citizenship":         stringValue(req.CurrentTrip["citizenship"], "Kazakhstan"),
		"budget":              intValue(req.CurrentTrip["budget"], inferBudget(prompt)),
	}
	return &AIPlanningResponse{
		MissingFields:    requiredMissing(normalized),
		NormalizedFields: normalized,
		VibeLabels:       inferVibes(prompt, normalized["trip_purpose"].(string)),
		VisaInsights: VisaInfo{
			Country:         normalized["destination_country"].(string),
			Requirement:     "Prototype visa assistant based on mock rules",
			RecommendedLead: "Check requirements 14-30 days before departure",
			Checklist:       []string{"Passport", "Travel dates", "Hotel booking", "Insurance"},
			Notes:           "Mock output from local planner fallback",
		},
		WeatherInsights: []string{
			"Weather and seasonality are shown as guidance, not real-time facts.",
			"AI suggests planning around family comfort and event timing.",
		},
		ReviewSummaries: []ReviewSummary{
			{
				ID:         uuid.New(),
				Kind:       "hotel",
				TargetName: "Suggested stay",
				Summary:    "AI summary focuses on family fit, transit access, and review sentiment.",
				SourceName: "Tripadvisor",
				SourceLink: "https://tripadvisor.com",
			},
		},
		AssistantSummary: fmt.Sprintf("I collected the trip context and prepared a %s plan for %s.", normalized["trip_purpose"], normalized["destination_city"]),
	}, nil
}

func requiredMissing(values map[string]any) []string {
	required := []string{"origin_city", "destination_country", "destination_city", "start_date", "end_date", "budget", "transport_type", "trip_purpose", "citizenship"}
	missing := []string{}
	for _, key := range required {
		value := values[key]
		switch v := value.(type) {
		case string:
			if strings.TrimSpace(v) == "" {
				missing = append(missing, key)
			}
		case int:
			if v == 0 {
				missing = append(missing, key)
			}
		}
	}
	return missing
}

func inferCountry(prompt string) string {
	switch {
	case strings.Contains(prompt, "dubai") || strings.Contains(prompt, "uae"):
		return "UAE"
	case strings.Contains(prompt, "japan") || strings.Contains(prompt, "tokyo"):
		return "Japan"
	case strings.Contains(prompt, "kazakhstan") || strings.Contains(prompt, "almaty"):
		return "Kazakhstan"
	default:
		return "Turkey"
	}
}

func inferCity(prompt string) string {
	switch {
	case strings.Contains(prompt, "dubai"):
		return "Dubai"
	case strings.Contains(prompt, "tokyo") || strings.Contains(prompt, "japan"):
		return "Tokyo"
	case strings.Contains(prompt, "kazakhstan") || strings.Contains(prompt, "almaty"):
		return "Almaty"
	default:
		return "Istanbul"
	}
}

func inferTransport(prompt string) string {
	if strings.Contains(prompt, "train") || strings.Contains(prompt, "rail") || strings.Contains(prompt, "жд") {
		return "rail"
	}
	return "flight"
}

func inferPurpose(prompt string) string {
	switch {
	case strings.Contains(prompt, "solo"):
		return "solo"
	case strings.Contains(prompt, "event") || strings.Contains(prompt, "kino"):
		return "event"
	default:
		return "family"
	}
}

func inferBudget(prompt string) int {
	if strings.Contains(prompt, "900") {
		return 900000
	}
	if strings.Contains(prompt, "500") {
		return 500000
	}
	return 750000
}

func inferVibes(prompt, purpose string) []string {
	switch purpose {
	case "solo":
		return []string{"solo", "event", "city-break"}
	case "event":
		return []string{"event", "urban", "flexible"}
	default:
		if strings.Contains(prompt, "budget") {
			return []string{"family", "budget", "balanced"}
		}
		return []string{"family", "comfort", "planner"}
	}
}

func stringValue(v any, fallback string) string {
	if s, ok := v.(string); ok && strings.TrimSpace(s) != "" {
		return s
	}
	return fallback
}

func intValue(v any, fallback int) int {
	switch value := v.(type) {
	case int:
		if value > 0 {
			return value
		}
	case float64:
		if value > 0 {
			return int(value)
		}
	}
	return fallback
}
