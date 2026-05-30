package trip

import (
	"fmt"
	"strings"

	"github.com/google/uuid"
)

func buildAIPlanningResponse(req AIPlanningRequest, parsed *agentParseTripResponse) *AIPlanningResponse {
	normalized := cloneStringAnyMap(req.CurrentTrip)
	if normalized == nil {
		normalized = map[string]any{}
	}

	prompt := strings.ToLower(req.UserPrompt)
	if value := normalizeCountry(parsed.Parsed.Country); value != "" {
		normalized["destination_country"] = value
	}
	if value := strings.TrimSpace(parsed.Parsed.City); value != "" {
		normalized["destination_city"] = value
	}
	if value := strings.TrimSpace(parsed.Parsed.DepartureDate); value != "" {
		normalized["start_date"] = value
	}
	if value := strings.TrimSpace(parsed.Parsed.ArrivalDate); value != "" {
		normalized["end_date"] = value
	}
	if parsed.Parsed.Cost > 0 {
		normalized["budget"] = parsed.Parsed.Cost
	}
	if stringValue(normalized["transport_type"], "") == "" {
		normalized["transport_type"] = inferTransport(prompt)
	}

	purpose := stringValue(normalized["trip_purpose"], "")
	if purpose == "" {
		purpose = inferPurpose(prompt)
		if parsed.Parsed.PeopleCount > 2 {
			purpose = "family"
		}
		if strings.Contains(prompt, "kino") || strings.Contains(prompt, "event") {
			purpose = "event"
		}
		normalized["trip_purpose"] = purpose
	}

	country := stringValue(normalized["destination_country"], "")
	if stringValue(normalized["destination_city"], "") == "" {
		if value := defaultCityForCountry(country); value != "" {
			normalized["destination_city"] = value
		}
	}

	return &AIPlanningResponse{
		MissingFields:    requiredMissing(normalized),
		NormalizedFields: normalized,
		VibeLabels:       buildVibeLabels(prompt, purpose, parsed.Parsed.Theme),
		VisaInsights:     visaInsightsForCountry(country),
		WeatherInsights:  weatherInsightsForCountry(country),
		ReviewSummaries:  reviewSummariesForCountry(country),
		AssistantSummary: assistantSummaryForPlan(normalized, purpose),
	}
}

func (s *Service) applyAIFields(trip *Trip, plan *AIPlanningResponse) {
	if plan == nil {
		return
	}

	trip.VibeLabels = append([]string{}, plan.VibeLabels...)
	if value, ok := plan.NormalizedFields["origin_city"].(string); ok && strings.TrimSpace(value) != "" {
		trip.OriginCity = value
	}
	if value, ok := plan.NormalizedFields["destination_country"].(string); ok && strings.TrimSpace(value) != "" {
		trip.DestinationCountry = normalizeCountry(value)
	}
	if value, ok := plan.NormalizedFields["destination_city"].(string); ok && strings.TrimSpace(value) != "" {
		trip.DestinationCity = value
	}
	if value, ok := plan.NormalizedFields["start_date"].(string); ok && strings.TrimSpace(value) != "" {
		trip.StartDate = value
	}
	if value, ok := plan.NormalizedFields["end_date"].(string); ok && strings.TrimSpace(value) != "" {
		trip.EndDate = value
	}
	if value, ok := plan.NormalizedFields["transport_type"].(string); ok && strings.TrimSpace(value) != "" {
		trip.TransportType = value
	}
	if value, ok := plan.NormalizedFields["trip_purpose"].(string); ok && strings.TrimSpace(value) != "" {
		trip.TripPurpose = value
	}
	if value, ok := plan.NormalizedFields["citizenship"].(string); ok && strings.TrimSpace(value) != "" {
		trip.Citizenship = value
	}
	switch value := plan.NormalizedFields["budget"].(type) {
	case int:
		if value > 0 {
			trip.Budget = value
		}
	case float64:
		if value > 0 {
			trip.Budget = int(value)
		}
	}

	if trip.OriginCity == "" {
		trip.OriginCity = "Almaty"
	}
	if trip.TransportType == "" {
		trip.TransportType = "flight"
	}
	if trip.TripPurpose == "" {
		trip.TripPurpose = inferPurpose(strings.ToLower(trip.Title))
	}
	if trip.Citizenship == "" {
		trip.Citizenship = "Kazakhstan"
	}
}

