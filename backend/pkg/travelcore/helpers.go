package travelcore

import (
	"fmt"
	"math"
	"regexp"
	"strings"
	"time"

	"github.com/google/uuid"
)

type destinationReference struct {
	CountryCode        string
	CountryName        string
	CityName           string
	CityRegion         string
	CityDescription    string
	Attractions        []referenceAttraction
	Restaurants        []referenceRestaurant
	Events             []referenceEvent
	FoodEstimate       int
	LocalTransportCost int
	InsuranceEstimate  int
}

type referenceAttraction struct {
	Name        string `db:"name_en"`
	Category    string `db:"category"`
	Description string `db:"description"`
	DurationMin int    `db:"recommended_duration_minutes"`
	PriceLevel  string `db:"price_level"`
}

type referenceRestaurant struct {
	Name        string `db:"name"`
	Cuisine     string `db:"cuisine"`
	PriceLevel  string `db:"price_level"`
	Description string `db:"description"`
	Area        string `db:"area"`
}

type referenceEvent struct {
	Name        string `db:"name_en"`
	Category    string `db:"category"`
	Description string `db:"description"`
	TravelTip   string `db:"travel_tip"`
}

type countryRow struct {
	CountryCode string `db:"country_code"`
	NameEn      string `db:"name_en"`
}

type cityRow struct {
	CityID      int    `db:"city_id"`
	CountryCode string `db:"country_code"`
	NameEn      string `db:"name_en"`
	Region      string `db:"region"`
	Description string `db:"description"`
}

func cloneTrip(src *TripState) *TripState {
	if src == nil {
		return nil
	}
	cp := *src
	cp.VibeLabels = append([]string{}, src.VibeLabels...)
	cp.HotelPreferences = append([]string{}, src.HotelPreferences...)
	cp.Interests = append([]string{}, src.Interests...)
	cp.Travelers = cloneTravelers(src.Travelers)
	cp.TodoSections = cloneTodoSections(src.TodoSections)
	cp.TransportOptions = append([]TransportOption{}, src.TransportOptions...)
	cp.HotelOptions = append([]HotelOption{}, src.HotelOptions...)
	cp.Activities = append([]ActivityItem{}, src.Activities...)
	cp.ReviewSummaries = append([]ReviewSummary{}, src.ReviewSummaries...)
	cp.Offers.Highlights = append([]string{}, src.Offers.Highlights...)
	cp.VisaInfo.Checklist = append([]string{}, src.VisaInfo.Checklist...)
	if src.SelectedTransport != nil {
		selected := *src.SelectedTransport
		cp.SelectedTransport = &selected
	}
	if src.SelectedHotel != nil {
		selected := *src.SelectedHotel
		cp.SelectedHotel = &selected
	}
	return &cp
}

func cloneSession(src *ChatSession) *ChatSession {
	if src == nil {
		return nil
	}
	cp := *src
	cp.Messages = cloneMessages(src.Messages)
	return &cp
}

func cloneTravelers(src []Traveler) []Traveler {
	if src == nil {
		return nil
	}
	out := make([]Traveler, 0, len(src))
	for _, traveler := range src {
		cp := traveler
		cp.Preferences = append([]string{}, traveler.Preferences...)
		out = append(out, cp)
	}
	return out
}

func cloneTodoSections(src []TodoSection) []TodoSection {
	if src == nil {
		return nil
	}
	out := make([]TodoSection, 0, len(src))
	for _, section := range src {
		cp := section
		cp.Items = append([]TodoItem{}, section.Items...)
		out = append(out, cp)
	}
	return out
}

func cloneMessages(src []ChatMessage) []ChatMessage {
	if src == nil {
		return nil
	}
	out := make([]ChatMessage, 0, len(src))
	for _, message := range src {
		cp := message
		cp.Structured = cloneMap(cp.Structured)
		out = append(out, cp)
	}
	return out
}

func cloneMap(src map[string]any) map[string]any {
	if src == nil {
		return nil
	}
	out := make(map[string]any, len(src))
	for key, value := range src {
		switch typed := value.(type) {
		case []string:
			out[key] = append([]string{}, typed...)
		default:
			out[key] = typed
		}
	}
	return out
}

func (r *Repository) LoadDestinationReference(country, city string) (*destinationReference, error) {
	if r.db == nil || r.db.DB == nil {
		return nil, fmt.Errorf("failed to load destination reference: database is not configured")
	}

	normalizedCountry := normalizeCountry(country)
	if strings.TrimSpace(normalizedCountry) == "" {
		normalizedCountry = "Germany"
	}

	var countryRow countryRow
	if err := r.db.TrackedGet(&countryRow, r.db.Rebind(`
		SELECT country_code, name_en
		FROM travel_countries
		WHERE name_en = ?
		LIMIT 1
	`), normalizedCountry); err != nil {
		return nil, fmt.Errorf("failed to load country reference: %w", err)
	}

	cityRow, err := r.loadCityRow(countryRow.CountryCode, city)
	if err != nil {
		return nil, err
	}

	ref := &destinationReference{
		CountryCode:     countryRow.CountryCode,
		CountryName:     countryRow.NameEn,
		CityName:        cityRow.NameEn,
		CityRegion:      cityRow.Region,
		CityDescription: cityRow.Description,
	}

	if err := r.loadReferenceCollections(ref, cityRow.CityID, countryRow.CountryCode); err != nil {
		return nil, err
	}

	ref.FoodEstimate = estimateFoodTotal(ref.CountryName)
	ref.LocalTransportCost = estimateLocalTransportTotal(ref.CountryName)
	ref.InsuranceEstimate = estimateInsuranceTotal(ref.CountryName)
	return ref, nil
}

func (r *Repository) loadCityRow(countryCode, preferredCity string) (cityRow, error) {
	var row cityRow
	var err error

	if strings.TrimSpace(preferredCity) != "" {
		err = r.db.TrackedGet(&row, r.db.Rebind(`
			SELECT city_id, country_code, name_en, region, description
			FROM travel_cities
			WHERE country_code = ? AND name_en = ?
			LIMIT 1
		`), countryCode, strings.TrimSpace(preferredCity))
		if err == nil {
			return row, nil
		}
	}

	err = r.db.TrackedGet(&row, r.db.Rebind(`
		SELECT city_id, country_code, name_en, region, description
		FROM travel_cities
		WHERE country_code = ?
		ORDER BY city_id
		LIMIT 1
	`), countryCode)
	if err != nil {
		return cityRow{}, fmt.Errorf("failed to load city reference: %w", err)
	}
	return row, nil
}

