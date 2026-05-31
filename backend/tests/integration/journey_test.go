//go:build integration

package integration

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/agentic-lab-club/smart-travel-halyk-hackathon/backend/pkg/travelcore"
)

type tripIDEnvelope struct {
	TripID string `json:"trip_id"`
}

func TestAgentHealthAndLegacyParseTrip(t *testing.T) {
	agentBaseURL := requiredEnv("INTEGRATION_AGENT_URL")
	client := newHTTPClient()

	waitForJSON(t, client, agentBaseURL+"/health", http.StatusOK, 60*time.Second)

	var parsed struct {
		Parsed map[string]any `json:"parsed"`
	}
	postJSON(t, client, agentBaseURL+"/parse-trip", map[string]any{
		"text": "Family trip from Almaty to Tokyo with 900000 budget",
	}, http.StatusOK, &parsed)

	if parsed.Parsed == nil {
		t.Fatalf("agent /parse-trip returned nil parsed payload")
	}
}

func TestMobileConsumerJourneyAcrossBackendAndAgent(t *testing.T) {
	backendBaseURL := requiredEnv("INTEGRATION_BACKEND_URL")
	agentBaseURL := requiredEnv("INTEGRATION_AGENT_URL")
	client := newHTTPClient()

	waitForJSON(t, client, agentBaseURL+"/health", http.StatusOK, 60*time.Second)
	waitForJSON(t, client, backendBaseURL+"/health/readiness", http.StatusOK, 60*time.Second)

	var profile travelcore.UserProfileResponse
	getJSON(t, client, backendBaseURL+"/api/v1/user-profile", http.StatusOK, &profile)
	if profile.UserID == "" || profile.Currency == "" {
		t.Fatalf("user-profile contract is incomplete: %+v", profile)
	}

	var recommendations travelcore.RecommendationsResponse
	getJSON(t, client, backendBaseURL+"/api/v1/recommendations", http.StatusOK, &recommendations)
	if len(recommendations.Recommendations) == 0 {
		t.Fatalf("recommendations should not be empty")
	}

	var planning travelcore.PlanningTripResponse
	postJSON(t, client, backendBaseURL+"/api/v1/trips", map[string]any{
		"title": "Family trip to Japan",
	}, http.StatusCreated, &planning)
	if planning.TripID.String() == "" {
		t.Fatalf("planning trip id is empty")
	}
	if len(planning.MissingFields) == 0 {
		t.Fatalf("expected missing_fields for partial initial prompt")
	}

	tripID := planning.TripID.String()

	var currentPlanning travelcore.PlanningTripResponse
	getJSON(t, client, backendBaseURL+"/api/v1/trips/"+tripID+"/planning", http.StatusOK, &currentPlanning)
	if currentPlanning.TripID.String() != tripID {
		t.Fatalf("planning read returned wrong trip id: %s", currentPlanning.TripID)
	}

	var chat travelcore.PlanningChatResponse
	postJSON(t, client, backendBaseURL+"/api/v1/trips/"+tripID+"/chat/messages", map[string]any{
		"content": "We depart from Almaty, Kazakhstan passport, 2026-07-10 to 2026-07-17, budget 900000, family trip, flight",
		"action":  "collect_fields",
	}, http.StatusOK, &chat)
	if len(chat.Messages) < 2 {
		t.Fatalf("expected chat history to contain user and assistant messages")
	}

	var patchedPlanning travelcore.PlanningTripResponse
	patchJSON(t, client, backendBaseURL+"/api/v1/trips/"+tripID, map[string]any{
		"origin_city":         "Almaty",
		"destination_country": "Japan",
		"destination_city":    "Tokyo",
		"start_date":          "2026-07-10",
		"end_date":            "2026-07-17",
		"budget":              900000,
		"transport_type":      "flight",
		"trip_purpose":        "family",
		"citizenship":         "Kazakhstan",
	}, http.StatusOK, &patchedPlanning)
	if len(patchedPlanning.MissingFields) != 0 {
		t.Fatalf("patch step should complete required fields: %+v", patchedPlanning)
	}
	if !patchedPlanning.ReadyForConfirmation {
		t.Fatalf("trip should be ready for confirmation after patch step: %+v", patchedPlanning)
	}

	var fetchedChat travelcore.PlanningChatResponse
	getJSON(t, client, backendBaseURL+"/api/v1/trips/"+tripID+"/chat/messages", http.StatusOK, &fetchedChat)
	if fetchedChat.SessionID.String() == "" {
		t.Fatalf("chat session id is empty")
	}

	var trip travelcore.TripDetailsResponse
	postJSON(t, client, backendBaseURL+"/api/v1/trips/"+tripID+"/confirm", nil, http.StatusOK, &trip)
	assertTripDetailsContract(t, trip)

	var fetchedTrip travelcore.TripDetailsResponse
	getJSON(t, client, backendBaseURL+"/api/v1/trips/"+tripID, http.StatusOK, &fetchedTrip)
	assertTripDetailsContract(t, fetchedTrip)

	var budget travelcore.BudgetBreakdown
	getJSON(t, client, backendBaseURL+"/api/v1/trips/"+tripID+"/budget", http.StatusOK, &budget)
	if budget.Total.Currency == "" || len(budget.Items) == 0 {
		t.Fatalf("budget contract is incomplete: %+v", budget)
	}

	var visa travelcore.VisaInfo
	getJSON(t, client, backendBaseURL+"/api/v1/trips/"+tripID+"/visa", http.StatusOK, &visa)
	if visa.Citizenship == "" || visa.DestinationCountry == "" {
		t.Fatalf("visa contract is incomplete: %+v", visa)
	}

	var reviews []travelcore.ReviewSummary
	getJSON(t, client, backendBaseURL+"/api/v1/trips/"+tripID+"/reviews", http.StatusOK, &reviews)
	if len(reviews) == 0 {
		t.Fatalf("reviews should not be empty")
	}

	var transportOptions []travelcore.TransportOption
	getJSON(t, client, backendBaseURL+"/api/v1/trips/"+tripID+"/options/transport", http.StatusOK, &transportOptions)
	if len(transportOptions) < 2 {
		t.Fatalf("expected at least two transport options")
	}

	alternativeTransportID := findUnselectedTransportOption(transportOptions)
	if alternativeTransportID == "" {
		t.Fatalf("failed to find alternative transport option")
	}

	var tripAfterTransport travelcore.TripDetailsResponse
	postJSON(t, client, backendBaseURL+"/api/v1/trips/"+tripID+"/options/transport/"+alternativeTransportID+"/select", nil, http.StatusOK, &tripAfterTransport)
	assertTripDetailsContract(t, tripAfterTransport)

	var hotelOptions []travelcore.HotelOption
	getJSON(t, client, backendBaseURL+"/api/v1/trips/"+tripID+"/options/hotels", http.StatusOK, &hotelOptions)
	if len(hotelOptions) < 2 {
		t.Fatalf("expected at least two hotel options")
	}

	alternativeHotelID := findUnselectedHotelOption(hotelOptions)
	if alternativeHotelID == "" {
		t.Fatalf("failed to find alternative hotel option")
	}

	var tripAfterHotel travelcore.TripDetailsResponse
	postJSON(t, client, backendBaseURL+"/api/v1/trips/"+tripID+"/options/hotels/"+alternativeHotelID+"/select", nil, http.StatusOK, &tripAfterHotel)
	assertTripDetailsContract(t, tripAfterHotel)

	var tripAfterActivity travelcore.TripDetailsResponse
	postJSON(t, client, backendBaseURL+"/api/v1/trips/"+tripID+"/activities", map[string]any{
		"kind":        "event",
		"title":       "Kino.kz Anime Event Pick",
		"location":    "Tokyo",
		"day_label":   "Day 3",
		"price":       21000,
		"source_name": "Kino.kz",
		"source_link": "https://kino.kz",
		"description": "Manual event insertion from integration test",
	}, http.StatusOK, &tripAfterActivity)
	assertTripDetailsContract(t, tripAfterActivity)

	var regeneratedTrip travelcore.TripDetailsResponse
	postJSON(t, client, backendBaseURL+"/api/v1/trips/"+tripID+"/regenerate", nil, http.StatusOK, &regeneratedTrip)
	assertTripDetailsContract(t, regeneratedTrip)

	hotelID := selectedHotelID(regeneratedTrip)
	if hotelID == "" {
		t.Fatalf("selected hotel id is empty after generation")
	}

	var hotel travelcore.HotelDetailsFull
	getJSON(t, client, backendBaseURL+"/api/v1/hotels/"+hotelID, http.StatusOK, &hotel)
	if hotel.HotelID == "" || len(hotel.Rooms) == 0 || len(hotel.SourceRatings) == 0 {
		t.Fatalf("hotel details contract is incomplete: %+v", hotel)
	}
}

