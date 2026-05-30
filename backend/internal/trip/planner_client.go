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
)

type PlannerClient interface {
	Plan(ctx context.Context, req AIPlanningRequest) (*AIPlanningResponse, error)
}

type HTTPPlannerClient struct {
	baseURL  string
	client   *http.Client
	fallback PlannerClient
}

type agentParseTripRequest struct {
	Text string `json:"text"`
}

type agentParseTripResponse struct {
	Parsed struct {
		Country       string `json:"country"`
		DepartureDate string `json:"departure_date"`
		ArrivalDate   string `json:"arrival_date"`
		City          string `json:"city"`
		Theme         string `json:"theme"`
		Cost          int    `json:"cost"`
		PeopleCount   int    `json:"people_count"`
	} `json:"parsed"`
	RawText string `json:"raw_text"`
}

func NewPlannerClient(cfg *config.Config) PlannerClient {
	fallback := &LocalPlannerClient{}
	if cfg != nil && strings.TrimSpace(cfg.AIAgent.URL) != "" {
		return &HTTPPlannerClient{
			baseURL:  strings.TrimRight(cfg.AIAgent.URL, "/"),
			client:   &http.Client{Timeout: 15 * time.Second},
			fallback: fallback,
		}
	}
	return fallback
}

func (c *HTTPPlannerClient) Plan(ctx context.Context, req AIPlanningRequest) (*AIPlanningResponse, error) {
	response, err := c.parseTrip(ctx, req)
	if err != nil {
		return c.fallback.Plan(ctx, req)
	}
	return buildAIPlanningResponse(req, response), nil
}

func (c *HTTPPlannerClient) parseTrip(ctx context.Context, req AIPlanningRequest) (*agentParseTripResponse, error) {
	body, err := json.Marshal(agentParseTripRequest{Text: buildAgentPrompt(req)})
	if err != nil {
		return nil, fmt.Errorf("marshal parse-trip request: %w", err)
	}

	for _, endpoint := range []string{"/parse-trip", "/parser-trip"} {
		httpReq, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+endpoint, bytes.NewReader(body))
		if err != nil {
			return nil, fmt.Errorf("create parse-trip request: %w", err)
		}
		httpReq.Header.Set("Content-Type", "application/json")

		resp, err := c.client.Do(httpReq)
		if err != nil {
			continue
		}

		var parsed agentParseTripResponse
		decodeErr := json.NewDecoder(resp.Body).Decode(&parsed)
		resp.Body.Close()
		if resp.StatusCode >= 400 || decodeErr != nil {
			continue
		}

		return &parsed, nil
	}

	return nil, fmt.Errorf("agent parse-trip endpoints unavailable")
}

func buildAgentPrompt(req AIPlanningRequest) string {
	lines := []string{"Extract travel details for a Smart Travel trip plan."}
	if text := strings.TrimSpace(req.UserPrompt); text != "" {
		lines = append(lines, "User request: "+text)
	}
	for _, field := range []struct {
		Key   string
		Label string
	}{
		{Key: "origin_city", Label: "Origin city"},
		{Key: "destination_country", Label: "Destination country"},
		{Key: "destination_city", Label: "Destination city"},
		{Key: "start_date", Label: "Start date"},
		{Key: "end_date", Label: "End date"},
		{Key: "budget", Label: "Budget KZT"},
		{Key: "transport_type", Label: "Transport type"},
		{Key: "trip_purpose", Label: "Trip purpose"},
		{Key: "citizenship", Label: "Citizenship"},
	} {
		if value, ok := req.CurrentTrip[field.Key]; ok && strings.TrimSpace(fmt.Sprint(value)) != "" {
			lines = append(lines, fmt.Sprintf("%s: %v", field.Label, value))
		}
	}
	lines = append(lines, "Return country, city, departure_date, arrival_date, theme, cost, and people_count.")
	return strings.Join(lines, "\n")
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
	country := stringValue(normalized["destination_country"], "")
	return &AIPlanningResponse{
		MissingFields:    requiredMissing(normalized),
		NormalizedFields: normalized,
		VibeLabels:       buildVibeLabels(prompt, normalized["trip_purpose"].(string), ""),
		VisaInsights:     visaInsightsForCountry(country),
		WeatherInsights:  weatherInsightsForCountry(country),
		ReviewSummaries:  reviewSummariesForCountry(country),
		AssistantSummary: assistantSummaryForPlan(normalized, normalized["trip_purpose"].(string)),
	}, nil
}

func requiredMissing(values map[string]any) []string {
	missing := []string{}
	for _, key := range planningRequiredFields() {
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
		case float64:
			if int(v) == 0 {
				missing = append(missing, key)
			}
		default:
			if value == nil {
				missing = append(missing, key)
			}
		}
	}
	return missing
}

func planningRequiredFields() []string {
	return []string{"origin_city", "destination_country", "destination_city", "start_date", "end_date", "budget", "transport_type", "trip_purpose", "citizenship"}
}

func inferCountry(prompt string) string {
	switch {
	case strings.Contains(prompt, "japan") || strings.Contains(prompt, "tokyo"):
		return "Japan"
	case strings.Contains(prompt, "germany") || strings.Contains(prompt, "berlin"):
		return "Germany"
	default:
		return "Kazakhstan"
	}
}

func inferCity(prompt string) string {
	switch {
	case strings.Contains(prompt, "tokyo") || strings.Contains(prompt, "japan"):
		return "Tokyo"
	case strings.Contains(prompt, "germany") || strings.Contains(prompt, "berlin"):
		return "Berlin"
	default:
		return "Almaty"
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