func (r *Repository) loadReferenceCollections(ref *destinationReference, cityID int, countryCode string) error {
	attractions := []referenceAttraction{}
	if err := r.db.TrackedSelect(&attractions, r.db.Rebind(`
		SELECT name_en, category, description, recommended_duration_minutes, price_level
		FROM travel_attractions
		WHERE city_id = ?
		ORDER BY attraction_id
		LIMIT 4
	`), cityID); err != nil {
		return fmt.Errorf("failed to load attractions: %w", err)
	}

	restaurants := []referenceRestaurant{}
	if err := r.db.TrackedSelect(&restaurants, r.db.Rebind(`
		SELECT name, cuisine, price_level, description, area
		FROM popular_restaurants
		WHERE city_id = ?
		ORDER BY restaurant_id
		LIMIT 2
	`), cityID); err != nil {
		return fmt.Errorf("failed to load restaurants: %w", err)
	}

	events := []referenceEvent{}
	if err := r.db.TrackedSelect(&events, r.db.Rebind(`
		SELECT name_en, category, description, travel_tip
		FROM seasonal_events
		WHERE country_code = ? AND (city_id = ? OR city_id IS NULL)
		ORDER BY city_id DESC NULLS LAST, seasonal_event_id
		LIMIT 3
	`), countryCode, cityID); err != nil {
		return fmt.Errorf("failed to load seasonal events: %w", err)
	}

	ref.Attractions = attractions
	ref.Restaurants = restaurants
	ref.Events = events
	return nil
}

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
		VisaInsights:     legacyVisaInsightsForCountry(country),
		WeatherInsights:  weatherInsightsForCountry(country),
		ReviewSummaries:  reviewSummariesForCountry(country),
		AssistantSummary: assistantSummaryForPlan(normalized, purpose),
	}
}

