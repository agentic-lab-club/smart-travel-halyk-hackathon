package trip

import (
	"time"

	"github.com/gofiber/fiber/v3"
	respond "github.com/agentic-lab-club/smart-travel-halyk-hackathon/backend/pkg/http/responder"
)

// GetUserProfile returns a static demo user profile matching the mobile UserProfileResponse contract.
//
// @Summary Get user profile
// @Description Returns the current user profile for the demo session.
// @Tags @consumer
// @Produce json
// @Success 200 {object} UserProfileResponse
// @Router /api/v1/user-profile [get]
func GetUserProfile(c fiber.Ctx) error {
	profile := UserProfileResponse{
		UserID:            "user-001",
		Name:              "Aigerim",
		Citizenship:       "KZ",
		HomeCity:          "Almaty",
		HomeAirport:       "ALA",
		Currency:          "KZT",
		PreferredLanguage: "ru",
		TravelProfile: MobileTravelProfile{
			BudgetLevel:             "balanced",
			TravelFrequency:         "medium",
			PreferredTripLengthDays: 5,
			PreferredCategories:     []string{"food", "history", "sea", "walkable"},
			AvoidCategories:         []string{"nightlife", "extreme_sports"},
			HotelPreference:         "balanced_location_price",
			TransportPreference:     "mixed",
		},
	}
	return respond.OK(c, profile, nil)
}

// GetRecommendations returns seed-based trip recommendations matching the mobile RecommendationsResponse contract.
//
// @Summary Get trip recommendations
// @Description Returns AI-curated trip recommendations for the current user.
// @Tags @consumer
// @Produce json
// @Success 200 {object} RecommendationsResponse
// @Router /api/v1/recommendations [get]
func GetRecommendations(c fiber.Ctx) error {
	now := time.Now().UTC().Format(time.RFC3339)
	istanbul := "https://images.unsplash.com/photo-1524231757912-21f4fe3a7200"
	tbilisi := "https://images.unsplash.com/photo-1565008576549-57569a49371d"
	almaty := "https://images.unsplash.com/photo-1596367407372-5af9a8b8d67e"
	dubai := "https://images.unsplash.com/photo-1512453979798-5ea266f8880c"

	startIST := "2026-06-12"
	endIST := "2026-06-16"
	startTBS := "2026-06-20"
	endTBS := "2026-06-24"
	startALA := "2026-06-27"
	endALA := "2026-06-29"
	startDXB := "2026-07-04"
	endDXB := "2026-07-09"

	cashbackIST := MobileCashbackEstimate{Amount: 31_500, Currency: "KZT", Percent: 4.2}
	cashbackTBS := MobileCashbackEstimate{Amount: 18_000, Currency: "KZT", Percent: 3.0}
	cashbackALA := MobileCashbackEstimate{Amount: 5_500, Currency: "KZT", Percent: 3.0}
	cashbackDXB := MobileCashbackEstimate{Amount: 32_000, Currency: "KZT", Percent: 3.5}

	resp := RecommendationsResponse{
		UserID:       "user-001",
		GeneratedAt:  now,
		SelectedMode: "balanced",
		Recommendations: []MobileTripRecommendation{
			{
				TripID:           "trip-istanbul-001",
				DestinationName:  "Istanbul, Turkey",
				DestinationTitle: "Istanbul food and Bosphorus weekend",
				CountryCode:      "TR",
				CityCodes:        []string{"IST"},
				StartDate:        &startIST,
				EndDate:          &endIST,
				DurationDays:     5,
				ImageURL:         &istanbul,
				EstimatedTotalCost: MobileEstimatedMoney{Amount: 742_000, Currency: "KZT", Confidence: "high"},
				CashbackEstimate:   &cashbackIST,
				MainReason:       "Visa-free, direct flight from Almaty, strong food and history match.",
				ReasonLabels:     []string{"Visa-free", "Direct flight", "Food match", "Cashback boost"},
				RecommendationType: "cashback_boosted",
				Score:            0.94,
			},
			{
				TripID:           "trip-tbilisi-001",
				DestinationName:  "Tbilisi, Georgia",
				DestinationTitle: "Tbilisi old town and wine route",
				CountryCode:      "GE",
				CityCodes:        []string{"TBS"},
				StartDate:        &startTBS,
				EndDate:          &endTBS,
				DurationDays:     5,
				ImageURL:         &tbilisi,
				EstimatedTotalCost: MobileEstimatedMoney{Amount: 586_000, Currency: "KZT", Confidence: "medium"},
				CashbackEstimate:   &cashbackTBS,
				MainReason:       "Short flight, familiar cuisine, easy intercity day trips.",
				ReasonLabels:     []string{"Budget friendly", "Weekend trip", "Food", "Mountains"},
				RecommendationType: "budget_friendly",
				Score:            0.87,
			},
			{
				TripID:           "trip-almaty-001",
				DestinationName:  "Almaty, Kazakhstan",
				DestinationTitle: "Almaty mountain reset weekend",
				CountryCode:      "KZ",
				CityCodes:        []string{"ALA"},
				StartDate:        &startALA,
				EndDate:          &endALA,
				DurationDays:     3,
				ImageURL:         &almaty,
				EstimatedTotalCost: MobileEstimatedMoney{Amount: 180_000, Currency: "KZT", Confidence: "high"},
				CashbackEstimate:   &cashbackALA,
				MainReason:       "No visa, no flight stress, great mountain scenery.",
				ReasonLabels:     []string{"No visa", "Mountains", "Weekend getaway"},
				RecommendationType: "similar_to_previous",
				Score:            0.82,
			},
			{
				TripID:           "trip-dubai-001",
				DestinationName:  "Dubai, UAE",
				DestinationTitle: "Dubai luxury and desert experience",
				CountryCode:      "AE",
				CityCodes:        []string{"DXB"},
				StartDate:        &startDXB,
				EndDate:          &endDXB,
				DurationDays:     6,
				ImageURL:         &dubai,
				EstimatedTotalCost: MobileEstimatedMoney{Amount: 890_000, Currency: "KZT", Confidence: "medium"},
				CashbackEstimate:   &cashbackDXB,
				MainReason:       "Visa on arrival, direct flight, world-class shopping and beaches.",
				ReasonLabels:     []string{"Visa on arrival", "Direct flight", "Beach", "Shopping"},
				RecommendationType: "opposite_to_previous",
				Score:            0.79,
			},
		},
	}
	return respond.OK(c, resp, nil)
}

