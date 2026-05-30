package trip

import (
	"fmt"
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
	cp.Travelers = append([]Traveler{}, src.Travelers...)
	cp.TodoSections = append([]TodoSection{}, src.TodoSections...)
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
	cp.Messages = append([]ChatMessage{}, src.Messages...)
	return &cp
}