func (s *CoreService) applyAIFields(trip *TripState, plan *AIPlanningResponse) {
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

func (s *CoreService) enrichTripFromSeed(trip *TripState) {
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
	trip.VisaInfo = legacyVisaInsightsForCountry(ref.CountryName)
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

func (s *CoreService) rebuildTodoSections(trip *TripState) {
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
	case "kazakhstan", "кaзахстан", "kz":
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

func legacyVisaInsightsForCountry(country string) LegacyVisaInfo {
	switch normalizeCountry(country) {
	case "Japan":
		return LegacyVisaInfo{Country: "Japan", Requirement: "Prototype shows a visa-assistant style checklist", RecommendedLead: "Begin visa preparation 30 days before departure", Checklist: []string{"Passport", "Application form", "Hotel proof", "Trip itinerary", "Insurance"}, Notes: "Mock data for the hackathon prototype"}
	case "Germany":
		return LegacyVisaInfo{Country: "Germany", Requirement: "Visa rules depend on passport in real life; MVP shows a simplified assistant", RecommendedLead: "Check requirements 14 days before departure", Checklist: []string{"Passport validity", "Flight booking", "Hotel booking", "Travel insurance"}, Notes: "Prototype uses simplified visa assistant copy"}
	default:
		return LegacyVisaInfo{Country: "Kazakhstan", Requirement: "No visa required for domestic travelers in this prototype", RecommendedLead: "No lead time required", Checklist: []string{"Valid local ID", "Travel tickets", "Hotel confirmation"}, Notes: "Domestic route mock scenario"}
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
	if strings.Contains(prompt, "train") || strings.Contains(prompt, "rail") {
		return "train"
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

func inferOriginCity(prompt string) string {
	switch {
	case strings.Contains(prompt, "almaty"):
		return "Almaty"
	case strings.Contains(prompt, "astana"):
		return "Astana"
	default:
		return ""
	}
}

func inferCitizenship(prompt string) string {
	switch {
	case strings.Contains(prompt, "kazakhstan"):
		return "Kazakhstan"
	case strings.Contains(prompt, "germany"):
		return "Germany"
	case strings.Contains(prompt, "japan"):
		return "Japan"
	default:
		return ""
	}
}

func inferPromptDates(prompt string) (string, string) {
	re := regexp.MustCompile(`\b\d{4}-\d{2}-\d{2}\b`)
	matches := re.FindAllString(prompt, -1)
	if len(matches) == 0 {
		return "", ""
	}
	if len(matches) == 1 {
		return matches[0], ""
	}
	return matches[0], matches[1]
}

func inferExplicitBudget(prompt string) int {
	re := regexp.MustCompile(`\b(\d{5,7})\b`)
	match := re.FindStringSubmatch(prompt)
	if len(match) < 2 {
		return 0
	}
	value := match[1]
	switch {
	case strings.HasPrefix(value, "9"):
		return 900000
	case strings.HasPrefix(value, "5"):
		return 500000
	default:
		return inferBudget(prompt)
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

func fallbackDestinationReference(country, city string) *destinationReference {
	normalizedCountry := normalizeCountry(country)
	if normalizedCountry == "" {
		normalizedCountry = "Germany"
	}
	resolvedCity := strings.TrimSpace(city)
	if resolvedCity == "" {
		resolvedCity = defaultCityForCountry(normalizedCountry)
	}
	code := countryCodeForCountry(normalizedCountry)
	return &destinationReference{
		CountryCode:        code,
		CountryName:        normalizedCountry,
		CityName:           resolvedCity,
		FoodEstimate:       estimateFoodTotal(normalizedCountry),
		LocalTransportCost: estimateLocalTransportTotal(normalizedCountry),
		InsuranceEstimate:  estimateInsuranceTotal(normalizedCountry),
	}
}

func transportOptionsFromReference(ref *destinationReference, origin, transportType string) []TransportOption {
	if ref == nil {
		return nil
	}
	mode := strings.TrimSpace(transportType)
	if mode == "" {
		mode = "flight"
	}
	if strings.TrimSpace(origin) == "" {
		origin = "Almaty"
	}

	primaryProvider := "Air Astana"
	primaryPrice := 58000
	secondaryProvider := "Kazakhstan Railways"
	secondaryMode := "train"
	secondaryPrice := 32000

	switch normalizeCountry(ref.CountryName) {
	case "Japan":
		primaryProvider = "JAL Mock"
		primaryPrice = 395000
		secondaryProvider = "ANA Mock"
		secondaryMode = "flight"
		secondaryPrice = 348000
	case "Germany":
		primaryProvider = "Lufthansa Mock"
		primaryPrice = 245000
		secondaryProvider = "Air Astana"
		secondaryMode = "flight"
		secondaryPrice = 198000
	}

	return []TransportOption{
		{
			ID:          uuid.New(),
			Mode:        mode,
			Provider:    primaryProvider,
			Title:       fmt.Sprintf("%s -> %s", origin, ref.CityName),
			Origin:      origin,
			Destination: ref.CityName,
			Departure:   "08:00",
			Arrival:     "12:00",
			Price:       primaryPrice,
			Currency:    "KZT",
			Description: "Primary mock transport option derived from destination reference",
		},
		{
			ID:          uuid.New(),
			Mode:        secondaryMode,
			Provider:    secondaryProvider,
			Title:       fmt.Sprintf("%s -> %s", origin, ref.CityName),
			Origin:      origin,
			Destination: ref.CityName,
			Departure:   "20:00",
			Arrival:     "08:00",
			Price:       secondaryPrice,
			Currency:    "KZT",
			Description: "Alternative mock transport option derived from destination reference",
		},
	}
}

func hotelOptionsFromReference(ref *destinationReference) []HotelOption {
	if ref == nil {
		return nil
	}
	city := ref.CityName
	primaryArea := city + " center"
	secondaryArea := city + " old town"
	primaryPrice := 95000
	secondaryPrice := 61000
	primaryRating := 4.7
	secondaryRating := 4.3

	switch normalizeCountry(ref.CountryName) {
	case "Japan":
		primaryArea = "Shinjuku"
		secondaryArea = "Ueno"
		primaryPrice = 355000
		secondaryPrice = 240000
		primaryRating = 4.8
		secondaryRating = 4.3
	case "Germany":
		primaryArea = "Mitte"
		secondaryArea = "Prenzlauer Berg"
		primaryPrice = 225000
		secondaryPrice = 162000
		primaryRating = 4.8
		secondaryRating = 4.2
	}

	return []HotelOption{
		{
			ID:          uuid.New(),
			Provider:    "Booking Mock",
			Name:        city + " Family Central Hotel",
			Location:    primaryArea,
			Price:       primaryPrice,
			Currency:    "KZT",
			Rating:      primaryRating,
			Description: "Mock hotel option near key destinations",
			ReviewLink:  "https://tripadvisor.com",
		},
		{
			ID:          uuid.New(),
			Provider:    "Booking Mock",
			Name:        city + " Smart Budget Stay",
			Location:    secondaryArea,
			Price:       secondaryPrice,
			Currency:    "KZT",
			Rating:      secondaryRating,
			Description: "Mock lower-cost stay with decent access",
			ReviewLink:  "https://maps.google.com/?q=" + strings.ReplaceAll(city, " ", "+") + "+hotel",
		},
	}
}

func activityItemsFromReference(ref *destinationReference) []ActivityItem {
	if ref == nil {
		return nil
	}
	items := make([]ActivityItem, 0, len(ref.Attractions)+len(ref.Events))
	for i, attraction := range ref.Attractions {
		items = append(items, ActivityItem{
			ID:          uuid.New(),
			Kind:        activityKind(attraction.Category),
			Title:       attraction.Name,
			Location:    ref.CityName,
			DayLabel:    fmt.Sprintf("Day %d", i+1),
			Price:       priceFromLevel(attraction.PriceLevel),
			Currency:    "KZT",
			SourceName:  "Google Maps",
			SourceLink:  "https://maps.google.com/?q=" + strings.ReplaceAll(attraction.Name, " ", "+"),
			Description: attraction.Description,
		})
	}
	for i, event := range ref.Events {
		items = append(items, ActivityItem{
			ID:          uuid.New(),
			Kind:        "event",
			Title:       event.Name,
			Location:    ref.CityName,
			DayLabel:    fmt.Sprintf("Day %d", i+1),
			Price:       18000 + (i * 4000),
			Currency:    "KZT",
			SourceName:  "Kino.kz",
			SourceLink:  "https://kino.kz",
			Description: event.Description,
		})
	}
	return items
}

func reviewSummariesFromReference(ref *destinationReference) []ReviewSummary {
	if ref == nil {
		return nil
	}
	items := []ReviewSummary{}
	if len(ref.Restaurants) > 0 {
		items = append(items, ReviewSummary{
			ID:         uuid.New(),
			Kind:       "hotel",
			TargetName: ref.CityName + " Family Central Hotel",
			Summary:    "Mock hotel summary emphasizes location fit, transport convenience, and family usability.",
			SourceName: "Tripadvisor",
			SourceLink: "https://tripadvisor.com",
		})
	}
	for _, attraction := range ref.Attractions {
		items = append(items, ReviewSummary{
			ID:         uuid.New(),
			Kind:       "place",
			TargetName: attraction.Name,
			Summary:    "Reference-based summary highlights why this stop fits the trip route and theme.",
			SourceName: "Google Maps",
			SourceLink: "https://maps.google.com/?q=" + strings.ReplaceAll(attraction.Name, " ", "+"),
		})
		if len(items) >= 3 {
			break
		}
	}
	return items
}

func priceFromLevel(level string) int {
	switch strings.ToLower(strings.TrimSpace(level)) {
	case "free":
		return 0
	case "budget":
		return 9000
	case "moderate":
		return 18000
	case "premium":
		return 32000
	default:
		return 12000
	}
}

func activityKind(category string) string {
	switch strings.ToLower(strings.TrimSpace(category)) {
	case "restaurant", "food":
		return "restaurant"
	case "event":
		return "event"
	default:
		return "activity"
	}
}

func (s *CoreService) recalculateBudget(trip *TripState) {
	trip.BudgetSummary.TransportTotal = selectedTransportPrice(trip)
	trip.BudgetSummary.HotelTotal = selectedHotelPrice(trip)
	trip.BudgetSummary.EventsTotal = activitiesTotal(trip.Activities)
	trip.BudgetSummary.GrandTotal = trip.BudgetSummary.TransportTotal + trip.BudgetSummary.HotelTotal + trip.BudgetSummary.EventsTotal + trip.BudgetSummary.EstimatedFoodTotal + trip.BudgetSummary.EstimatedLocalTransport + trip.BudgetSummary.InsuranceEstimate
	trip.BudgetSummary.CashbackAmount = int(float64(trip.BudgetSummary.GrandTotal) * 0.05)
	trip.BudgetSummary.BonusAmount = int(float64(trip.BudgetSummary.GrandTotal) * 0.02)
	trip.BudgetSummary.HalykOfferLabel = "Pay fully with Halyk card to unlock cashback"
	trip.Offers = OfferSummary{
		CashbackAmount: trip.BudgetSummary.CashbackAmount,
		BonusAmount:    trip.BudgetSummary.BonusAmount,
		HalykOffer:     trip.BudgetSummary.HalykOfferLabel,
		Highlights:     []string{"Cashback applied on full Halyk payment", "Insurance added into total estimate", "Planning route optimized for mobile rendering"},
	}
}

func selectedTransportPrice(trip *TripState) int {
	if trip.SelectedTransport == nil {
		return 0
	}
	return trip.SelectedTransport.Price
}

func selectedHotelPrice(trip *TripState) int {
	if trip.SelectedHotel == nil {
		return 0
	}
	return trip.SelectedHotel.Price
}

func activitiesTotal(items []ActivityItem) int {
	total := 0
	for _, item := range items {
		total += item.Price
	}
	return total
}

func estimateFoodTotal(country string) int {
	switch normalizeCountry(country) {
	case "Japan":
		return 84000
	case "Germany":
		return 62000
	default:
		return 28000
	}
}

func estimateLocalTransportTotal(country string) int {
	switch normalizeCountry(country) {
	case "Japan":
		return 36000
	case "Germany":
		return 26000
	default:
		return 18000
	}
}

func estimateInsuranceTotal(country string) int {
	switch normalizeCountry(country) {
	case "Japan":
		return 22000
	case "Germany":
		return 15000
	default:
		return 6000
	}
}

func (s *CoreService) buildPlanningTripResponse(trip *TripState) PlanningTripResponse {
	normalized := tripToMap(trip)
	keys := requiredMissing(normalized)
	return PlanningTripResponse{
		TripID:               trip.ID,
		Status:               trip.Status,
		Title:                trip.Title,
		NormalizedFields:     normalized,
		MissingFields:        missingFieldDescriptors(keys),
		ReadyForConfirmation: len(keys) == 0,
		ChatEntrypoints:      []string{"Share your travel prompt", "Answer missing field questions", "Confirm extracted details"},
		UpdatedAt:            trip.UpdatedAt,
	}
}

func planningMessages(messages []ChatMessage) []PlanningMessage {
	out := make([]PlanningMessage, 0, len(messages))
	for _, item := range messages {
		out = append(out, PlanningMessage{
			ID:         item.ID,
			Role:       item.Role,
			Content:    item.Content,
			Action:     item.Action,
			Structured: cloneMap(item.Structured),
			CreatedAt:  item.CreatedAt,
		})
	}
	return out
}

func tripToMap(trip *TripState) map[string]any {
	return map[string]any{
		"title":               trip.Title,
		"origin_city":         trip.OriginCity,
		"destination_country": trip.DestinationCountry,
		"destination_city":    trip.DestinationCity,
		"start_date":          trip.StartDate,
		"end_date":            trip.EndDate,
		"budget":              trip.Budget,
		"transport_type":      trip.TransportType,
		"trip_purpose":        trip.TripPurpose,
		"citizenship":         trip.Citizenship,
		"interests":           append([]string{}, trip.Interests...),
	}
}

func normalizeAction(value, fallback string) string {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return fallback
	}
	return trimmed
}

func missingFieldDescriptors(keys []string) []MissingField {
	labels := map[string]MissingField{
		"origin_city":         {Key: "origin_city", Label: "Origin city", Prompt: "Which city are you departing from?"},
		"destination_country": {Key: "destination_country", Label: "Destination country", Prompt: "Which country do you want to visit?"},
		"destination_city":    {Key: "destination_city", Label: "Destination city", Prompt: "Which city should the plan focus on?"},
		"start_date":          {Key: "start_date", Label: "Start date", Prompt: "What is the trip start date?"},
		"end_date":            {Key: "end_date", Label: "End date", Prompt: "What is the trip end date?"},
		"budget":              {Key: "budget", Label: "Budget", Prompt: "What total budget in KZT should the planner respect?"},
		"transport_type":      {Key: "transport_type", Label: "Transport type", Prompt: "Do you prefer flight, train, or another transport type?"},
		"trip_purpose":        {Key: "trip_purpose", Label: "Trip purpose", Prompt: "Is this trip for family, solo, event, or another purpose?"},
		"citizenship":         {Key: "citizenship", Label: "Citizenship", Prompt: "Which citizenship should be used for visa checks?"},
	}
	out := make([]MissingField, 0, len(keys))
	for _, key := range keys {
		if item, ok := labels[key]; ok {
			out = append(out, item)
			continue
		}
		out = append(out, MissingField{Key: key, Label: key, Prompt: "Please provide " + strings.ReplaceAll(key, "_", " ") + "."})
	}
	return out
}

func buildBudgetBreakdown(trip *TripState) BudgetBreakdown {
	currency := trip.BudgetSummary.Currency
	if currency == "" {
		currency = "KZT"
	}
	items := []BudgetItem{
		{Amount: float64(trip.BudgetSummary.TransportTotal), Currency: currency, Category: "flights", Title: "Primary transport"},
		{Amount: float64(trip.BudgetSummary.HotelTotal), Currency: currency, Category: "hotels", Title: "Selected hotel"},
		{Amount: float64(trip.BudgetSummary.EstimatedLocalTransport), Currency: currency, Category: "local_transport", Title: "Local transport"},
		{Amount: float64(trip.BudgetSummary.EstimatedFoodTotal), Currency: currency, Category: "food", Title: "Food estimate"},
		{Amount: float64(trip.BudgetSummary.EventsTotal), Currency: currency, Category: "activities", Title: "Activities and events"},
		{Amount: float64(trip.BudgetSummary.InsuranceEstimate), Currency: currency, Category: "insurance", Title: "Insurance"},
		{Amount: -float64(trip.BudgetSummary.CashbackAmount), Currency: currency, Category: "cashback_discount", Title: "Estimated cashback"},
	}
	return BudgetBreakdown{
		Total: EstimatedMoney{Amount: float64(trip.BudgetSummary.GrandTotal), Currency: currency, Confidence: "medium"},
		Items: items,
	}
}

func buildVisaInfo(trip *TripState) VisaInfo {
	required := normalizeCountry(trip.DestinationCountry) != "Kazakhstan"
	status := "unknown"
	switch normalizeCountry(trip.DestinationCountry) {
	case "Japan":
		status = "visa_required"
	case "Germany":
		status = "visa_required"
	case "Kazakhstan":
		status = "visa_free"
		required = false
	}
	var days *int
	var estimatedCost *Money
	if required {
		value := 14
		days = &value
		estimatedCost = &Money{Amount: 20000, Currency: "KZT"}
	}
	return VisaInfo{
		Citizenship:        stringValue(trip.Citizenship, "Kazakhstan"),
		DestinationCountry: stringValue(trip.DestinationCountry, "Kazakhstan"),
		Status:             status,
		Required:           required,
		EstimatedCost:      estimatedCost,
		ProcessingTimeDays: days,
		Notes:              trip.VisaInfo.Notes,
		Confidence:         "medium",
	}
}

func (s *CoreService) buildTripDetailsResponse(trip *TripState) TripDetailsResponse {
	currency := trip.BudgetSummary.Currency
	if currency == "" {
		currency = "KZT"
	}
	if trip.Title == "" {
		trip.Title = fmt.Sprintf("%s Trip", stringValue(trip.DestinationCity, "Planned"))
	}
	coords := coordinatesForTrip(trip)
	selectedMode := "balanced"
	mapModel, routeNavigator, segments, warnings := buildMapAndSegments(trip, coords)
	return TripDetailsResponse{
		TripID:         trip.ID.String(),
		Title:          trip.Title,
		Subtitle:       buildSubtitle(trip),
		StartDate:      trip.StartDate,
		EndDate:        trip.EndDate,
		DurationDays:   tripDurationDays(trip.StartDate, trip.EndDate),
		PeopleCount:    max(1, len(trip.Travelers)),
		Currency:       currency,
		SelectedMode:   selectedMode,
		AvailableModes: []string{"economy", "balanced", "comfort"},
		Summary: TripSummary{
			EstimatedTotalCost:     Money{Amount: float64(trip.BudgetSummary.GrandTotal), Currency: currency},
			EstimatedTotalCashback: &Money{Amount: float64(trip.BudgetSummary.CashbackAmount), Currency: currency},
			WeatherSummary:         firstString(weatherInsightsForCountry(trip.DestinationCountry)),
			VisaStatus:             buildVisaInfo(trip).Status,
			MainLabels:             uniqueStrings(append([]string{trip.TripPurpose, trip.TransportType}, trip.VibeLabels...)),
		},
		RouteNavigator: routeNavigator,
		Map:            mapModel,
		Segments:       segments,
		Budget:         buildBudgetBreakdown(trip),
		ModeVariants:   buildModeVariants(trip),
		Visa:           ptr(buildVisaInfo(trip)),
		Cashback:       ptr(buildCashbackInfo(trip)),
		Challenges:     buildChallenges(trip),
		Warnings:       warnings,
	}
}

func buildMapAndSegments(trip *TripState, coords Coordinates) (TripMap, []RouteStop, []ItinerarySegment, []SmartWarning) {
	airportMarkerID := "marker-airport-" + trip.ID.String()
	hotelMarkerID := "marker-hotel-" + trip.ID.String()
	activityMarkerID := "marker-activity-" + trip.ID.String()
	arrivalSegmentID := "segment-arrival-" + trip.ID.String()
	transferSegmentID := "segment-transfer-" + trip.ID.String()
	hotelSegmentID := "segment-hotel-" + trip.ID.String()
	daySegmentID := "segment-day-1-" + trip.ID.String()
	departureSegmentID := "segment-departure-" + trip.ID.String()
	routeID := "route-airport-hotel-" + trip.ID.String()

	markers := []MapMarker{
		{MarkerID: airportMarkerID, SegmentID: arrivalSegmentID, Type: "airport", Title: strings.ToUpper(firstN(trip.OriginCity, 3)) + " -> " + strings.ToUpper(firstN(trip.DestinationCity, 3)), Subtitle: "Arrival airport", Lat: coords.Lat + 0.12, Lng: coords.Lng + 0.12, Icon: "flight"},
		{MarkerID: hotelMarkerID, SegmentID: hotelSegmentID, Type: "hotel", Title: hotelName(trip), Subtitle: "Selected hotel", Lat: coords.Lat, Lng: coords.Lng, Icon: "hotel", Price: hotelMarkerPrice(trip), Labels: []string{"Selected", "Balanced mode"}},
		{MarkerID: activityMarkerID, SegmentID: daySegmentID, Type: "attraction", Title: firstActivityTitle(trip), Subtitle: "Day plan cluster", Lat: coords.Lat + 0.03, Lng: coords.Lng + 0.02, Icon: "activity", Labels: []string{"Main stop"}},
	}

	routes := []MapRoute{
		{
			RouteID:         routeID,
			FromMarkerID:    airportMarkerID,
			ToMarkerID:      hotelMarkerID,
			SegmentID:       transferSegmentID,
			TransportType:   "taxi",
			DistanceKm:      22.5,
			DurationMinutes: 40,
			EstimatedCost:   &Money{Amount: 8500, Currency: "KZT"},
			AlternativeRoutes: []AlternativeRoute{
				{TransportType: "public_transport", DurationMinutes: 70, EstimatedCost: &Money{Amount: 1200, Currency: "KZT"}, Reason: "Cheaper, but slower"},
			},
		},
	}

	hotelPrice := Money{Amount: float64(selectedHotelPrice(trip)), Currency: budgetCurrency(trip)}
	segments := []ItinerarySegment{
		{
			SegmentID: arrivalSegmentID, Type: "arrival", Title: "Arrival in " + stringValue(trip.DestinationCity, "destination"), Date: trip.StartDate, DayNumber: 1, StartTime: "08:00", EndTime: "12:00", Icon: "flight", Status: "planned",
			LinkedMarkerIDs: []string{airportMarkerID}, Labels: []string{"Planned"}, Description: "Arrival leg generated from the selected transport option.",
			Details: SegmentDetails{Kind: "arrival", Payload: map[string]any{"flight": map[string]any{"fromAirport": strings.ToUpper(firstN(trip.OriginCity, 3)), "toAirport": strings.ToUpper(firstN(trip.DestinationCity, 3)), "airline": selectedTransportProvider(trip), "flightNumber": "HT100", "departureTime": "08:00", "arrivalTime": "12:00", "durationMinutes": 240, "stops": 0, "cabinClass": "economy", "price": hotelPrice}}},
		},
		{
			SegmentID: transferSegmentID, Type: "transfer", Title: "Transfer to hotel", Date: trip.StartDate, DayNumber: 1, StartTime: "12:30", EndTime: "13:10", Icon: "taxi", Status: "planned",
			LinkedMarkerIDs: []string{airportMarkerID, hotelMarkerID}, LinkedRouteIDs: []string{routeID}, Labels: []string{"Fastest route"}, Description: "Recommended transfer from airport to the selected hotel.",
			Details: SegmentDetails{Kind: "transfer", Payload: map[string]any{"from": "Airport", "to": hotelName(trip), "recommendedTransport": "taxi", "distanceKm": 22.5, "durationMinutes": 40, "taxiEstimate": Money{Amount: 8500, Currency: budgetCurrency(trip)}, "publicTransportEstimate": map[string]any{"amount": 1200, "currency": budgetCurrency(trip), "durationMinutes": 70}, "reason": "Best balance between simplicity and travel time after arrival."}},
		},
		{
			SegmentID: hotelSegmentID, Type: "hotel_stay", Title: hotelName(trip), Date: trip.StartDate, DayNumber: 1, StartTime: "14:00", Icon: "hotel", Status: "selected",
			LinkedMarkerIDs: []string{hotelMarkerID}, Labels: []string{"Selected hotel"}, Description: "Primary hotel selected for the generated bundle.", Price: &hotelPrice,
			Details: SegmentDetails{Kind: "hotel", Payload: map[string]any{"hotelId": hotelID(trip), "name": hotelName(trip), "district": hotelDistrict(trip), "stars": 4, "rating": hotelRatingValue(trip), "ratingLabel": "Great fit", "reviewShortSummary": "Strong location fit for the selected route.", "selectedRoomId": hotelID(trip) + "-room-selected", "selectedRoomName": "Standard Room", "pricePerNight": Money{Amount: float64(selectedHotelPrice(trip) / max(1, tripDurationDays(trip.StartDate, trip.EndDate))), Currency: budgetCurrency(trip)}, "nights": max(1, tripDurationDays(trip.StartDate, trip.EndDate)-1), "downgradeLabel": "Save more with a smaller room", "upgradeLabel": "Upgrade for better location and comfort", "distanceToMainClusterKm": 2.1, "averageTaxiToActivities": Money{Amount: 2500, Currency: budgetCurrency(trip)}, "locationScore": 8.5, "priceScore": 8.1, "reason": "Best balance between route convenience and budget."}},
		},
		{
			SegmentID: daySegmentID, Type: "day_itinerary", Title: "Main itinerary day", Date: trip.StartDate, DayNumber: 1, Icon: "map", Status: "planned",
			LinkedMarkerIDs: []string{activityMarkerID}, Labels: []string{"AI planned"}, Description: "Daily cluster assembled from selected activities and destination seed data.",
			Details: SegmentDetails{Kind: "day_itinerary", Payload: map[string]any{"city": stringValue(trip.DestinationCity, "Destination"), "experienceCount": len(trip.Activities), "weather": map[string]any{"temperatureC": 24, "condition": "sunny", "rainChancePercent": 20}, "pace": "medium", "overloadScore": 0.34, "activities": buildSegmentActivities(trip, activityMarkerID)}},
		},
		{
			SegmentID: departureSegmentID, Type: "departure", Title: "Departure", Date: trip.EndDate, DayNumber: max(1, tripDurationDays(trip.StartDate, trip.EndDate)), StartTime: "18:00", EndTime: "22:00", Icon: "flight", Status: "planned",
			LinkedMarkerIDs: []string{airportMarkerID}, Labels: []string{"Return"}, Description: "Return segment for the selected trip bundle.",
			Details: SegmentDetails{Kind: "departure", Payload: map[string]any{"flight": map[string]any{"fromAirport": strings.ToUpper(firstN(trip.DestinationCity, 3)), "toAirport": strings.ToUpper(firstN(trip.OriginCity, 3)), "airline": selectedTransportProvider(trip), "flightNumber": "HT101", "departureTime": "18:00", "arrivalTime": "22:00", "durationMinutes": 240, "stops": 0, "cabinClass": "economy"}, "checkoutTime": "12:00", "recommendedLeaveHotelTime": "16:45"}},
		},
	}

	warnings := buildWarnings(trip, transferSegmentID)
	mapModel := TripMap{InitialCamera: MapCamera{CenterLat: coords.Lat, CenterLng: coords.Lng, Zoom: 11}, Markers: markers, Routes: routes}
	routeNavigator := []RouteStop{{StopID: "stop-" + trip.ID.String(), Title: stringValue(trip.DestinationCity, "Destination"), StartDate: trip.StartDate, EndDate: trip.EndDate, TransportToNext: trip.TransportType, Coordinates: &coords}}
	return mapModel, routeNavigator, segments, warnings
}

func buildSegmentActivities(trip *TripState, markerID string) []map[string]any {
	items := make([]map[string]any, 0, len(trip.Activities))
	for _, activity := range trip.Activities {
		items = append(items, map[string]any{
			"activityId":      activity.ID.String(),
			"title":           activity.Title,
			"type":            normalizeActivityType(activity.Kind),
			"durationMinutes": 120,
			"price":           Money{Amount: float64(activity.Price), Currency: budgetCurrency(trip)},
			"markerId":        markerID,
			"reason":          "Selected from destination seed data and trip purpose.",
		})
	}
	if len(items) == 0 {
		items = append(items, map[string]any{
			"activityId":      "free-time",
			"title":           "Free exploration",
			"type":            "free_time",
			"durationMinutes": 90,
			"markerId":        markerID,
			"reason":          "Buffer time preserved in the itinerary.",
		})
	}
	return items
}

func normalizeActivityType(kind string) string {
	switch strings.ToLower(strings.TrimSpace(kind)) {
	case "event":
		return "event"
	case "restaurant":
		return "restaurant"
	default:
		return "attraction"
	}
}

func buildModeVariants(trip *TripState) map[string]ModeVariant {
	balanced := trip.BudgetSummary.GrandTotal
	return map[string]ModeVariant{
		"economy":  {TotalCost: max(0, balanced-120000), HotelStrategy: "farther_but_cheaper", TransportStrategy: "public_transport_first", EstimatedTravelTimeMinutes: 920, SavingsComparedToBalanced: ptrInt(120000), TradeoffLabel: "Cheaper, but more time in transit."},
		"balanced": {TotalCost: balanced, HotelStrategy: "balanced_location_price", TransportStrategy: "mixed", EstimatedTravelTimeMinutes: 720, TradeoffLabel: "Balanced cost and convenience."},
		"comfort":  {TotalCost: balanced + 160000, HotelStrategy: "closer_to_activities", TransportStrategy: "taxi_and_direct_routes", EstimatedTravelTimeMinutes: 540, ExtraCostComparedToBalanced: ptrInt(160000), TradeoffLabel: "Higher cost, but less friction and travel time."},
	}
}

func buildCashbackInfo(trip *TripState) CashbackInfo {
	base := 5.0
	boosted := 7.0
	return CashbackInfo{
		EstimatedTotal: Money{Amount: float64(trip.BudgetSummary.CashbackAmount), Currency: budgetCurrency(trip)},
		BasePercent:    base,
		BoostedPercent: &boosted,
		Items: []CashbackItem{
			{Category: "hotel", Amount: math.Round(float64(trip.BudgetSummary.HotelTotal) * 0.03), Currency: budgetCurrency(trip), Condition: "Pay hotel with Halyk card"},
			{Category: "flight", Amount: math.Round(float64(trip.BudgetSummary.TransportTotal) * 0.02), Currency: budgetCurrency(trip), Condition: "Pay flights with Halyk card"},
		},
	}
}

func buildChallenges(trip *TripState) []TravelChallenge {
	return []TravelChallenge{
		{
			ChallengeID: "challenge-" + trip.ID.String(),
			Title:       "Complete the full bundle in one checkout",
			Description: "Pay transport, hotel, and insurance together to unlock boosted cashback.",
			Reward:      ChallengeReward{Type: "cashback_boost", ValuePercent: ptrFloat(2)},
			Progress:    ChallengeProgress{Current: float64(trip.BudgetSummary.TransportTotal + trip.BudgetSummary.HotelTotal), Target: float64(trip.BudgetSummary.GrandTotal), Unit: "KZT"},
			Deadline:    trip.StartDate,
			Difficulty:  "easy",
			Reason:      "Bundle checkout is the most direct cashback path for this trip.",
		},
	}
}

func buildWarnings(trip *TripState, transferSegmentID string) []SmartWarning {
	out := []SmartWarning{}
	if trip.Budget > 0 && trip.BudgetSummary.GrandTotal > trip.Budget {
		out = append(out, SmartWarning{Type: "low_confidence_price", Severity: "medium", Message: "Current generated total is above the stated budget."})
	}
	if normalizeCountry(trip.DestinationCountry) != "Kazakhstan" {
		out = append(out, SmartWarning{Type: "visa_uncertain", Severity: "medium", Message: "Visa requirements should be checked again before booking."})
	}
	if selectedHotelPrice(trip) > 0 {
		out = append(out, SmartWarning{Type: "airport_far_from_hotel", Severity: "low", SegmentID: transferSegmentID, Message: "Airport to hotel transfer is material enough to review before booking."})
	}
	return out
}

func buildHotelDetailsFull(trip *TripState, hotelID string) HotelDetailsFull {
	coords := coordinatesForTrip(trip)
	room1Refundable := true
	room1Breakfast := true
	room2Refundable := false
	room2Breakfast := false
	selectedRoomID := hotelID + "-room-selected"
	downgradeRoomID := hotelID + "-room-budget"
	upgradeRoomID := hotelID + "-room-premium"
	stars := 4
	distanceAirport := 22.5
	distanceCluster := 2.1
	walkable := 8
	locationScore := 8.5
	priceScore := 8.1
	convenienceScore := 8.4
	return HotelDetailsFull{
		HotelID:      hotelID,
		Name:         hotelName(trip),
		City:         stringValue(trip.DestinationCity, "Destination"),
		District:     hotelDistrict(trip),
		Address:      hotelDistrict(trip) + ", " + stringValue(trip.DestinationCity, "Destination"),
		Lat:          coords.Lat,
		Lng:          coords.Lng,
		Stars:        &stars,
		MainImageURL: "https://images.unsplash.com/photo-1566073771259-6a8506099945",
		Rating:       HotelRating{Overall: hotelRatingValue(trip), Scale: 5, Label: "Very good", ReviewCount: 1240},
		SourceRatings: []HotelSourceRating{
			{Source: "Booking.com", Rating: hotelRatingValue(trip), Scale: 5, ReviewCount: 620, URL: "https://booking.com"},
			{Source: "Tripadvisor", Rating: hotelRatingValue(trip) - 0.1, Scale: 5, ReviewCount: 410, URL: "https://tripadvisor.com"},
		},
		ReviewSummary: HotelReviewSummary{ShortSummary: "Strong location fit, clean rooms, and good access to the route cluster.", PositivePoints: []string{"Good location", "Family-friendly rooms", "Reliable breakfast"}, NegativePoints: []string{"Peak-hour check-in can be slow"}, BestFor: []string{"Families", "Balanced city trips"}, NotIdealFor: []string{"Ultra-budget travelers"}, Confidence: "medium", BasedOnSources: []string{"Booking.com", "Tripadvisor"}},
		ReviewsBySource: []HotelReviewsSourceGroup{
			{Source: "Booking.com", TotalReviews: 620, AverageRating: hotelRatingValue(trip), Scale: 5, Reviews: []HotelReview{{ReviewID: "booking-1", AuthorName: "A.", Rating: 4.8, Scale: 5, Date: time.Now().UTC().Format("2006-01-02"), Text: "Clean rooms and very practical location.", Pros: []string{"Clean", "Location"}, Cons: []string{"Busy lobby"}}}},
			{Source: "Tripadvisor", TotalReviews: 410, AverageRating: hotelRatingValue(trip) - 0.1, Scale: 5, Reviews: []HotelReview{{ReviewID: "tripadvisor-1", AuthorName: "M.", Rating: 4.6, Scale: 5, Date: time.Now().UTC().AddDate(0, -1, 0).Format("2006-01-02"), Text: "Convenient base for city exploration.", Pros: []string{"Transit access"}, Cons: []string{"Compact room"}}}},
		},
		Rooms: []HotelRoom{
			{RoomID: selectedRoomID, Name: "Standard Room", Description: "Best balance of price and comfort for the selected plan.", ImageURL: "https://images.unsplash.com/photo-1631049307264-da0ec9d70304", Capacity: 2, BedType: "queen", AreaSqm: 24, Refundable: &room1Refundable, BreakfastIncluded: &room1Breakfast, PricePerNight: Money{Amount: float64(selectedHotelPrice(trip) / max(1, tripDurationDays(trip.StartDate, trip.EndDate))), Currency: budgetCurrency(trip)}, TotalPrice: Money{Amount: float64(selectedHotelPrice(trip)), Currency: budgetCurrency(trip)}, Labels: []string{"Selected", "Balanced"}, TradeoffLabel: "Balanced location and comfort"},
			{RoomID: downgradeRoomID, Name: "Compact Saver Room", Description: "Lower cost with smaller space and fewer extras.", Capacity: 2, BedType: "double", AreaSqm: 18, Refundable: &room2Refundable, BreakfastIncluded: &room2Breakfast, PricePerNight: Money{Amount: math.Max(1, float64(selectedHotelPrice(trip)-35000)/float64(max(1, tripDurationDays(trip.StartDate, trip.EndDate)))), Currency: budgetCurrency(trip)}, TotalPrice: Money{Amount: math.Max(1, float64(selectedHotelPrice(trip)-35000)), Currency: budgetCurrency(trip)}, Labels: []string{"Budget"}, TradeoffLabel: "Cheaper, but less spacious"},
		},
		SelectedRoomID: selectedRoomID,
		RoomOptions:    HotelRoomOptions{SelectedRoomID: selectedRoomID, DowngradeRoomID: downgradeRoomID, UpgradeRoomID: upgradeRoomID, SelectedReason: "Chosen for the best route convenience to price ratio.", DowngradeLabel: "Save money with a smaller room", UpgradeLabel: "Upgrade for more comfort and extras"},
		LocationInfo:   HotelLocationInfo{DistanceToAirportKm: &distanceAirport, TaxiFromAirport: &Money{Amount: 8500, Currency: budgetCurrency(trip)}, DistanceToMainClusterKm: &distanceCluster, AverageTaxiToActivities: &Money{Amount: 2500, Currency: budgetCurrency(trip)}, WalkablePlacesCount: &walkable, LocationScore: &locationScore, PriceScore: &priceScore, ConvenienceScore: &convenienceScore},
		Reason:         "Selected as the best mobile-facing bundle fit for route convenience, review quality, and price balance.",
	}
}

func buildSubtitle(trip *TripState) string {
	parts := []string{stringValue(trip.OriginCity, "Origin"), stringValue(trip.DestinationCity, "Destination")}
	if trip.SelectedHotel != nil {
		parts = append(parts, trip.SelectedHotel.Location)
	}
	return strings.Join(uniqueStrings(parts), " -> ")
}

func tripDurationDays(startDate, endDate string) int {
	if strings.TrimSpace(startDate) == "" || strings.TrimSpace(endDate) == "" {
		return 1
	}
	start, err1 := time.Parse("2006-01-02", startDate)
	end, err2 := time.Parse("2006-01-02", endDate)
	if err1 != nil || err2 != nil || end.Before(start) {
		return 1
	}
	return int(end.Sub(start).Hours()/24) + 1
}

func coordinatesForTrip(trip *TripState) Coordinates {
	switch normalizeCountry(trip.DestinationCountry) {
	case "Japan":
		return Coordinates{Lat: 35.6762, Lng: 139.6503}
	case "Germany":
		return Coordinates{Lat: 52.52, Lng: 13.405}
	default:
		return Coordinates{Lat: 43.2389, Lng: 76.8897}
	}
}

func countryCodeForCountry(country string) string {
	switch normalizeCountry(country) {
	case "Japan":
		return "JP"
	case "Germany":
		return "DE"
	case "Kazakhstan":
		return "KZ"
	default:
		return "KZ"
	}
}

func estimateTripTotal(country string) int {
	switch normalizeCountry(country) {
	case "Japan":
		return 920000
	case "Germany":
		return 760000
	default:
		return 340000
	}
}

func firstN(value string, n int) string {
	value = strings.TrimSpace(value)
	if len(value) <= n {
		return strings.ToUpper(value)
	}
	return strings.ToUpper(value[:n])
}

func firstString(items []string) string {
	if len(items) == 0 {
		return ""
	}
	return items[0]
}

func hotelName(trip *TripState) string {
	if trip.SelectedHotel != nil && strings.TrimSpace(trip.SelectedHotel.Name) != "" {
		return trip.SelectedHotel.Name
	}
	return stringValue(trip.DestinationCity, "Destination") + " Family Central Hotel"
}

func hotelID(trip *TripState) string {
	if trip.SelectedHotel != nil {
		return trip.SelectedHotel.ID.String()
	}
	return "hotel-" + trip.ID.String()
}

func hotelDistrict(trip *TripState) string {
	if trip.SelectedHotel != nil && strings.TrimSpace(trip.SelectedHotel.Location) != "" {
		return trip.SelectedHotel.Location
	}
	return stringValue(trip.DestinationCity, "Destination") + " center"
}

func hotelRatingValue(trip *TripState) float64 {
	if trip.SelectedHotel != nil && trip.SelectedHotel.Rating > 0 {
		return trip.SelectedHotel.Rating
	}
	return 4.6
}

func hotelMarkerPrice(trip *TripState) *MoneyWithUnit {
	if trip.SelectedHotel == nil {
		return nil
	}
	return &MoneyWithUnit{Amount: float64(trip.SelectedHotel.Price), Currency: trip.SelectedHotel.Currency, Unit: "night"}
}

func selectedTransportProvider(trip *TripState) string {
	if trip.SelectedTransport != nil && strings.TrimSpace(trip.SelectedTransport.Provider) != "" {
		return trip.SelectedTransport.Provider
	}
	return "Air Astana"
}

func firstActivityTitle(trip *TripState) string {
	if len(trip.Activities) > 0 && strings.TrimSpace(trip.Activities[0].Title) != "" {
		return trip.Activities[0].Title
	}
	return "Main city highlights"
}

func budgetCurrency(trip *TripState) string {
	if strings.TrimSpace(trip.BudgetSummary.Currency) != "" {
		return trip.BudgetSummary.Currency
	}
	return "KZT"
}

func ptr[T any](value T) *T {
	return &value
}

func ptrInt(value int) *int {
	return &value
}

func ptrFloat(value float64) *float64 {
	return &value
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}