// GetHotelDetails returns a seed-based hotel details response for the given hotel ID.
//
// @Summary Get hotel full details
// @Description Returns full hotel details including rooms, ratings, and reviews.
// @Tags @consumer
// @Produce json
// @Param hotelId path string true "Hotel ID"
// @Success 200 {object} HotelDetailsFullResponse
// @Failure 404 {object} map[string]interface{}
// @Router /api/v1/hotels/{hotelId} [get]
func GetHotelDetails(c fiber.Ctx) error {
	hotelID := c.Params("hotelId")
	hotel := buildHotelDetails(hotelID)
	if hotel == nil {
		return respond.WithStatus(c, fiber.Map{"error": "hotel not found"}, nil, fiber.StatusNotFound)
	}
	return respond.OK(c, hotel, nil)
}

func buildHotelDetails(hotelID string) *HotelDetailsFullResponse {
	switch hotelID {
	case "hotel-ist-001":
		return istanbulHotelFull()
	case "hotel-ala-001":
		return almatyHotelFull()
	case "hotel-dxb-001":
		return dubaiHotelFull()
	case "hotel-ber-001":
		return berlinHotelFull()
	case "hotel-tky-001":
		return tokyoHotelFull()
	default:
		// Return a generic fallback for any unknown hotel ID
		return genericHotelFull(hotelID)
	}
}

