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
	seed := buildDestinationSeed(trip.DestinationCountry, trip.OriginCity, trip.TransportType)
	trip.DestinationCountry = seed.Country
	if trip.DestinationCity == "" {
		trip.DestinationCity = seed.City
	}

	trip.TransportOptions = make([]TransportOption, 0, len(seed.Transport))
	for _, option := range seed.Transport {
		trip.TransportOptions = append(trip.TransportOptions, TransportOption{
			ID:          uuid.New(),
			Mode:        option.Mode,
			Provider:    option.Provider,
			Title:       option.Title,
			Origin:      option.Origin,
			Destination: option.Destination,
			Departure:   option.Departure,
			Arrival:     option.Arrival,
			Price:       option.Price,
			Currency:    option.Currency,
			Description: option.Description,
		})
	}
	if len(trip.TransportOptions) > 0 {
		trip.TransportOptions[0].Selected = true
		selected := trip.TransportOptions[0]
		trip.SelectedTransport = &selected
	}

	trip.HotelOptions = make([]HotelOption, 0, len(seed.Hotels))
	for _, option := range seed.Hotels {
		trip.HotelOptions = append(trip.HotelOptions, HotelOption{
			ID:          uuid.New(),
			Provider:    option.Provider,
			Name:        option.Name,
			Location:    option.Location,
			Price:       option.Price,
			Currency:    option.Currency,
			Rating:      option.Rating,
			Description: option.Description,
			ReviewLink:  option.ReviewLink,
		})
	}
	if len(trip.HotelOptions) > 0 {
		trip.HotelOptions[0].Selected = true
		selected := trip.HotelOptions[0]
		trip.SelectedHotel = &selected
	}

	trip.Activities = make([]ActivityItem, 0, len(seed.Activities))
	for _, item := range seed.Activities {
		trip.Activities = append(trip.Activities, ActivityItem{
			ID:          uuid.New(),
			Kind:        item.Kind,
			Title:       item.Title,
			Location:    item.Location,
			DayLabel:    item.DayLabel,
			Price:       item.Price,
			Currency:    item.Currency,
			SourceName:  item.SourceName,
			SourceLink:  item.SourceLink,
			Description: item.Description,
		})
	}

	trip.VisaInfo = VisaInfo{
		Country:         seed.Visa.Country,
		Requirement:     seed.Visa.Requirement,
		RecommendedLead: seed.Visa.RecommendedLead,
		Checklist:       append([]string{}, seed.Visa.Checklist...),
		Notes:           seed.Visa.Notes,
	}

	trip.ReviewSummaries = make([]ReviewSummary, 0, len(seed.Reviews))
	for _, item := range seed.Reviews {
		trip.ReviewSummaries = append(trip.ReviewSummaries, ReviewSummary{
			ID:         uuid.New(),
			Kind:       item.Kind,
			TargetName: item.TargetName,
			Summary:    item.Summary,
			SourceName: item.SourceName,
			SourceLink: item.SourceLink,
		})
	}

	trip.BudgetSummary = BudgetSummary{
		TransportTotal:          selectedTransportPrice(trip),
		HotelTotal:              selectedHotelPrice(trip),
		EventsTotal:             activitiesTotal(trip.Activities),
		EstimatedFoodTotal:      seed.FoodEstimate,
		EstimatedLocalTransport: seed.LocalTransport,
		InsuranceEstimate:       seed.InsuranceEstimate,
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
	case "turkey", "turkiye", "türkiye", "турция", "tr":
		return "Turkey"
	case "uae", "united arab emirates", "emirates", "оаэ", "ae":
		return "UAE"
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
	case "Turkey":
		return "Istanbul"
	case "UAE":
		return "Dubai"
	case "Germany":
		return "Berlin"
	default:
		return ""
	}
}

func visaInsightsForCountry(country string) VisaInfo {
	seed := buildDestinationSeed(country, "Almaty", "flight")
	return VisaInfo{
		Country:         seed.Visa.Country,
		Requirement:     seed.Visa.Requirement,
		RecommendedLead: seed.Visa.RecommendedLead,
		Checklist:       append([]string{}, seed.Visa.Checklist...),
		Notes:           seed.Visa.Notes,
	}
}

func weatherInsightsForCountry(country string) []string {
	switch normalizeCountry(country) {
	case "Japan":
		return []string{"Spring and autumn are the most comfortable seasons for family travel.", "Plan city days with indoor backups because weather can shift quickly."}
	case "Turkey":
		return []string{"Shoulder seasons usually balance comfortable weather and better pricing.", "Event and sightseeing plans work best with evening outdoor slots in warmer months."}
	case "UAE":
		return []string{"Outdoor-heavy itineraries fit best in cooler months.", "Daytime heat can affect family comfort, so evening activities are often better."}
	default:
		return []string{"Weather and seasonality are shown as guidance, not real-time facts.", "AI suggestions should be checked again closer to departure."}
	}
}

func reviewSummariesForCountry(country string) []ReviewSummary {
	seed := buildDestinationSeed(country, "Almaty", "flight")
	items := make([]ReviewSummary, 0, len(seed.Reviews))
	for _, review := range seed.Reviews {
		items = append(items, ReviewSummary{
			ID:         uuid.New(),
			Kind:       review.Kind,
			TargetName: review.TargetName,
			Summary:    review.Summary,
			SourceName: review.SourceName,
			SourceLink: review.SourceLink,
		})
	}
	return items
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
