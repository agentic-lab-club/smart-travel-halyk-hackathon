package trip

import (
	"fmt"
	"strings"
)

type destinationSeed struct {
	City              string
	Country           string
	Transport         []transportSeed
	Hotels            []hotelSeed
	Activities        []activitySeed
	Visa              visaSeed
	Reviews           []reviewSeed
	FoodEstimate      int
	LocalTransport    int
	InsuranceEstimate int
}

type transportSeed struct {
	Mode        string
	Provider    string
	Title       string
	Origin      string
	Destination string
	Departure   string
	Arrival     string
	Price       int
	Currency    string
	Description string
}

type hotelSeed struct {
	Provider    string
	Name        string
	Location    string
	Price       int
	Currency    string
	Rating      float64
	Description string
	ReviewLink  string
}

type activitySeed struct {
	Kind        string
	Title       string
	Location    string
	DayLabel    string
	Price       int
	Currency    string
	SourceName  string
	SourceLink  string
	Description string
}

type visaSeed struct {
	Country         string
	Requirement     string
	RecommendedLead string
	Checklist       []string
	Notes           string
}

type reviewSeed struct {
	Kind       string
	TargetName string
	Summary    string
	SourceName string
	SourceLink string
}

func buildDestinationSeed(country, origin, transportType string) destinationSeed {
	key := strings.ToLower(strings.TrimSpace(normalizeCountry(country)))
	switch key {
	case "kazakhstan":
		return destinationSeed{
			City:    "Almaty",
			Country: "Kazakhstan",
			Transport: []transportSeed{
				newTransportSeed(transportType, "Air Astana", fmt.Sprintf("%s -> Almaty", origin), origin, "Almaty", "08:00", "10:00", 58000, "Fast domestic option"),
				newTransportSeed("rail", "Kazakhstan Railways", fmt.Sprintf("%s -> Almaty", origin), origin, "Almaty", "21:00", "09:00", 32000, "Budget overnight ride"),
			},
			Hotels: []hotelSeed{
				newHotelSeed("Booking Mock", "Family View Almaty", "Almaty city center", 95000, 4.7, "Family-friendly stay near attractions", "https://maps.google.com/?q=Almaty+hotel"),
				newHotelSeed("Booking Mock", "Budget Smart Stay", "Almaty old town", 61000, 4.3, "Budget option close to transport", "https://2gis.kz/almaty/search/hotel"),
			},
			Activities: []activitySeed{
				newActivitySeed("place", "Kok Tobe", "Almaty", "Day 1", 12000, "Google Maps", "https://maps.google.com/?q=Kok+Tobe", "Scenic family-friendly hilltop stop"),
				newActivitySeed("event", "Kino.kz Family Movie", "Almaty", "Day 2", 9000, "Kino.kz", "https://kino.kz", "Optional family event after dinner"),
			},
			Visa: visaSeed{
				Country:         "Kazakhstan",
				Requirement:     "No visa required for domestic travelers in this prototype",
				RecommendedLead: "No lead time required",
				Checklist:       []string{"Valid local ID", "Travel tickets", "Hotel confirmation"},
				Notes:           "Domestic route mock scenario",
			},
			Reviews: []reviewSeed{
				newReviewSeed("hotel", "Family View Almaty", "Families praise the location, breakfast, and easy access to sights.", "Google Maps", "https://maps.google.com/?q=Almaty+hotel"),
				newReviewSeed("event", "Kino.kz Family Movie", "Easy add-on entertainment for families with children.", "Kino.kz", "https://kino.kz"),
			},
			FoodEstimate:      28000,
			LocalTransport:    18000,
			InsuranceEstimate: 6000,
		}
	case "turkey":
		return destinationSeed{
			City:    "Istanbul",
			Country: "Turkey",
			Transport: []transportSeed{
				newTransportSeed("flight", "Turkish Airlines Mock", fmt.Sprintf("%s -> Istanbul", origin), origin, "Istanbul", "09:30", "14:10", 265000, "Balanced international family option"),
				newTransportSeed("flight", "Pegasus Mock", fmt.Sprintf("%s -> Istanbul", origin), origin, "Istanbul", "22:50", "03:15", 214000, "Lower-fare late route"),
			},
			Hotels: []hotelSeed{
				newHotelSeed("Booking Mock", "Istanbul Bosphorus Family Stay", "Besiktas", 210000, 4.7, "Comfort stay with family-friendly access to major sights", "https://maps.google.com/?q=Istanbul+hotel"),
				newHotelSeed("Booking Mock", "Historic Istanbul Smart Rooms", "Sultanahmet", 168000, 4.4, "Good fit for itinerary-first travelers near landmarks", "https://tripadvisor.com"),
			},
			Activities: []activitySeed{
				newActivitySeed("place", "Hagia Sophia and Blue Mosque", "Istanbul", "Day 1", 18000, "Google Maps", "https://maps.google.com/?q=Hagia+Sophia", "High-value first day route for family and solo travelers"),
				newActivitySeed("event", "Kino.kz Culture Pick", "Istanbul", "Day 3", 15000, "Kino.kz", "https://kino.kz", "Optional event-focused evening plan"),
			},
			Visa: visaSeed{
				Country:         "Turkey",
				Requirement:     "Prototype visa rules depend on citizenship and are shown as guidance only",
				RecommendedLead: "Check entry rules 14 days before departure",
				Checklist:       []string{"Passport validity", "Hotel confirmation", "Return ticket", "Insurance"},
				Notes:           "Mock visa assistant data for the MVP",
			},
			Reviews: []reviewSeed{
				newReviewSeed("hotel", "Istanbul Bosphorus Family Stay", "Guests like the location, breakfast, and family comfort.", "Tripadvisor", "https://tripadvisor.com"),
				newReviewSeed("place", "Hagia Sophia and Blue Mosque", "Review summaries highlight strong atmosphere and easy route planning nearby.", "Google Maps", "https://maps.google.com/?q=Hagia+Sophia"),
			},
			FoodEstimate:      52000,
			LocalTransport:    23000,
			InsuranceEstimate: 14000,
		}
	case "uae":
		return destinationSeed{
			City:    "Dubai",
			Country: "UAE",
			Transport: []transportSeed{
				newTransportSeed("flight", "FlyDubai Mock", fmt.Sprintf("%s -> Dubai", origin), origin, "Dubai", "10:20", "13:35", 285000, "Direct route for event and family travel"),
				newTransportSeed("flight", "Air Astana", fmt.Sprintf("%s -> Dubai", origin), origin, "Dubai", "01:10", "04:30", 242000, "Lower price overnight option"),
			},
			Hotels: []hotelSeed{
				newHotelSeed("Booking Mock", "Dubai Marina Family Suites", "Dubai Marina", 320000, 4.8, "High-comfort stay near family attractions and beaches", "https://maps.google.com/?q=Dubai+Marina+hotel"),
				newHotelSeed("Booking Mock", "Smart Downtown Dubai Stay", "Downtown Dubai", 245000, 4.5, "Good balance for sightseeing and event access", "https://tripadvisor.com"),
			},
			Activities: []activitySeed{
				newActivitySeed("place", "Burj Khalifa and Dubai Mall", "Dubai", "Day 1", 26000, "Google Maps", "https://maps.google.com/?q=Burj+Khalifa", "Core city itinerary block with easy indoor fallback"),
				newActivitySeed("event", "Kino.kz Premium Event Pick", "Dubai", "Day 3", 28000, "Kino.kz", "https://kino.kz", "Event-driven option for solo or mixed group plans"),
			},
			Visa: visaSeed{
				Country:         "UAE",
				Requirement:     "Prototype visa assistant shows simplified entry guidance",
				RecommendedLead: "Check entry requirements 21 days before departure",
				Checklist:       []string{"Passport", "Accommodation proof", "Return booking", "Insurance"},
				Notes:           "Mock entry guidance only",
			},
			Reviews: []reviewSeed{
				newReviewSeed("hotel", "Dubai Marina Family Suites", "Review summary highlights cleanliness, service, and family amenities.", "Tripadvisor", "https://tripadvisor.com"),
				newReviewSeed("place", "Burj Khalifa and Dubai Mall", "Visitors mention convenience, indoor comfort, and strong first-day appeal.", "Google Maps", "https://maps.google.com/?q=Burj+Khalifa"),
			},
			FoodEstimate:      76000,
			LocalTransport:    31000,
			InsuranceEstimate: 18000,
		}
	case "japan":
		return destinationSeed{
			City:    "Tokyo",
			Country: "Japan",
			Transport: []transportSeed{
				newTransportSeed("flight", "JAL Mock", fmt.Sprintf("%s -> Tokyo", origin), origin, "Tokyo", "07:10", "16:20", 395000, "High-comfort long-haul option"),
				newTransportSeed("flight", "ANA Mock", fmt.Sprintf("%s -> Tokyo", origin), origin, "Tokyo", "23:20", "08:40", 348000, "Lower price overnight route"),
			},
			Hotels: []hotelSeed{
				newHotelSeed("Booking Mock", "Tokyo Family Smart Hotel", "Shinjuku", 355000, 4.8, "Central stay for family and solo travelers", "https://maps.google.com/?q=Shinjuku+hotel"),
				newHotelSeed("Booking Mock", "Compact Tokyo Stay", "Ueno", 240000, 4.3, "Smaller rooms but better budget fit", "https://tripadvisor.com"),
			},
			Activities: []activitySeed{
				newActivitySeed("place", "Asakusa and Senso-ji", "Tokyo", "Day 1", 16000, "Google Maps", "https://maps.google.com/?q=Sensoji", "Cultural first-day itinerary stop"),
				newActivitySeed("event", "Kino.kz Anime Event Pick", "Tokyo", "Day 3", 21000, "Kino.kz", "https://kino.kz", "Event-focused option for solo travelers"),
			},
			Visa: visaSeed{
				Country:         "Japan",
				Requirement:     "Prototype shows a visa-assistant style checklist",
				RecommendedLead: "Begin visa preparation 30 days before departure",
				Checklist:       []string{"Passport", "Application form", "Hotel proof", "Trip itinerary", "Insurance"},
				Notes:           "Mock data for the hackathon prototype",
			},
			Reviews: []reviewSeed{
				newReviewSeed("hotel", "Tokyo Family Smart Hotel", "Review summary highlights cleanliness, transit access, and family room comfort.", "Tripadvisor", "https://tripadvisor.com"),
				newReviewSeed("place", "Asakusa and Senso-ji", "Visitors mention strong atmosphere and easy family-friendly exploration.", "Google Maps", "https://maps.google.com/?q=Sensoji"),
			},
			FoodEstimate:      84000,
			LocalTransport:    36000,
			InsuranceEstimate: 22000,
		}
	default:
		return destinationSeed{
			City:    "Berlin",
			Country: "Germany",
			Transport: []transportSeed{
				newTransportSeed("flight", "Lufthansa Mock", fmt.Sprintf("%s -> Berlin", origin), origin, "Berlin", "06:20", "11:40", 245000, "Direct international flight"),
				newTransportSeed("flight", "Air Astana", fmt.Sprintf("%s -> Berlin", origin), origin, "Berlin", "13:10", "19:25", 198000, "Lower fare with tighter schedule"),
			},
			Hotels: []hotelSeed{
				newHotelSeed("Booking Mock", "Berlin Family Central Hotel", "Mitte", 225000, 4.8, "Family hotel near key landmarks", "https://maps.google.com/?q=Berlin+hotel"),
				newHotelSeed("Booking Mock", "Historic Budget Inn Berlin", "Prenzlauer Berg", 162000, 4.2, "Budget stay with metro access", "https://tripadvisor.com"),
			},
			Activities: []activitySeed{
				newActivitySeed("place", "Brandenburg Gate", "Berlin", "Day 1", 18000, "Google Maps", "https://maps.google.com/?q=Brandenburg+Gate", "Iconic landmark for first-day sightseeing"),
				newActivitySeed("event", "Kino.kz Partner Event Pick", "Berlin", "Day 3", 22000, "Kino.kz", "https://kino.kz", "Mock event add-on for a solo/event traveler"),
			},
			Visa: visaSeed{
				Country:         "Germany",
				Requirement:     "Visa rules depend on passport in real life; MVP shows a simplified assistant",
				RecommendedLead: "Check requirements 14 days before departure",
				Checklist:       []string{"Passport validity", "Flight booking", "Hotel booking", "Travel insurance"},
				Notes:           "Prototype uses simplified visa assistant copy",
			},
			Reviews: []reviewSeed{
				newReviewSeed("hotel", "Berlin Family Central Hotel", "Guests highlight breakfast, family rooms, and proximity to major sights.", "Tripadvisor", "https://tripadvisor.com"),
				newReviewSeed("place", "Brandenburg Gate", "Visitors rate it as a must-see stop in central Berlin.", "Google Maps", "https://maps.google.com/?q=Brandenburg+Gate"),
			},
			FoodEstimate:      62000,
			LocalTransport:    26000,
			InsuranceEstimate: 15000,
		}
	}
}

func newTransportSeed(mode, provider, title, origin, destination, departure, arrival string, price int, description string) transportSeed {
	if mode == "" {
		mode = "flight"
	}
	return transportSeed{Mode: mode, Provider: provider, Title: title, Origin: origin, Destination: destination, Departure: departure, Arrival: arrival, Price: price, Currency: "KZT", Description: description}
}

func newHotelSeed(provider, name, location string, price int, rating float64, description, link string) hotelSeed {
	return hotelSeed{Provider: provider, Name: name, Location: location, Price: price, Currency: "KZT", Rating: rating, Description: description, ReviewLink: link}
}

func newActivitySeed(kind, title, location, dayLabel string, price int, sourceName, sourceLink, description string) activitySeed {
	return activitySeed{Kind: kind, Title: title, Location: location, DayLabel: dayLabel, Price: price, Currency: "KZT", SourceName: sourceName, SourceLink: sourceLink, Description: description}
}

func newReviewSeed(kind, target, summary, sourceName, sourceLink string) reviewSeed {
	return reviewSeed{Kind: kind, TargetName: target, Summary: summary, SourceName: sourceName, SourceLink: sourceLink}
}