func istanbulHotelFull() *HotelDetailsFullResponse {
	stars := 4
	district := "Galata, Beyoglu"
	label := "Excellent"
	downgrade := strPtr("room-economy-ist")
	upgrade := strPtr("room-comfort-ist")
	downgradeLabel := strPtr("Save 22 000 ₸ with Standard Room")
	upgradeLabel := strPtr("Upgrade to Deluxe Suite for +54 000 ₸")
	distCluster := float64Ptr(0.4)
	taxiAvg := &MobileMoney{Amount: 9000, Currency: "KZT"}
	locScore := float64Ptr(9.1)
	priceScore := float64Ptr(7.8)
	priceBalanced := 68_000.0
	priceEconomy := 46_000.0
	priceComfort := 122_000.0
	refTrue := true
	brkfTrue := true
	brkfFalse := false
	return &HotelDetailsFullResponse{
		HotelID:      "hotel-ist-001",
		Name:         "Galata Balance Hotel",
		City:         "Istanbul",
		District:     &district,
		Lat:          41.0255,
		Lng:          28.9742,
		Stars:        &stars,
		Rating:       HotelRatingResponse{Overall: 8.7, Scale: 10, Label: &label, ReviewCount: 1842},
		SourceRatings: []HotelSourceRatingResponse{
			{Source: "Booking.com", Rating: 8.7, Scale: 10, ReviewCount: 1842},
			{Source: "Google Hotels", Rating: 8.4, Scale: 10, ReviewCount: 3201},
			{Source: "Tripadvisor", Rating: 4.5, Scale: 5, ReviewCount: 980},
		},
		ReviewSummary: HotelReviewSummaryResponse{
			ShortSummary:   "Guests consistently praise the Bosphorus views, breakfast quality, and walkable location near Galata Tower.",
			PositivePoints: []string{"Bosphorus view", "Excellent breakfast", "Walkable location"},
			NegativePoints: []string{"Street noise at night", "Limited elevator capacity"},
			BestFor:        []string{"Couples", "Solo travelers", "Culture lovers"},
			NotIdealFor:    []string{"Light sleepers", "Large groups"},
			Confidence:     "high",
			BasedOnSources: []string{"Booking.com", "Google Hotels", "Tripadvisor"},
		},
		ReviewsBySource: []HotelReviewsSourceGroupResponse{
			{Source: "Booking.com", TotalReviews: 1842, AverageRating: 8.7, Scale: 10, Reviews: []HotelReviewResponse{
				{ReviewID: "r-ist-001", AuthorName: strPtr("Maria K."), Rating: 9.0, Scale: 10, Text: "Perfect location for exploring Istanbul on foot. Breakfast was outstanding.", Date: strPtr("2026-04-15")},
				{ReviewID: "r-ist-002", AuthorName: strPtr("James L."), Rating: 8.0, Scale: 10, Text: "Good hotel, slight street noise. Would book again.", Date: strPtr("2026-03-22")},
			}},
		},
		Rooms: []HotelRoomResponse{
			{RoomID: "room-economy-ist", Name: "Standard Room", Capacity: 2, Refundable: &refTrue, BreakfastIncluded: &brkfFalse,
				PricePerNight: MobileMoney{Amount: priceEconomy, Currency: "KZT"}, TotalPrice: MobileMoney{Amount: priceEconomy * 5, Currency: "KZT"},
				Labels: []string{"City view", "Free Wi-Fi"}, TradeoffLabel: strPtr("Economy option — save 22 000 ₸")},
			{RoomID: "room-balanced-ist", Name: "Bosphorus View Standard", Capacity: 2, Refundable: &refTrue, BreakfastIncluded: &brkfTrue,
				PricePerNight: MobileMoney{Amount: priceBalanced, Currency: "KZT"}, TotalPrice: MobileMoney{Amount: priceBalanced * 5, Currency: "KZT"},
				Labels: []string{"Bosphorus view", "Free Wi-Fi", "Breakfast included"}},
			{RoomID: "room-comfort-ist", Name: "Bosphorus Deluxe Suite", Capacity: 2, Refundable: &refTrue, BreakfastIncluded: &brkfTrue,
				PricePerNight: MobileMoney{Amount: priceComfort, Currency: "KZT"}, TotalPrice: MobileMoney{Amount: priceComfort * 5, Currency: "KZT"},
				Labels: []string{"Panoramic view", "Lounge access", "Breakfast + dinner"}, TradeoffLabel: strPtr("Comfort upgrade — +54 000 ₸")},
		},
		SelectedRoomID: "room-balanced-ist",
		RoomOptions: HotelRoomOptionsResponse{
			SelectedRoomID:  "room-balanced-ist",
			DowngradeRoomID: downgrade,
			UpgradeRoomID:   upgrade,
			SelectedReason:  "Best balance of Bosphorus view and price.",
			DowngradeLabel:  downgradeLabel,
			UpgradeLabel:    upgradeLabel,
		},
		LocationInfo: HotelLocationInfoResponse{
			DistanceToAirportKm:     float64Ptr(39.5),
			DistanceToMainClusterKm: distCluster,
			AverageTaxiToActivities: taxiAvg,
			LocationScore:           locScore,
			PriceScore:              priceScore,
		},
		Reason: "Selected for central Galata location with Bosphorus views and strong review score.",
	}
}

