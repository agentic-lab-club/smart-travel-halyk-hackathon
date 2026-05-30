package seeder

import (
	"fmt"
	"strings"
)

func BuildDestinationSeed(country, origin, transportType string) DestinationSeed {
	key := strings.ToLower(country)
	switch key {
	case "kazakhstan":
		return DestinationSeed{
			City:    "Almaty",
			Country: "Kazakhstan",
			Transport: []TransportSeed{
				newTransport(transportType, "Air Astana", fmt.Sprintf("%s -> Almaty", origin), origin, "Almaty", "08:00", "10:00", 58000, "Fast domestic option"),
				newTransport("rail", "Kazakhstan Railways", fmt.Sprintf("%s -> Almaty", origin), origin, "Almaty", "21:00", "09:00", 32000, "Budget overnight ride"),
			},
			Hotels: []HotelSeed{
				newHotel("Booking Mock", "Family View Almaty", "Almaty city center", 95000, 4.7, "Family-friendly stay near attractions", "https://maps.google.com/?q=Almaty+hotel"),
				newHotel("Booking Mock", "Budget Smart Stay", "Almaty old town", 61000, 4.3, "Budget option close to transport", "https://2gis.kz/almaty/search/hotel"),
			},
			Activities: []ActivitySeed{
				newActivity("place", "Kok Tobe", "Almaty", "Day 1", 12000, "Google Maps", "https://maps.google.com/?q=Kok+Tobe", "Scenic family-friendly hilltop stop"),
				newActivity("event", "Kino.kz Family Movie", "Almaty", "Day 2", 9000, "Kino.kz", "https://kino.kz", "Optional family event after dinner"),
			},
			Visa: VisaSeed{
				Country:         "Kazakhstan",
				Requirement:     "No visa required for domestic travelers in this prototype",
				RecommendedLead: "No lead time required",
				Checklist:       []string{"Valid local ID", "Travel tickets", "Hotel confirmation"},
				Notes:           "Domestic route mock scenario",
			},
			Reviews: []ReviewSeed{
				newReview("hotel", "Family View Almaty", "Families praise the location, breakfast, and easy access to sights.", "Google Maps", "https://maps.google.com/?q=Almaty+hotel"),
				newReview("event", "Kino.kz Family Movie", "Easy add-on entertainment for families with children.", "Kino.kz", "https://kino.kz"),
			},
			FoodEstimate:      28000,
			LocalTransport:    18000,
			InsuranceEstimate: 6000,
		}
	case "uae":
		return DestinationSeed{
			City:    "Dubai",
			Country: "UAE",
			Transport: []TransportSeed{
				newTransport("flight", "FlyDubai Mock", fmt.Sprintf("%s -> Dubai", origin), origin, "Dubai", "09:30", "12:50", 288000, "Direct family option"),
				newTransport("flight", "Air Astana", fmt.Sprintf("%s -> Dubai", origin), origin, "Dubai", "20:00", "23:35", 318000, "Evening arrival option"),
			},
			Hotels: []HotelSeed{
				newHotel("Booking Mock", "Desert Family Resort", "Dubai Marina", 310000, 4.9, "Premium family resort with airport transfer", "https://maps.google.com/?q=Dubai+resort"),
				newHotel("Booking Mock", "Metro Smart Hotel", "Downtown Dubai", 210000, 4.4, "Balanced option near metro and malls", "https://tripadvisor.com"),
			},
			Activities: []ActivitySeed{
				newActivity("place", "Burj Khalifa District", "Dubai", "Day 1", 25000, "Google Maps", "https://maps.google.com/?q=Burj+Khalifa", "High-visibility city icon for demo"),
				newActivity("event", "Kino.kz Concert Pick", "Dubai", "Day 2", 28000, "Kino.kz", "https://kino.kz", "Mock event card to show event mode"),
			},
			Visa: VisaSeed{
				Country:         "UAE",
				Requirement:     "Entry rules vary by passport; MVP displays a mock checklist",
				RecommendedLead: "Check visa details 21 days before departure",
				Checklist:       []string{"Passport", "Hotel confirmation", "Return ticket", "Insurance"},
				Notes:           "Mock assistant for demo only",
			},
			Reviews: []ReviewSeed{
				newReview("hotel", "Desert Family Resort", "Travelers love the pool, kids areas, and premium service.", "Tripadvisor", "https://tripadvisor.com"),
				newReview("event", "Kino.kz Concert Pick", "Strong add-on for evening plans in a city trip.", "Kino.kz", "https://kino.kz"),
			},
			FoodEstimate:      78000,
			LocalTransport:    32000,
			InsuranceEstimate: 18000,
		}
	case "japan":
		return DestinationSeed{
			City:    "Tokyo",
			Country: "Japan",
			Transport: []TransportSeed{
				newTransport("flight", "JAL Mock", fmt.Sprintf("%s -> Tokyo", origin), origin, "Tokyo", "07:10", "16:20", 395000, "High-comfort long-haul option"),
				newTransport("flight", "ANA Mock", fmt.Sprintf("%s -> Tokyo", origin), origin, "Tokyo", "23:20", "08:40", 348000, "Lower price overnight route"),
			},
			Hotels: []HotelSeed{
				newHotel("Booking Mock", "Tokyo Family Smart Hotel", "Shinjuku", 355000, 4.8, "Central stay for family and solo travelers", "https://maps.google.com/?q=Shinjuku+hotel"),
				newHotel("Booking Mock", "Compact Tokyo Stay", "Ueno", 240000, 4.3, "Smaller rooms but better budget fit", "https://tripadvisor.com"),
			},
			Activities: []ActivitySeed{
				newActivity("place", "Asakusa and Senso-ji", "Tokyo", "Day 1", 16000, "Google Maps", "https://maps.google.com/?q=Sensoji", "Cultural first-day itinerary stop"),
				newActivity("event", "Kino.kz Anime Event Pick", "Tokyo", "Day 3", 21000, "Kino.kz", "https://kino.kz", "Event-focused option for solo travelers"),
			},
			Visa: VisaSeed{
				Country:         "Japan",
				Requirement:     "Prototype shows a visa-assistant style checklist",
				RecommendedLead: "Begin visa preparation 30 days before departure",
				Checklist:       []string{"Passport", "Application form", "Hotel proof", "Trip itinerary", "Insurance"},
				Notes:           "Mock data for the hackathon prototype",
			},
			Reviews: []ReviewSeed{
				newReview("hotel", "Tokyo Family Smart Hotel", "Review summary highlights cleanliness, transit access, and family room comfort.", "Tripadvisor", "https://tripadvisor.com"),
				newReview("place", "Asakusa and Senso-ji", "Visitors mention strong atmosphere and easy family-friendly exploration.", "Google Maps", "https://maps.google.com/?q=Sensoji"),
			},
			FoodEstimate:      84000,
			LocalTransport:    36000,
			InsuranceEstimate: 22000,
		}
	default:
		return DestinationSeed{
			City:    "Istanbul",
			Country: "Turkey",
			Transport: []TransportSeed{
				newTransport("flight", "Turkish Airlines", fmt.Sprintf("%s -> Istanbul", origin), origin, "Istanbul", "06:20", "10:40", 245000, "Direct international flight"),
				newTransport("flight", "Pegasus Mock", fmt.Sprintf("%s -> Istanbul", origin), origin, "Istanbul", "13:10", "17:25", 198000, "Lower fare with tighter schedule"),
			},
			Hotels: []HotelSeed{
				newHotel("Booking Mock", "Bosporus Family Hotel", "Sultanahmet", 225000, 4.8, "Family hotel near key landmarks", "https://maps.google.com/?q=Istanbul+hotel"),
				newHotel("Booking Mock", "Historic Budget Inn", "Beyoglu", 162000, 4.2, "Budget stay with metro access", "https://tripadvisor.com"),
			},
			Activities: []ActivitySeed{
				newActivity("place", "Hagia Sophia", "Istanbul", "Day 1", 18000, "Google Maps", "https://maps.google.com/?q=Hagia+Sophia", "Iconic landmark for first-day sightseeing"),
				newActivity("event", "Kino.kz Partner Event Pick", "Istanbul", "Day 3", 22000, "Kino.kz", "https://kino.kz", "Mock event add-on for a solo/event traveler"),
			},
			Visa: VisaSeed{
				Country:         "Turkey",
				Requirement:     "Visa rules depend on passport in real life; MVP shows a simplified assistant",
				RecommendedLead: "Check requirements 14 days before departure",
				Checklist:       []string{"Passport validity", "Flight booking", "Hotel booking", "Travel insurance"},
				Notes:           "Prototype uses simplified visa assistant copy",
			},
			Reviews: []ReviewSeed{
				newReview("hotel", "Bosporus Family Hotel", "Guests highlight breakfast, family rooms, and proximity to major sights.", "Tripadvisor", "https://tripadvisor.com"),
				newReview("place", "Hagia Sophia", "Crowds can be heavy, but most visitors still rate it as essential.", "Google Maps", "https://maps.google.com/?q=Hagia+Sophia"),
			},
			FoodEstimate:      62000,
			LocalTransport:    26000,
			InsuranceEstimate: 15000,
		}
	}
}

func newTransport(mode, provider, title, origin, destination, departure, arrival string, price int, description string) TransportSeed {
	if mode == "" {
		mode = "flight"
	}
	return TransportSeed{Mode: mode, Provider: provider, Title: title, Origin: origin, Destination: destination, Departure: departure, Arrival: arrival, Price: price, Currency: "KZT", Description: description}
}

func newHotel(provider, name, location string, price int, rating float64, description, link string) HotelSeed {
	return HotelSeed{Provider: provider, Name: name, Location: location, Price: price, Currency: "KZT", Rating: rating, Description: description, ReviewLink: link}
}

func newActivity(kind, title, location, dayLabel string, price int, sourceName, sourceLink, description string) ActivitySeed {
	return ActivitySeed{Kind: kind, Title: title, Location: location, DayLabel: dayLabel, Price: price, Currency: "KZT", SourceName: sourceName, SourceLink: sourceLink, Description: description}
}

func newReview(kind, target, summary, sourceName, sourceLink string) ReviewSeed {
	return ReviewSeed{Kind: kind, TargetName: target, Summary: summary, SourceName: sourceName, SourceLink: sourceLink}
}