func (s *Service) enrichTripFromSeed(trip *Trip) {
	ref, err := s.repo.LoadDestinationReference(trip.DestinationCountry, trip.DestinationCity)
	if err != nil {
		ref = fallbackDestinationReference(trip.DestinationCountry, trip.DestinationCity)
	}

	trip.DestinationCountry = ref.CountryName
	if trip.DestinationCity == "" {
		trip.DestinationCity = ref.CityName
	}

	trip.TransportOptions = transportOptionsFromReference(ref, trip.OriginCity, trip.TransportType)
	if len(trip.TransportOptions) > 0 {
		trip.TransportOptions[0].Selected = true
		selected := trip.TransportOptions[0]
		trip.SelectedTransport = &selected
	}

	trip.HotelOptions = hotelOptionsFromReference(ref)
	if len(trip.HotelOptions) > 0 {
		trip.HotelOptions[0].Selected = true
		selected := trip.HotelOptions[0]
		trip.SelectedHotel = &selected
	}

	trip.Activities = activityItemsFromReference(ref)
	trip.VisaInfo = visaInsightsForCountry(ref.CountryName)
	trip.ReviewSummaries = reviewSummariesFromReference(ref)
	trip.BudgetSummary = BudgetSummary{
		TransportTotal:          selectedTransportPrice(trip),
		HotelTotal:              selectedHotelPrice(trip),
		EventsTotal:             activitiesTotal(trip.Activities),
		EstimatedFoodTotal:      ref.FoodEstimate,
		EstimatedLocalTransport: ref.LocalTransportCost,
		InsuranceEstimate:       ref.InsuranceEstimate,
		Currency:                "KZT",
	}
	s.recalculateBudget(trip)
	s.rebuildTodoSections(trip)
}

func (s *Service) rebuildTodoSections(trip *Trip) {
	transportItems := []TodoItem{}
	if trip.SelectedTransport != nil {
		transportItems = append(transportItems, TodoItem{ID: trip.SelectedTransport.ID, Kind: "transport", Title: trip.SelectedTransport.Title, Description: trip.SelectedTransport.Description, Status: "selected", Price: trip.SelectedTransport.Price})
	}

	hotelItems := []TodoItem{}
	if trip.SelectedHotel != nil {
		hotelItems = append(hotelItems, TodoItem{ID: trip.SelectedHotel.ID, Kind: "hotel", Title: trip.SelectedHotel.Name, Description: trip.SelectedHotel.Description, Status: "selected", Price: trip.SelectedHotel.Price, Link: trip.SelectedHotel.ReviewLink})
	}

	activityItems := make([]TodoItem, 0, len(trip.Activities))
	for _, activity := range trip.Activities {
		activityItems = append(activityItems, TodoItem{ID: activity.ID, Kind: activity.Kind, Title: activity.Title, Description: activity.Description, Status: "planned", DayLabel: activity.DayLabel, Price: activity.Price, Link: activity.SourceLink})
	}

	trip.TodoSections = []TodoSection{
		{ID: "transport", Title: "Transport", Items: transportItems},
		{ID: "hotel", Title: "Hotel", Items: hotelItems},
		{ID: "activities", Title: "Places and Events", Items: activityItems},
		{ID: "trip-info", Title: "Trip Essentials", Items: []TodoItem{{ID: uuid.New(), Kind: "visa", Title: "Visa and documents", Description: trip.VisaInfo.Requirement, Status: "check"}}},
	}
}

func normalizeCountry(value string) string {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "kazakhstan", "казахстан", "kz":
		return "Kazakhstan"
	case "japan", "япония", "jp":
		return "Japan"
	case "germany", "германия", "de":
		return "Germany"
	default:
		return strings.TrimSpace(value)
	}
}

func defaultCityForCountry(country string) string {
	switch normalizeCountry(country) {
	case "Kazakhstan":
		return "Almaty"
	case "Japan":
		return "Tokyo"
	case "Germany":
		return "Berlin"
	default:
		return ""
	}
}

func visaInsightsForCountry(country string) VisaInfo {
	switch normalizeCountry(country) {
	case "Japan":
		return VisaInfo{Country: "Japan", Requirement: "Prototype shows a visa-assistant style checklist", RecommendedLead: "Begin visa preparation 30 days before departure", Checklist: []string{"Passport", "Application form", "Hotel proof", "Trip itinerary", "Insurance"}, Notes: "Mock data for the hackathon prototype"}
	case "Germany":
		return VisaInfo{Country: "Germany", Requirement: "Visa rules depend on passport in real life; MVP shows a simplified assistant", RecommendedLead: "Check requirements 14 days before departure", Checklist: []string{"Passport validity", "Flight booking", "Hotel booking", "Travel insurance"}, Notes: "Prototype uses simplified visa assistant copy"}
	default:
		return VisaInfo{Country: "Kazakhstan", Requirement: "No visa required for domestic travelers in this prototype", RecommendedLead: "No lead time required", Checklist: []string{"Valid local ID", "Travel tickets", "Hotel confirmation"}, Notes: "Domestic route mock scenario"}
	}
}