func almatyHotelFull() *HotelDetailsFullResponse {
	stars := 4
	district := "City center"
	label := "Excellent"
	return &HotelDetailsFullResponse{
		HotelID: "hotel-ala-001", Name: "Family View Almaty", City: "Almaty", District: &district,
		Lat: 43.238, Lng: 76.889, Stars: &stars,
		Rating: HotelRatingResponse{Overall: 4.7, Scale: 5, Label: &label, ReviewCount: 612},
		SourceRatings: []HotelSourceRatingResponse{
			{Source: "Booking.com", Rating: 4.7, Scale: 5, ReviewCount: 612},
		},
		ReviewSummary: HotelReviewSummaryResponse{
			ShortSummary:   "Families praise the location, breakfast, and easy access to sights.",
			PositivePoints: []string{"Great location", "Good breakfast"},
			NegativePoints: []string{"Some rooms feel dated"},
			BestFor:        []string{"Families"},
			NotIdealFor:    []string{"Business travelers"},
			Confidence:     "medium",
			BasedOnSources: []string{"Booking.com"},
		},
		ReviewsBySource: []HotelReviewsSourceGroupResponse{},
		Rooms: []HotelRoomResponse{
			{RoomID: "room-ala-01", Name: "Superior Room", Capacity: 2,
				PricePerNight: MobileMoney{Amount: 95000, Currency: "KZT"}, TotalPrice: MobileMoney{Amount: 190000, Currency: "KZT"},
				Labels: []string{"City view", "Free Wi-Fi", "Breakfast"}},
		},
		SelectedRoomID: "room-ala-01",
		RoomOptions: HotelRoomOptionsResponse{
			SelectedRoomID: "room-ala-01", SelectedReason: "Only available option.",
		},
		LocationInfo: HotelLocationInfoResponse{
			DistanceToAirportKm: float64Ptr(10),
		},
		Reason: "Family-friendly hotel in city center with strong reviews.",
	}
}