func TestConfirmRejectedWhenRequiredFieldsAreMissing(t *testing.T) {
	backendBaseURL := requiredEnv("INTEGRATION_BACKEND_URL")
	agentBaseURL := requiredEnv("INTEGRATION_AGENT_URL")
	client := newHTTPClient()

	waitForJSON(t, client, agentBaseURL+"/health", http.StatusOK, 60*time.Second)
	waitForJSON(t, client, backendBaseURL+"/health/readiness", http.StatusOK, 60*time.Second)

	var planning travelcore.PlanningTripResponse
	postJSON(t, client, backendBaseURL+"/api/v1/trips", map[string]any{
		"title": "Trip to Japan",
	}, http.StatusCreated, &planning)

	req, err := http.NewRequestWithContext(context.Background(), http.MethodPost, backendBaseURL+"/api/v1/trips/"+planning.TripID.String()+"/confirm", nil)
	if err != nil {
		t.Fatalf("failed to build confirm request: %v", err)
	}
	resp, err := client.Do(req)
	if err != nil {
		t.Fatalf("confirm request failed: %v", err)
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	if resp.StatusCode == http.StatusOK {
		t.Fatalf("confirm should fail for incomplete trip, body=%s", strings.TrimSpace(string(body)))
	}
}

func assertTripDetailsContract(t *testing.T, trip travelcore.TripDetailsResponse) {
	t.Helper()
	if trip.TripID == "" || trip.Title == "" || trip.Currency == "" {
		t.Fatalf("trip top-level contract is incomplete: %+v", trip)
	}
	if len(trip.RouteNavigator) == 0 || len(trip.Map.Markers) == 0 || len(trip.Map.Routes) == 0 {
		t.Fatalf("trip route/map contract is incomplete")
	}
	if len(trip.Segments) == 0 {
		t.Fatalf("trip segments should not be empty")
	}
	if len(trip.ModeVariants) == 0 {
		t.Fatalf("trip mode variants should not be empty")
	}
	if len(trip.Budget.Items) == 0 || trip.Budget.Total.Currency == "" {
		t.Fatalf("trip budget contract is incomplete")
	}
	for _, marker := range trip.Map.Markers {
		if marker.MarkerID == "" {
			t.Fatalf("map marker id is empty")
		}
	}
	for _, route := range trip.Map.Routes {
		if route.RouteID == "" {
			t.Fatalf("map route id is empty")
		}
	}
	for _, segment := range trip.Segments {
		if segment.SegmentID == "" {
			t.Fatalf("segment id is empty")
		}
		if segment.Details.Kind == "" {
			t.Fatalf("segment details kind is empty for segment %s", segment.SegmentID)
		}
	}
}

func findUnselectedTransportOption(options []travelcore.TransportOption) string {
	for _, option := range options {
		if !option.Selected {
			return option.ID.String()
		}
	}
	return ""
}

func findUnselectedHotelOption(options []travelcore.HotelOption) string {
	for _, option := range options {
		if !option.Selected {
			return option.ID.String()
		}
	}
	return ""
}

func selectedHotelID(trip travelcore.TripDetailsResponse) string {
	for _, segment := range trip.Segments {
		if segment.Details.Kind != "hotel" {
			continue
		}
		payload, ok := segment.Details.Payload.(map[string]any)
		if !ok {
			continue
		}
		if hotelID, ok := payload["hotelId"].(string); ok && strings.TrimSpace(hotelID) != "" {
			return hotelID
		}
	}
	return ""
}

func waitForJSON(t *testing.T, client *http.Client, url string, statusCode int, timeout time.Duration) {
	t.Helper()
	deadline := time.Now().Add(timeout)
	var lastErr error
	for time.Now().Before(deadline) {
		req, err := http.NewRequestWithContext(context.Background(), http.MethodGet, url, nil)
		if err != nil {
			t.Fatalf("failed to build request for %s: %v", url, err)
		}
		resp, err := client.Do(req)
		if err == nil {
			defer resp.Body.Close()
			if resp.StatusCode == statusCode {
				return
			}
			body, _ := io.ReadAll(resp.Body)
			lastErr = fmt.Errorf("status=%d body=%s", resp.StatusCode, strings.TrimSpace(string(body)))
		} else {
			lastErr = err
		}
		time.Sleep(2 * time.Second)
	}
	t.Fatalf("service %s did not become ready: %v", url, lastErr)
}

func getJSON(t *testing.T, client *http.Client, url string, expectedStatus int, out any) {
	t.Helper()
	req, err := http.NewRequestWithContext(context.Background(), http.MethodGet, url, nil)
	if err != nil {
		t.Fatalf("failed to build GET request: %v", err)
	}
	doJSON(t, client, req, expectedStatus, out)
}

func postJSON(t *testing.T, client *http.Client, url string, body any, expectedStatus int, out any) {
	t.Helper()
	requestJSON(t, client, http.MethodPost, url, body, expectedStatus, out)
}

func patchJSON(t *testing.T, client *http.Client, url string, body any, expectedStatus int, out any) {
	t.Helper()
	requestJSON(t, client, http.MethodPatch, url, body, expectedStatus, out)
}

func requestJSON(t *testing.T, client *http.Client, method, url string, body any, expectedStatus int, out any) {
	t.Helper()
	var reader io.Reader
	if body != nil {
		payload, err := json.Marshal(body)
		if err != nil {
			t.Fatalf("failed to marshal request body for %s: %v", url, err)
		}
		reader = bytes.NewReader(payload)
	}
	req, err := http.NewRequestWithContext(context.Background(), method, url, reader)
	if err != nil {
		t.Fatalf("failed to build %s request: %v", method, err)
	}
	req.Header.Set("Content-Type", "application/json")
	doJSON(t, client, req, expectedStatus, out)
}

func doJSON(t *testing.T, client *http.Client, req *http.Request, expectedStatus int, out any) {
	t.Helper()
	resp, err := client.Do(req)
	if err != nil {
		t.Fatalf("%s %s failed: %v", req.Method, req.URL.String(), err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		t.Fatalf("failed to read response body: %v", err)
	}
	if resp.StatusCode != expectedStatus {
		t.Fatalf("%s %s returned status %d, expected %d, body=%s", req.Method, req.URL.String(), resp.StatusCode, expectedStatus, strings.TrimSpace(string(body)))
	}
	if out == nil {
		return
	}
	if err := json.Unmarshal(body, out); err != nil {
		t.Fatalf("failed to decode response from %s: %v, body=%s", req.URL.String(), err, strings.TrimSpace(string(body)))
	}
}

func newHTTPClient() *http.Client {
	return &http.Client{Timeout: 15 * time.Second}
}

func requiredEnv(key string) string {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		panic("required env missing: " + key)
	}
	return value
}
