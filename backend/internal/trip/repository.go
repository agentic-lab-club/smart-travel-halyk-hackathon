package trip

import (
	"fmt"
	"strings"
	"sync"
	"time"

	"github.com/agentic-lab-club/smart-travel-halyk-hackathon/backend/pkg/database"
	"github.com/google/uuid"
)

type Repository struct {
	db       *database.TrackedDB
	mu       sync.RWMutex
	trips    map[uuid.UUID]*Trip
	sessions map[uuid.UUID]*ChatSession
}

func NewRepository(db *database.TrackedDB) *Repository {
	return &Repository{
		db:       db,
		trips:    make(map[uuid.UUID]*Trip),
		sessions: make(map[uuid.UUID]*ChatSession),
	}
}

func (r *Repository) CreateTrip(title string) (*Trip, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	now := time.Now().UTC()
	tripID := uuid.New()
	sessionID := uuid.New()
	trip := &Trip{
		ID:            tripID,
		Status:        StatusDraft,
		Title:         title,
		ChatSessionID: sessionID,
		BudgetSummary: BudgetSummary{Currency: "KZT"},
		CreatedAt:     now,
		UpdatedAt:     now,
	}
	session := &ChatSession{
		ID:        sessionID,
		TripID:    tripID,
		Messages:  []ChatMessage{},
		CreatedAt: now,
		UpdatedAt: now,
	}
	r.trips[tripID] = trip
	r.sessions[sessionID] = session
	return cloneTrip(trip), nil
}

func (r *Repository) GetTrip(id uuid.UUID) (*Trip, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	trip, ok := r.trips[id]
	if !ok {
		return nil, nil
	}
	return cloneTrip(trip), nil
}

func (r *Repository) SaveTrip(trip *Trip) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if trip == nil {
		return fmt.Errorf("failed to save trip: trip is nil")
	}
	cp := cloneTrip(trip)
	cp.UpdatedAt = time.Now().UTC()
	r.trips[cp.ID] = cp
	return nil
}

func (r *Repository) GetSessionByTripID(tripID uuid.UUID) (*ChatSession, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	trip, ok := r.trips[tripID]
	if !ok {
		return nil, nil
	}
	session, ok := r.sessions[trip.ChatSessionID]
	if !ok {
		return nil, nil
	}
	return cloneSession(session), nil
}

func (r *Repository) SaveSession(session *ChatSession) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if session == nil {
		return fmt.Errorf("failed to save session: session is nil")
	}
	cp := cloneSession(session)
	cp.UpdatedAt = time.Now().UTC()
	r.sessions[cp.ID] = cp
	return nil
}

func cloneTrip(src *Trip) *Trip {
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