func dubaiHotelFull() *HotelDetailsFullResponse {
	stars := 5
	district := "Downtown Dubai"
	label := "Exceptional"
	downgrade := strPtr("room-dxb-standard")
	upgrade := strPtr("room-dxb-suite")
	downgradeLabel := strPtr("Save 30 000 ₸ with Standard Room")
	upgradeLabel := strPtr("Upgrade to Suite for +80 000 ₸")
	return &HotelDetailsFullResponse{
		HotelID: "hotel-dxb-001", Name: "Address Downtown Dubai", City: "Dubai", District: &district,
		Lat: 25.1972, Lng: 55.2796, Stars: &stars,
		Rating: HotelRatingResponse{Overall: 9.2, Scale: 10, Label: &label, ReviewCount: 3400},
		SourceRatings: []HotelSourceRatingResponse{
			{Source: "Booking.com", Rating: 9.2, Scale: 10, ReviewCount: 3400},
		},
		ReviewSummary: HotelReviewSummaryResponse{
			ShortSummary:   "Stunning Burj Khalifa views, exceptional service, world-class facilities.",
			PositivePoints: []string{"Burj Khalifa view", "Exceptional service", "World-class facilities"},
			NegativePoints: []string{"Premium pricing", "Expensive dining on-site"},
			BestFor:        []string{"Luxury travelers", "Couples"},
			NotIdealFor:    []string{"Budget travelers"},
			Confidence:     "high",
			BasedOnSources: []string{"Booking.com"},
		},
		ReviewsBySource: []HotelReviewsSourceGroupResponse{},
		Rooms: []HotelRoomResponse{
			{RoomID: "room-dxb-deluxe", Name: "Deluxe Room", Capacity: 2,
				PricePerNight: MobileMoney{Amount: 95000, Currency: "KZT"}, TotalPrice: MobileMoney{Amount: 475000, Currency: "KZT"},
				Labels: []string{"Burj Khalifa view", "Pool access", "Breakfast"}},
		},
		SelectedRoomID: "room-dxb-deluxe",
		RoomOptions: HotelRoomOptionsResponse{
			SelectedRoomID:  "room-dxb-deluxe",
			DowngradeRoomID: downgrade,
			UpgradeRoomID:   upgrade,
			SelectedReason:  "Best balance of view and price at this property.",
			DowngradeLabel:  downgradeLabel,
			UpgradeLabel:    upgradeLabel,
		},
		LocationInfo: HotelLocationInfoResponse{
			DistanceToAirportKm: float64Ptr(14),
		},
		Reason: "Icon of Dubai hospitality with unbeatable Burj Khalifa views.",
	}
}

func berlinHotelFull() *HotelDetailsFullResponse {
	stars := 4
	district := "Mitte"
	label := "Very Good"
	return &HotelDetailsFullResponse{
		HotelID: "hotel-ber-001", Name: "Hotel Berlin Mitte", City: "Berlin", District: &district,
		Lat: 52.5234, Lng: 13.4024, Stars: &stars,
		Rating: HotelRatingResponse{Overall: 8.4, Scale: 10, Label: &label, ReviewCount: 2100},
		SourceRatings: []HotelSourceRatingResponse{
			{Source: "Booking.com", Rating: 8.4, Scale: 10, ReviewCount: 2100},
		},
		ReviewSummary: HotelReviewSummaryResponse{
			ShortSummary:   "Central location, clean rooms, great access to U-Bahn.",
			PositivePoints: []string{"Central location", "Clean rooms", "Good transport"},
			NegativePoints: []string{"Limited breakfast options"},
			BestFor:        []string{"Culture lovers", "City explorers"},
			NotIdealFor:    []string{"Families with young children"},
			Confidence:     "medium",
			BasedOnSources: []string{"Booking.com"},
		},
		ReviewsBySource: []HotelReviewsSourceGroupResponse{},
		Rooms: []HotelRoomResponse{
			{RoomID: "room-ber-std", Name: "Standard Room", Capacity: 2,
				PricePerNight: MobileMoney{Amount: 120000, Currency: "KZT"}, TotalPrice: MobileMoney{Amount: 600000, Currency: "KZT"},
				Labels: []string{"City view", "Free Wi-Fi"}},
		},
		SelectedRoomID: "room-ber-std",
		RoomOptions: HotelRoomOptionsResponse{
			SelectedRoomID: "room-ber-std", SelectedReason: "Best value in Mitte.",
		},
		LocationInfo: HotelLocationInfoResponse{
			DistanceToAirportKm: float64Ptr(18),
		},
		Reason: "Best Mitte location for museum and cultural exploration.",
	}
}

