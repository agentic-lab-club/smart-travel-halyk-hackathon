package trip

import (
	"fmt"
	"strings"

	"github.com/google/uuid"
)

func fallbackDestinationReference(country, city string) *destinationReference {
	normalizedCountry := normalizeCountry(country)
	if normalizedCountry == "" {
		normalizedCountry = "Germany"
	}
	resolvedCity := strings.TrimSpace(city)
	if resolvedCity == "" {
		resolvedCity = defaultCityForCountry(normalizedCountry)
	}
	return &destinationReference{
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
	secondaryMode := "rail"
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
			Kind:        "place",
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