func weatherInsightsForCountry(country string) []string {
	switch normalizeCountry(country) {
	case "Japan":
		return []string{"Spring and autumn are the most comfortable seasons for family travel.", "Plan city days with indoor backups because weather can shift quickly."}
	case "Germany":
		return []string{"Spring and early autumn usually balance comfortable weather and city walking.", "Museum and indoor options help keep family plans flexible."}
	default:
		return []string{"Weather and seasonality are shown as guidance, not real-time facts.", "AI suggestions should be checked again closer to departure."}
	}
}

func reviewSummariesForCountry(country string) []ReviewSummary {
	switch normalizeCountry(country) {
	case "Japan":
		return []ReviewSummary{
			{ID: uuid.New(), Kind: "hotel", TargetName: "Tokyo Family Smart Hotel", Summary: "Review summary highlights cleanliness, transit access, and family room comfort.", SourceName: "Tripadvisor", SourceLink: "https://tripadvisor.com"},
			{ID: uuid.New(), Kind: "place", TargetName: "Asakusa and Senso-ji", Summary: "Visitors mention strong atmosphere and easy family-friendly exploration.", SourceName: "Google Maps", SourceLink: "https://maps.google.com/?q=Sensoji"},
		}
	case "Germany":
		return []ReviewSummary{
			{ID: uuid.New(), Kind: "hotel", TargetName: "Berlin Family Central Hotel", Summary: "Guests highlight breakfast, family rooms, and proximity to major sights.", SourceName: "Tripadvisor", SourceLink: "https://tripadvisor.com"},
			{ID: uuid.New(), Kind: "place", TargetName: "Brandenburg Gate", Summary: "Visitors rate it as a must-see stop in central Berlin.", SourceName: "Google Maps", SourceLink: "https://maps.google.com/?q=Brandenburg+Gate"},
		}
	default:
		return []ReviewSummary{
			{ID: uuid.New(), Kind: "hotel", TargetName: "Family View Almaty", Summary: "Families praise the location, breakfast, and easy access to sights.", SourceName: "Google Maps", SourceLink: "https://maps.google.com/?q=Almaty+hotel"},
			{ID: uuid.New(), Kind: "event", TargetName: "Kino.kz Family Movie", Summary: "Easy add-on entertainment for families with children.", SourceName: "Kino.kz", SourceLink: "https://kino.kz"},
		}
	}
}

func buildVibeLabels(prompt, purpose, theme string) []string {
	labels := []string{purpose}
	if value := strings.TrimSpace(strings.ToLower(theme)); value != "" {
		labels = append(labels, value)
	}
	switch purpose {
	case "solo":
		labels = append(labels, "city-break")
	case "event":
		labels = append(labels, "urban", "flexible")
	default:
		if strings.Contains(prompt, "budget") {
			labels = append(labels, "budget", "balanced")
		} else {
			labels = append(labels, "comfort", "planner")
		}
	}
	return uniqueStrings(labels)
}

func assistantSummaryForPlan(normalized map[string]any, purpose string) string {
	city := stringValue(normalized["destination_city"], "your destination")
	if len(requiredMissing(normalized)) > 0 {
		return fmt.Sprintf("I collected part of the %s trip context. I still need a few fields before building the full plan.", purpose)
	}
	return fmt.Sprintf("I collected the trip context and prepared a %s plan for %s.", purpose, city)
}

func cloneStringAnyMap(src map[string]any) map[string]any {
	if src == nil {
		return nil
	}
	out := make(map[string]any, len(src))
	for key, value := range src {
		out[key] = value
	}
	return out
}

func uniqueStrings(items []string) []string {
	seen := map[string]struct{}{}
	out := make([]string, 0, len(items))
	for _, item := range items {
		value := strings.TrimSpace(item)
		if value == "" {
			continue
		}
		if _, ok := seen[value]; ok {
			continue
		}
		seen[value] = struct{}{}
		out = append(out, value)
	}
	return out
}