func tokyoHotelFull() *HotelDetailsFullResponse {
	stars := 4
	district := "Shinjuku"
	label := "Excellent"
	return &HotelDetailsFullResponse{
		HotelID: "hotel-tky-001", Name: "Shinjuku Hotel", City: "Tokyo", District: &district,
		Lat: 35.6896, Lng: 139.6917, Stars: &stars,
		Rating: HotelRatingResponse{Overall: 8.9, Scale: 10, Label: &label, ReviewCount: 5200},
		SourceRatings: []HotelSourceRatingResponse{
			{Source: "Booking.com", Rating: 8.9, Scale: 10, ReviewCount: 5200},
		},
		ReviewSummary: HotelReviewSummaryResponse{
			ShortSummary:   "Excellent location, spotlessly clean, friendly staff.",
			PositivePoints: []string{"Excellent location", "Spotlessly clean", "Friendly staff"},
			NegativePoints: []string{"Small rooms (typical Tokyo)"},
			BestFor:        []string{"City explorers", "First-time Japan visitors"},
			NotIdealFor:    []string{"Those wanting large rooms"},
			Confidence:     "high",
			BasedOnSources: []string{"Booking.com"},
		},
		ReviewsBySource: []HotelReviewsSourceGroupResponse{},
		Rooms: []HotelRoomResponse{
			{RoomID: "room-tky-std", Name: "Standard Room", Capacity: 2,
				PricePerNight: MobileMoney{Amount: 130000, Currency: "KZT"}, TotalPrice: MobileMoney{Amount: 650000, Currency: "KZT"},
				Labels: []string{"City view", "Free Wi-Fi", "Luggage storage"}},
		},
		SelectedRoomID: "room-tky-std",
		RoomOptions: HotelRoomOptionsResponse{
			SelectedRoomID: "room-tky-std", SelectedReason: "Best access to Shinjuku station.",
		},
		LocationInfo: HotelLocationInfoResponse{
			DistanceToAirportKm: float64Ptr(60),
		},
		Reason: "Shinjuku hub for exploring Tokyo efficiently by rail.",
	}
}

func genericHotelFull(hotelID string) *HotelDetailsFullResponse {
	stars := 3
	district := "City center"
	label := "Very Good"
	return &HotelDetailsFullResponse{
		HotelID: hotelID, Name: "City Center Hotel", City: "Unknown", District: &district,
		Lat: 51.5, Lng: 0.12, Stars: &stars,
		Rating: HotelRatingResponse{Overall: 8.2, Scale: 10, Label: &label, ReviewCount: 800},
		SourceRatings: []HotelSourceRatingResponse{
			{Source: "Booking.com", Rating: 8.2, Scale: 10, ReviewCount: 800},
		},
		ReviewSummary: HotelReviewSummaryResponse{
			ShortSummary:   "Clean rooms and helpful staff.",
			PositivePoints: []string{"Clean", "Helpful staff"},
			NegativePoints: []string{"Limited amenities"},
			BestFor:        []string{"Business travelers"},
			NotIdealFor:    []string{"Luxury seekers"},
			Confidence:     "low",
			BasedOnSources: []string{"Booking.com"},
		},
		ReviewsBySource: []HotelReviewsSourceGroupResponse{},
		Rooms: []HotelRoomResponse{
			{RoomID: "room-generic-std", Name: "Standard Room", Capacity: 2,
				PricePerNight: MobileMoney{Amount: 80000, Currency: "KZT"}, TotalPrice: MobileMoney{Amount: 400000, Currency: "KZT"},
				Labels: []string{"Free Wi-Fi", "Air conditioning"}},
		},
		SelectedRoomID: "room-generic-std",
		RoomOptions: HotelRoomOptionsResponse{
			SelectedRoomID: "room-generic-std", SelectedReason: "Good location and value.",
		},
		LocationInfo: HotelLocationInfoResponse{
			DistanceToAirportKm: float64Ptr(20),
		},
		Reason: "Good location and value.",
	}
}
