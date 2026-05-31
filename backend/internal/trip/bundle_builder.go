package trip

import (
	"fmt"
	"strings"
	"time"
)

// buildMobileBundle maps an internal Trip to the mobile-compatible read model.
// It uses the destination seed to populate segments, map data, and budget items.
func buildMobileBundle(trip *Trip) *MobileTripBundle {
	dest := normalizeCountry(trip.DestinationCountry)
	if dest == "" {
		dest = trip.DestinationCountry
	}
	city := trip.DestinationCity
	if city == "" {
		city = defaultCityForCountry(dest)
	}
	origin := trip.OriginCity
	if origin == "" {
		origin = "Almaty"
	}

	cfg := destinationConfig(dest, city, origin, trip)
	nights := durationDays(trip.StartDate, trip.EndDate)
	if nights <= 0 {
		nights = 5
	}
	people := 2
	if len(trip.Travelers) > 0 {
		people = len(trip.Travelers)
	}

	totalCost := float64(trip.BudgetSummary.GrandTotal)
	if totalCost == 0 {
		totalCost = cfg.baseCost
	}
	cashbackAmount := totalCost * cfg.cashbackPct / 100

	econSavings := totalCost * 0.18
	comfortExtra := totalCost * 0.28

	return &MobileTripBundle{
		TripID:         trip.ID.String(),
		Title:          bundleTitle(trip, city),
		Subtitle:       cfg.subtitle,
		StartDate:      trip.StartDate,
		EndDate:        trip.EndDate,
		DurationDays:   nights,
		PeopleCount:    people,
		Currency:       "KZT",
		SelectedMode:   "balanced",
		AvailableModes: []string{"economy", "balanced", "comfort"},
		Summary: MobileSummary{
			EstimatedTotalCost:     MobileMoney{Amount: totalCost, Currency: "KZT"},
			EstimatedTotalCashback: &MobileMoney{Amount: cashbackAmount, Currency: "KZT"},
			WeatherSummary:         cfg.weather,
			VisaStatus:             cfg.visaStatus,
			MainLabels:             cfg.mainLabels,
		},
		RouteNavigator: cfg.routeNavigator,
		Map:            cfg.tripMap,
		Segments:       cfg.segments(trip, nights),
		Budget:         buildBudget(totalCost, cashbackAmount, trip),
		ModeVariants: map[string]MobileModeVariant{
			"economy": {
				TotalCost:                  totalCost - econSavings,
				HotelStrategy:              "farther_but_cheaper",
				TransportStrategy:          "public_transport_first",
				EstimatedTravelTimeMinutes: 920,
				SavingsComparedToBalanced:  &econSavings,
				TradeoffLabel:              "Cheaper, but more time in transit",
			},
			"balanced": {
				TotalCost:                  totalCost,
				HotelStrategy:              "balanced_location_price",
				TransportStrategy:          "mixed",
				EstimatedTravelTimeMinutes: 720,
				TradeoffLabel:              "Best balance of comfort and price",
			},
			"comfort": {
				TotalCost:                   totalCost + comfortExtra,
				HotelStrategy:               "closer_to_activities",
				TransportStrategy:           "taxi_and_direct_routes",
				EstimatedTravelTimeMinutes:  480,
				ExtraCostComparedToBalanced: &comfortExtra,
				TradeoffLabel:               "More comfort, less time on the road",
			},
		},
		Visa:       buildVisa(trip.VisaInfo),
		Cashback:   buildCashback(cashbackAmount, cfg.cashbackPct),
		Challenges: []interface{}{},
		Warnings:   cfg.warnings,
	}
}

func bundleTitle(trip *Trip, city string) string {
	if trip.Title != "" {
		return trip.Title
	}
	return fmt.Sprintf("%s trip", city)
}

func durationDays(start, end string) int {
	s, err1 := time.Parse("2006-01-02", start)
	e, err2 := time.Parse("2006-01-02", end)
	if err1 != nil || err2 != nil {
		return 5
	}
	d := int(e.Sub(s).Hours() / 24)
	if d <= 0 {
		return 5
	}
	return d
}

func buildBudget(total, cashback float64, trip *Trip) MobileBudgetBreakdown {
	transport := float64(0)
	if trip.SelectedTransport != nil {
		transport = float64(trip.SelectedTransport.Price)
	}
	hotel := float64(0)
	if trip.SelectedHotel != nil {
		hotel = float64(trip.SelectedHotel.Price)
	}
	nights := durationDays(trip.StartDate, trip.EndDate)
	if nights <= 0 {
		nights = 5
	}
	hotelTotal := hotel * float64(nights)

	remaining := total - transport - hotelTotal - cashback
	if remaining < 0 {
		remaining = total * 0.35
	}
	food := remaining * 0.45
	activities := remaining * 0.35
	localTransport := remaining * 0.20

	return MobileBudgetBreakdown{
		Total: MobileEstimatedMoney{Amount: total, Currency: "KZT", Confidence: "medium"},
		Items: []MobileBudgetItem{
			{Category: "flights", Title: "Flights", Amount: transport, Currency: "KZT"},
			{Category: "hotels", Title: fmt.Sprintf("Hotel (%d nights)", nights), Amount: hotelTotal, Currency: "KZT"},
			{Category: "local_transport", Title: "Local transport", Amount: localTransport, Currency: "KZT"},
			{Category: "food", Title: "Food and restaurants", Amount: food, Currency: "KZT"},
			{Category: "activities", Title: "Activities and events", Amount: activities, Currency: "KZT"},
			{Category: "cashback_discount", Title: "Halyk cashback", Amount: -cashback, Currency: "KZT"},
		},
	}
}

func buildVisa(v VisaInfo) *MobileVisa {
	status := "unknown"
	required := true
	req := strings.ToLower(v.Requirement)
	switch {
	case strings.Contains(req, "no visa") || strings.Contains(req, "visa-free") || strings.Contains(req, "visa free") || strings.Contains(req, "domestic"):
		status = "visa_free"
		required = false
	case strings.Contains(req, "on arrival") || strings.Contains(req, "on-arrival"):
		status = "visa_on_arrival"
		required = false
	case strings.Contains(req, "required") || strings.Contains(req, "apply") || strings.Contains(req, "schengen"):
		status = "visa_required"
		required = true
	}
	country := v.Country
	if country == "" {
		country = "Unknown"
	}
	var notes *string
	if v.Notes != "" {
		notes = strPtr(v.Notes)
	}
	return &MobileVisa{
		Citizenship:        "Kazakhstan",
		DestinationCountry: country,
		Status:             status,
		Required:           required,
		Notes:              notes,
		Confidence:         "medium",
	}
}

func buildCashback(amount, pct float64) *MobileCashback {
	boosted := pct + 1.5
	return &MobileCashback{
		EstimatedTotal: MobileMoney{Amount: amount, Currency: "KZT"},
		BasePercent:    pct,
		BoostedPercent: &boosted,
		Items:          []interface{}{},
	}
}

// strPtr is a convenience helper.
func strPtr(s string) *string { return &s }

// intPtr is a convenience helper.
func intPtr(i int) *int { return &i }

// float64Ptr is a convenience helper.
func float64Ptr(f float64) *float64 { return &f }

// ─── Per-destination config ────────────────────────────────────────────────

type destConfig struct {
	subtitle       string
	weather        string
	visaStatus     string
	mainLabels     []string
	routeNavigator []MobileRouteStop
	tripMap        MobileTripMap
	baseCost       float64
	cashbackPct    float64
	warnings       []MobileWarning
	segments       func(trip *Trip, nights int) []MobileSegment
}

func destinationConfig(country, city, origin string, trip *Trip) destConfig {
	switch normalizeCountry(country) {
	case "Turkey":
		return turkeyConfig(city, origin, trip)
	case "UAE":
		return uaeConfig(city, origin, trip)
	case "Germany":
		return germanyConfig(city, origin, trip)
	case "Japan":
		return japanConfig(city, origin, trip)
	default:
		return kazakhstanConfig(city, origin, trip)
	}
}

// ─── Turkey / Istanbul ─────────────────────────────────────────────────────

func turkeyConfig(city, origin string, trip *Trip) destConfig {
	airportMarkerID := "marker-ist-airport"
	hotelMarkerID := "marker-ist-hotel"
	galataMarkerID := "marker-ist-galata"
	hagiaSophiaMarkerID := "marker-ist-hagia"
	transferSegID := "seg-transfer-ist"
	arrivalSegID := "seg-arrival-ist"
	hotelSegID := "seg-hotel-ist"

	markers := []MobileMarker{
		{MarkerID: airportMarkerID, SegmentID: &arrivalSegID, Type: "airport", Title: "Istanbul Airport", Lat: 41.2608, Lng: 28.7418},
		{MarkerID: hotelMarkerID, SegmentID: &hotelSegID, Type: "hotel", Title: "Galata Balance Hotel", Lat: 41.0255, Lng: 28.9742},
		{MarkerID: galataMarkerID, Type: "attraction", Title: "Galata Tower", Lat: 41.0256, Lng: 28.9741},
		{MarkerID: hagiaSophiaMarkerID, Type: "attraction", Title: "Hagia Sophia", Lat: 41.0086, Lng: 28.9802},
	}
	routes := []MobileRoute{
		{
			RouteID: "route-airport-hotel", FromMarkerID: airportMarkerID, ToMarkerID: hotelMarkerID,
			SegmentID: &transferSegID, TransportType: "shuttle", DistanceKm: 39.5, DurationMinutes: 55,
			EstimatedCost: &MobileMoney{Amount: 12000, Currency: "KZT"},
			AlternativeRoutes: []MobileAltRoute{
				{TransportType: "taxi", DurationMinutes: 40, EstimatedCost: &MobileMoney{Amount: 19000, Currency: "KZT"}, Reason: "Faster but more expensive"},
			},
		},
	}

	return destConfig{
		subtitle:    fmt.Sprintf("Visa-free · Direct flight from %s · 4.2%% cashback", origin),
		weather:     "Warm and sunny, 24–28°C. Light rain chance on day 3.",
		visaStatus:  "visa_free",
		mainLabels:  []string{"Visa-free", "4.2% cashback", "Central hotel", "Direct flight"},
		baseCost:    742_000,
		cashbackPct: 3.0,
		warnings: []MobileWarning{
			{Type: "airport_far_from_hotel", Severity: "low", SegmentID: &transferSegID,
				Message: "Istanbul Airport is 40 km from the city center. Allow 45–60 min for the transfer."},
		},
		routeNavigator: []MobileRouteStop{
			{StopID: "stop-ist", Title: "Istanbul", StartDate: trip.StartDate, EndDate: trip.EndDate, TransportToNext: nil,
				Coordinates: &MobileCoords{Lat: 41.015, Lng: 28.979}},
		},
		tripMap: MobileTripMap{
			InitialCamera: MobileMapCamera{CenterLat: 41.015, CenterLng: 28.979, Zoom: 11},
			Markers:       markers,
			Routes:        routes,
		},
		segments: func(t *Trip, nights int) []MobileSegment {
			airline := "Air Astana"
			flightNum := "KC721"
			return []MobileSegment{
				{
					SegmentID: arrivalSegID, Type: "arrival", Title: fmt.Sprintf("Arrival in %s", city),
					Date: t.StartDate, DayNumber: 1, StartTime: strPtr("09:30"), EndTime: strPtr("10:15"),
					Icon: "airplane.arrival", Status: "planned",
					LinkedMarkerIDs: []string{airportMarkerID}, LinkedRouteIDs: []string{},
					Price: &MobileMoney{Amount: 246000, Currency: "KZT"},
					Labels:      []string{"Direct flight", "Morning arrival"},
					Description: strPtr(fmt.Sprintf("Direct flight from %s to Istanbul.", origin)),
					Details: MobileSegmentDetails{Kind: "arrival", Payload: MobileArrivalPayload{
						Flight: MobileFlightInfo{
							FromAirport: "ALA", ToAirport: "IST", Airline: &airline, FlightNumber: &flightNum,
							DepartureTime: t.StartDate + "T05:15:00", ArrivalTime: t.StartDate + "T09:30:00",
							DurationMinutes: 255, Stops: 0, CabinClass: "economy",
							Price: &MobileMoney{Amount: 246000, Currency: "KZT"},
						},
					}},
				},
				{
					SegmentID: transferSegID, Type: "transfer", Title: "Airport → Galata hotel",
					Date: t.StartDate, DayNumber: 1, StartTime: strPtr("10:25"), EndTime: strPtr("11:20"),
					Icon: "bus.fill", Status: "recommended",
					LinkedMarkerIDs: []string{airportMarkerID, hotelMarkerID}, LinkedRouteIDs: []string{"route-airport-hotel"},
					Price: &MobileMoney{Amount: 12000, Currency: "KZT"},
					Labels:      []string{"Shuttle recommended", "Lower stress with luggage"},
					Description: strPtr("Shuttle is cheaper than taxi and easier with luggage."),
					Details: MobileSegmentDetails{Kind: "transfer", Payload: MobileTransferPayload{
						From: "Istanbul Airport", To: "Galata Balance Hotel", RecommendedTransport: "shuttle",
						DistanceKm: 39.5, DurationMinutes: 55,
						TaxiEstimate:            &MobileMoney{Amount: 19000, Currency: "KZT"},
						PublicTransportEstimate: &MobilePublicTransportEstimate{Amount: 3500, Currency: "KZT", DurationMinutes: 90},
						Reason:                  "Best balance of cost, predictability, and luggage comfort.",
					}},
				},
				istanbulHotelSegment(hotelSegID, hotelMarkerID, t, nights),
				istanbulDaySegment("seg-day1-ist", 2, t.StartDate, city, true),
				istanbulDaySegment("seg-day2-ist", 3, t.StartDate, city, false),
				{
					SegmentID: "seg-departure-ist", Type: "departure", Title: fmt.Sprintf("Return to %s", origin),
					Date: t.EndDate, DayNumber: nights, StartTime: strPtr("20:00"), EndTime: strPtr("23:55"),
					Icon: "airplane.departure", Status: "planned",
					LinkedMarkerIDs: []string{airportMarkerID}, LinkedRouteIDs: []string{},
					Price: &MobileMoney{Amount: 246000, Currency: "KZT"},
					Labels:      []string{"Evening flight", "Direct"},
					Description: strPtr("Return direct flight to Almaty."),
					Details: MobileSegmentDetails{Kind: "departure", Payload: MobileDeparturePayload{
						Flight: MobileFlightInfo{
							FromAirport: "IST", ToAirport: "ALA", Airline: &airline, FlightNumber: strPtr("KC722"),
							DepartureTime: t.EndDate + "T20:00:00", ArrivalTime: t.EndDate + "T23:55:00",
							DurationMinutes: 235, Stops: 0, CabinClass: "economy",
							Price: &MobileMoney{Amount: 246000, Currency: "KZT"},
						},
						CheckoutTime:              strPtr("12:00"),
						RecommendedLeaveHotelTime: strPtr("17:30"),
					}},
				},
			}
		},
	}
}

func istanbulHotelSegment(segID, markerID string, trip *Trip, nights int) MobileSegment {
	name := "Galata Balance Hotel"
	district := "Galata, Beyoglu"
	stars := 4
	rating := 8.7
	ratingLabel := "8.7 Excellent"
	summary := "Guests praise the Bosphorus view, breakfast quality, and walkable location."
	roomID := "room-balanced-ist"
	roomName := "Bosphorus View Standard"
	downgrade := "Save 22 000 ₸"
	upgrade := "Upgrade for +54 000 ₸"
	distCluster := 0.4
	taxiAvg := MobileMoney{Amount: 9000, Currency: "KZT"}
	locScore := 9.1
	pricScore := 7.8
	priceNight := 68_000.0
	if trip.SelectedHotel != nil && trip.SelectedHotel.Price > 0 {
		priceNight = float64(trip.SelectedHotel.Price)
	}
	return MobileSegment{
		SegmentID: segID, Type: "hotel_stay", Title: "Check-in: " + name,
		Date: trip.StartDate, DayNumber: 1, Icon: "bed.double.fill", Status: "selected",
		LinkedMarkerIDs: []string{markerID}, LinkedRouteIDs: []string{"route-airport-hotel"},
		Price: &MobileMoney{Amount: priceNight * float64(nights), Currency: "KZT"},
		Labels:      []string{ratingLabel, fmt.Sprintf("%d nights", nights)},
		Description: strPtr("Central location near Galata Tower; easy access to attractions."),
		Details: MobileSegmentDetails{Kind: "hotel", Payload: MobileHotelPayload{
			HotelID: "hotel-ist-001", Name: name, District: &district, Stars: &stars,
			Rating: &rating, RatingLabel: &ratingLabel, ReviewShortSummary: &summary,
			SelectedRoomID: &roomID, SelectedRoomName: &roomName,
			PricePerNight: MobileMoney{Amount: priceNight, Currency: "KZT"}, Nights: nights,
			DowngradeLabel: &downgrade, UpgradeLabel: &upgrade,
			DistanceToMainClusterKm: &distCluster, AverageTaxiToActivities: &taxiAvg,
			LocationScore: &locScore, PriceScore: &pricScore,
			Reason: "Selected for central location near top sights and positive review score.",
		}},
	}
}

func istanbulDaySegment(segID string, dayNum int, startDate, city string, first bool) MobileSegment {
	t := int(22)
	condition := "sunny"
	rain := int(10)
	wind := int(12)
	weather := &MobileWeatherInfo{TemperatureC: t, Condition: condition, RainChancePercent: &rain, WindKph: &wind}

	activities := []MobileActivityItem{}
	if first {
		activities = []MobileActivityItem{
			{ActivityID: "act-galata", Title: "Galata Tower", Type: "attraction",
				StartTime: strPtr("12:00"), DurationMinutes: 60,
				Price: &MobileMoney{Amount: 8000, Currency: "KZT"},
				MarkerID: strPtr("marker-ist-galata"),
				Reason:   strPtr("Iconic 360° view over the Bosphorus and Golden Horn.")},
			{ActivityID: "act-hagia", Title: "Hagia Sophia", Type: "attraction",
				StartTime: strPtr("14:30"), DurationMinutes: 90,
				Price:    nil,
				MarkerID: strPtr("marker-ist-hagia"),
				Reason:   strPtr("UNESCO heritage site — free entry.")},
			{ActivityID: "act-dinner1", Title: "Dinner at Karaköy Lokantası", Type: "restaurant",
				StartTime: strPtr("19:30"), DurationMinutes: 90,
				Price:  &MobileMoney{Amount: 22000, Currency: "KZT"},
				Reason: strPtr("Top-rated local restaurant in the Galata neighbourhood.")},
		}
	} else {
		activities = []MobileActivityItem{
			{ActivityID: "act-bazaar", Title: "Grand Bazaar", Type: "shopping",
				StartTime: strPtr("10:00"), DurationMinutes: 120,
				Price:  &MobileMoney{Amount: 5000, Currency: "KZT"},
				Reason: strPtr("One of the world's oldest and largest covered markets.")},
			{ActivityID: "act-topkapi", Title: "Topkapi Palace", Type: "attraction",
				StartTime: strPtr("13:00"), DurationMinutes: 150,
				Price:  &MobileMoney{Amount: 12000, Currency: "KZT"},
				Reason: strPtr("Essential Ottoman imperial heritage site.")},
		}
	}
	title := fmt.Sprintf("Day %d in %s", dayNum-1, city)
	desc := "City exploration day"
	return MobileSegment{
		SegmentID: segID, Type: "day_itinerary", Title: title,
		Date: startDate, DayNumber: dayNum, Icon: "map.fill", Status: "planned",
		LinkedMarkerIDs: []string{}, LinkedRouteIDs: []string{},
		Labels:      []string{fmt.Sprintf("%d places", len(activities))},
		Description: &desc,
		Details: MobileSegmentDetails{Kind: "day_itinerary", Payload: MobileDayItineraryPayload{
			City: city, ExperienceCount: len(activities), Weather: weather,
			Pace: "medium", OverloadScore: 0.4, Activities: activities,
		}},
	}
}

// ─── Kazakhstan / Almaty ───────────────────────────────────────────────────

func kazakhstanConfig(city, origin string, trip *Trip) destConfig {
	hotelMarkerID := "marker-ala-hotel"
	kokTobeMarkerID := "marker-ala-koktobe"
	hotelSegID := "seg-hotel-ala"

	markers := []MobileMarker{
		{MarkerID: hotelMarkerID, SegmentID: &hotelSegID, Type: "hotel", Title: "Family View Almaty", Lat: 43.238, Lng: 76.889},
		{MarkerID: kokTobeMarkerID, Type: "attraction", Title: "Kok Tobe", Lat: 43.2227, Lng: 76.9489},
	}

	return destConfig{
		subtitle:    fmt.Sprintf("Domestic · No visa required · from %s", origin),
		weather:     "Mild and sunny, 18–24°C. Good season for outdoor activities.",
		visaStatus:  "visa_free",
		mainLabels:  []string{"No visa", "Domestic route", "Family-friendly"},
		baseCost:    180_000,
		cashbackPct: 2.5,
		warnings:    []MobileWarning{},
		routeNavigator: []MobileRouteStop{
			{StopID: "stop-ala", Title: "Almaty", StartDate: trip.StartDate, EndDate: trip.EndDate,
				Coordinates: &MobileCoords{Lat: 43.238, Lng: 76.889}},
		},
		tripMap: MobileTripMap{
			InitialCamera: MobileMapCamera{CenterLat: 43.238, CenterLng: 76.889, Zoom: 12},
			Markers:       markers,
			Routes:        []MobileRoute{},
		},
		segments: func(t *Trip, nights int) []MobileSegment {
			airline := "Air Astana"
			fn := "KC101"
			priceNight := 95_000.0
			if t.SelectedHotel != nil && t.SelectedHotel.Price > 0 {
				priceNight = float64(t.SelectedHotel.Price)
			}
			district := "City center"
			stars := 4
			rating := 4.7
			ratingLabel := "4.7 Excellent"
			summary := "Families praise the location, breakfast, and easy access to sights."
			roomID := "room-ala-01"
			roomName := "Superior Room"
			_ = fn
			return []MobileSegment{
				{
					SegmentID: "seg-arrival-ala", Type: "arrival", Title: fmt.Sprintf("Arrival in %s", city),
					Date: t.StartDate, DayNumber: 1, StartTime: strPtr("10:00"),
					Icon: "airplane.arrival", Status: "planned",
					LinkedMarkerIDs: []string{}, LinkedRouteIDs: []string{},
					Price:  &MobileMoney{Amount: 58000, Currency: "KZT"},
					Labels: []string{"Domestic flight"},
					Details: MobileSegmentDetails{Kind: "arrival", Payload: MobileArrivalPayload{
						Flight: MobileFlightInfo{
							FromAirport: "NQZ", ToAirport: "ALA", Airline: &airline, FlightNumber: strPtr("KC101"),
							DepartureTime: t.StartDate + "T08:00:00", ArrivalTime: t.StartDate + "T10:00:00",
							DurationMinutes: 120, Stops: 0, CabinClass: "economy",
							Price: &MobileMoney{Amount: 58000, Currency: "KZT"},
						},
					}},
				},
				{
					SegmentID: hotelSegID, Type: "hotel_stay", Title: "Check-in: Family View Almaty",
					Date: t.StartDate, DayNumber: 1, Icon: "bed.double.fill", Status: "selected",
					LinkedMarkerIDs: []string{hotelMarkerID}, LinkedRouteIDs: []string{},
					Price: &MobileMoney{Amount: priceNight * float64(nights), Currency: "KZT"},
					Labels: []string{ratingLabel, fmt.Sprintf("%d nights", nights)},
					Details: MobileSegmentDetails{Kind: "hotel", Payload: MobileHotelPayload{
						HotelID: "hotel-ala-001", Name: "Family View Almaty", District: &district,
						Stars: &stars, Rating: &rating, RatingLabel: &ratingLabel, ReviewShortSummary: &summary,
						SelectedRoomID: &roomID, SelectedRoomName: &roomName,
						PricePerNight: MobileMoney{Amount: priceNight, Currency: "KZT"}, Nights: nights,
						Reason: "Family-friendly hotel near major attractions.",
					}},
				},
				{
					SegmentID: "seg-day1-ala", Type: "day_itinerary", Title: fmt.Sprintf("Day 2 in %s", city),
					Date: t.StartDate, DayNumber: 2, Icon: "map.fill", Status: "planned",
					LinkedMarkerIDs: []string{kokTobeMarkerID}, LinkedRouteIDs: []string{},
					Labels: []string{"3 places"},
					Details: MobileSegmentDetails{Kind: "day_itinerary", Payload: MobileDayItineraryPayload{
						City: city, ExperienceCount: 3,
						Weather: &MobileWeatherInfo{TemperatureC: 22, Condition: "sunny"},
						Pace: "medium", OverloadScore: 0.3,
						Activities: []MobileActivityItem{
							{ActivityID: "act-koktobe", Title: "Kok Tobe", Type: "attraction",
								StartTime: strPtr("10:00"), DurationMinutes: 120,
								Price: &MobileMoney{Amount: 12000, Currency: "KZT"},
								MarkerID: &kokTobeMarkerID,
								Reason:   strPtr("Scenic hilltop with panoramic city views.")},
						},
					}},
				},
				{
					SegmentID: "seg-departure-ala", Type: "departure", Title: "Return flight",
					Date: t.EndDate, DayNumber: nights, StartTime: strPtr("21:00"),
					Icon: "airplane.departure", Status: "planned",
					LinkedMarkerIDs: []string{}, LinkedRouteIDs: []string{},
					Price: &MobileMoney{Amount: 58000, Currency: "KZT"},
					Labels: []string{"Evening flight"},
					Details: MobileSegmentDetails{Kind: "departure", Payload: MobileDeparturePayload{
						Flight: MobileFlightInfo{
							FromAirport: "ALA", ToAirport: "NQZ", Airline: &airline, FlightNumber: strPtr("KC102"),
							DepartureTime: t.EndDate + "T21:00:00", ArrivalTime: t.EndDate + "T23:00:00",
							DurationMinutes: 120, Stops: 0, CabinClass: "economy",
						},
						CheckoutTime: strPtr("12:00"),
					}},
				},
			}
		},
	}
}

// ─── UAE / Dubai ───────────────────────────────────────────────────────────

func uaeConfig(city, origin string, trip *Trip) destConfig {
	airportID := "marker-dxb-airport"
	hotelID := "marker-dxb-hotel"
	hotelSegID := "seg-hotel-dxb"
	arrivalSegID := "seg-arrival-dxb"

	return destConfig{
		subtitle:    "Visa on arrival · Direct flight · Beach and cityscape",
		weather:     "Hot and sunny, 32–38°C. Outdoor activities best in morning or evening.",
		visaStatus:  "visa_on_arrival",
		mainLabels:  []string{"Visa on arrival", "Direct flight", "Beach + city", "Tax-free shopping"},
		baseCost:    890_000,
		cashbackPct: 3.5,
		warnings: []MobileWarning{
			{Type: "weather_risk", Severity: "medium", Message: "Outdoor activities are best planned in the morning or after 5 PM due to intense daytime heat."},
		},
		routeNavigator: []MobileRouteStop{
			{StopID: "stop-dxb", Title: "Dubai", StartDate: trip.StartDate, EndDate: trip.EndDate,
				Coordinates: &MobileCoords{Lat: 25.2048, Lng: 55.2708}},
		},
		tripMap: MobileTripMap{
			InitialCamera: MobileMapCamera{CenterLat: 25.2048, CenterLng: 55.2708, Zoom: 11},
			Markers: []MobileMarker{
				{MarkerID: airportID, SegmentID: &arrivalSegID, Type: "airport", Title: "Dubai International Airport", Lat: 25.2532, Lng: 55.3657},
				{MarkerID: hotelID, SegmentID: &hotelSegID, Type: "hotel", Title: "Address Downtown Dubai", Lat: 25.1972, Lng: 55.2796},
			},
			Routes: []MobileRoute{},
		},
		segments: func(t *Trip, nights int) []MobileSegment {
			airline := "flydubai"
			fn := "FZ711"
			priceNight := 95_000.0
			if t.SelectedHotel != nil && t.SelectedHotel.Price > 0 {
				priceNight = float64(t.SelectedHotel.Price)
			}
			district := "Downtown Dubai"
			stars := 5
			rating := 9.2
			ratingLabel := "9.2 Excellent"
			summary := "Stunning Burj Khalifa views, exceptional service."
			roomID := "room-dxb-deluxe"
			roomName := "Deluxe Room"
			return []MobileSegment{
				{
					SegmentID: arrivalSegID, Type: "arrival", Title: "Arrival in Dubai",
					Date: t.StartDate, DayNumber: 1, StartTime: strPtr("09:10"),
					Icon: "airplane.arrival", Status: "planned",
					LinkedMarkerIDs: []string{airportID}, LinkedRouteIDs: []string{},
					Price: &MobileMoney{Amount: 280000, Currency: "KZT"},
					Labels: []string{"Direct flight"},
					Details: MobileSegmentDetails{Kind: "arrival", Payload: MobileArrivalPayload{
						Flight: MobileFlightInfo{
							FromAirport: "ALA", ToAirport: "DXB", Airline: &airline, FlightNumber: &fn,
							DepartureTime: t.StartDate + "T06:30:00", ArrivalTime: t.StartDate + "T09:10:00",
							DurationMinutes: 280, Stops: 0, CabinClass: "economy",
							Price: &MobileMoney{Amount: 280000, Currency: "KZT"},
						},
					}},
				},
				{
					SegmentID: hotelSegID, Type: "hotel_stay", Title: "Check-in: Address Downtown Dubai",
					Date: t.StartDate, DayNumber: 1, Icon: "bed.double.fill", Status: "selected",
					LinkedMarkerIDs: []string{hotelID}, LinkedRouteIDs: []string{},
					Price: &MobileMoney{Amount: priceNight * float64(nights), Currency: "KZT"},
					Labels: []string{ratingLabel, fmt.Sprintf("%d nights", nights)},
					Details: MobileSegmentDetails{Kind: "hotel", Payload: MobileHotelPayload{
						HotelID: "hotel-dxb-001", Name: "Address Downtown Dubai", District: &district,
						Stars: &stars, Rating: &rating, RatingLabel: &ratingLabel, ReviewShortSummary: &summary,
						SelectedRoomID: &roomID, SelectedRoomName: &roomName,
						PricePerNight: MobileMoney{Amount: priceNight, Currency: "KZT"}, Nights: nights,
						Reason: "Best location near Burj Khalifa and Dubai Mall.",
					}},
				},
				{
					SegmentID: "seg-departure-dxb", Type: "departure", Title: "Return to Almaty",
					Date: t.EndDate, DayNumber: nights, StartTime: strPtr("21:45"),
					Icon: "airplane.departure", Status: "planned",
					LinkedMarkerIDs: []string{airportID}, LinkedRouteIDs: []string{},
					Price: &MobileMoney{Amount: 280000, Currency: "KZT"},
					Labels: []string{"Evening flight"},
					Details: MobileSegmentDetails{Kind: "departure", Payload: MobileDeparturePayload{
						Flight: MobileFlightInfo{
							FromAirport: "DXB", ToAirport: "ALA", Airline: &airline, FlightNumber: strPtr("FZ712"),
							DepartureTime: t.EndDate + "T21:45:00", ArrivalTime: t.EndDate + "T23:55:00",
							DurationMinutes: 280, Stops: 0, CabinClass: "economy",
						},
						CheckoutTime: strPtr("11:00"),
					}},
				},
			}
		},
	}
}

// ─── Germany / Berlin ──────────────────────────────────────────────────────

func germanyConfig(city, origin string, trip *Trip) destConfig {
	arrivalSegID := "seg-arrival-ber"
	hotelSegID := "seg-hotel-ber"

	return destConfig{
		subtitle:    "Schengen visa required · Rich culture and history",
		weather:     "Mild, 16–22°C. Some rain possible, pack a light jacket.",
		visaStatus:  "visa_required",
		mainLabels:  []string{"Schengen visa", "Cultural highlights", "Public transport"},
		baseCost:    1_050_000,
		cashbackPct: 2.0,
		warnings: []MobileWarning{
			{Type: "visa_uncertain", Severity: "high", Message: "Schengen visa required. Apply at least 3–4 weeks in advance."},
		},
		routeNavigator: []MobileRouteStop{
			{StopID: "stop-ber", Title: "Berlin", StartDate: trip.StartDate, EndDate: trip.EndDate,
				Coordinates: &MobileCoords{Lat: 52.52, Lng: 13.405}},
		},
		tripMap: MobileTripMap{
			InitialCamera: MobileMapCamera{CenterLat: 52.52, CenterLng: 13.405, Zoom: 12},
			Markers: []MobileMarker{
				{MarkerID: "marker-ber-airport", SegmentID: &arrivalSegID, Type: "airport", Title: "Berlin Brandenburg Airport", Lat: 52.3667, Lng: 13.5033},
				{MarkerID: "marker-ber-hotel", SegmentID: &hotelSegID, Type: "hotel", Title: "Hotel Berlin Mitte", Lat: 52.5234, Lng: 13.4024},
			},
			Routes: []MobileRoute{},
		},
		segments: func(t *Trip, nights int) []MobileSegment {
			airline := "Lufthansa"
			fn := "LH7830"
			priceNight := 120_000.0
			district := "Mitte"
			stars := 4
			rating := 8.4
			ratingLabel := "8.4 Very Good"
			summary := "Central location, clean rooms, great breakfast."
			roomID := "room-ber-std"
			roomName := "Standard Room"
			return []MobileSegment{
				{
					SegmentID: arrivalSegID, Type: "arrival", Title: "Arrival in Berlin",
					Date: t.StartDate, DayNumber: 1, StartTime: strPtr("14:00"),
					Icon: "airplane.arrival", Status: "planned",
					LinkedMarkerIDs: []string{"marker-ber-airport"}, LinkedRouteIDs: []string{},
					Price: &MobileMoney{Amount: 420000, Currency: "KZT"},
					Labels: []string{"1 stop", "Economy"},
					Details: MobileSegmentDetails{Kind: "arrival", Payload: MobileArrivalPayload{
						Flight: MobileFlightInfo{
							FromAirport: "ALA", ToAirport: "BER", Airline: &airline, FlightNumber: &fn,
							DepartureTime: t.StartDate + "T04:00:00", ArrivalTime: t.StartDate + "T14:00:00",
							DurationMinutes: 600, Stops: 1, CabinClass: "economy",
							Price: &MobileMoney{Amount: 420000, Currency: "KZT"},
						},
					}},
				},
				{
					SegmentID: hotelSegID, Type: "hotel_stay", Title: "Check-in: Hotel Berlin Mitte",
					Date: t.StartDate, DayNumber: 1, Icon: "bed.double.fill", Status: "selected",
					LinkedMarkerIDs: []string{"marker-ber-hotel"}, LinkedRouteIDs: []string{},
					Price: &MobileMoney{Amount: priceNight * float64(nights), Currency: "KZT"},
					Labels: []string{ratingLabel, fmt.Sprintf("%d nights", nights)},
					Details: MobileSegmentDetails{Kind: "hotel", Payload: MobileHotelPayload{
						HotelID: "hotel-ber-001", Name: "Hotel Berlin Mitte", District: &district,
						Stars: &stars, Rating: &rating, RatingLabel: &ratingLabel, ReviewShortSummary: &summary,
						SelectedRoomID: &roomID, SelectedRoomName: &roomName,
						PricePerNight: MobileMoney{Amount: priceNight, Currency: "KZT"}, Nights: nights,
						Reason: "Central Mitte location with great public transport access.",
					}},
				},
				{
					SegmentID: "seg-departure-ber", Type: "departure", Title: "Return to Almaty",
					Date: t.EndDate, DayNumber: nights, StartTime: strPtr("16:00"),
					Icon: "airplane.departure", Status: "planned",
					LinkedMarkerIDs: []string{"marker-ber-airport"}, LinkedRouteIDs: []string{},
					Price: &MobileMoney{Amount: 420000, Currency: "KZT"},
					Labels: []string{"1 stop", "Economy"},
					Details: MobileSegmentDetails{Kind: "departure", Payload: MobileDeparturePayload{
						Flight: MobileFlightInfo{
							FromAirport: "BER", ToAirport: "ALA", Airline: &airline, FlightNumber: strPtr("LH7831"),
							DepartureTime: t.EndDate + "T16:00:00", ArrivalTime: t.EndDate + "T23:55:00",
							DurationMinutes: 600, Stops: 1, CabinClass: "economy",
						},
						CheckoutTime: strPtr("12:00"),
					}},
				},
			}
		},
	}
}

// ─── Japan / Tokyo ─────────────────────────────────────────────────────────

func japanConfig(city, origin string, trip *Trip) destConfig {
	arrivalSegID := "seg-arrival-nrt"
	hotelSegID := "seg-hotel-tky"

	return destConfig{
		subtitle:    "Visa-free · Direct or 1-stop flight · Cherry blossom season",
		weather:     "Pleasant, 18–26°C in spring. Occasional light rain.",
		visaStatus:  "visa_free",
		mainLabels:  []string{"Visa-free", "Spring season", "Top food scene", "Efficient transport"},
		baseCost:    1_200_000,
		cashbackPct: 3.0,
		warnings: []MobileWarning{
			{Type: "low_confidence_price", Severity: "low", Message: "Cherry blossom season is popular — book hotels early."},
		},
		routeNavigator: []MobileRouteStop{
			{StopID: "stop-tky", Title: "Tokyo", StartDate: trip.StartDate, EndDate: trip.EndDate,
				Coordinates: &MobileCoords{Lat: 35.6762, Lng: 139.6503}},
		},
		tripMap: MobileTripMap{
			InitialCamera: MobileMapCamera{CenterLat: 35.6762, CenterLng: 139.6503, Zoom: 11},
			Markers: []MobileMarker{
				{MarkerID: "marker-nrt-airport", SegmentID: &arrivalSegID, Type: "airport", Title: "Narita International Airport", Lat: 35.7720, Lng: 140.3929},
				{MarkerID: "marker-tky-hotel", SegmentID: &hotelSegID, Type: "hotel", Title: "Shinjuku Hotel", Lat: 35.6896, Lng: 139.6917},
			},
			Routes: []MobileRoute{},
		},
		segments: func(t *Trip, nights int) []MobileSegment {
			airline := "Japan Airlines"
			fn := "JL721"
			priceNight := 130_000.0
			district := "Shinjuku"
			stars := 4
			rating := 8.9
			ratingLabel := "8.9 Excellent"
			summary := "Excellent location, spotlessly clean, friendly staff."
			roomID := "room-tky-std"
			roomName := "Standard Room"
			return []MobileSegment{
				{
					SegmentID: arrivalSegID, Type: "arrival", Title: "Arrival in Tokyo",
					Date: t.StartDate, DayNumber: 1, StartTime: strPtr("15:30"),
					Icon: "airplane.arrival", Status: "planned",
					LinkedMarkerIDs: []string{"marker-nrt-airport"}, LinkedRouteIDs: []string{},
					Price: &MobileMoney{Amount: 480000, Currency: "KZT"},
					Labels: []string{"1 stop", "Economy"},
					Details: MobileSegmentDetails{Kind: "arrival", Payload: MobileArrivalPayload{
						Flight: MobileFlightInfo{
							FromAirport: "ALA", ToAirport: "NRT", Airline: &airline, FlightNumber: &fn,
							DepartureTime: t.StartDate + "T02:00:00", ArrivalTime: t.StartDate + "T15:30:00",
							DurationMinutes: 570, Stops: 1, CabinClass: "economy",
							Price: &MobileMoney{Amount: 480000, Currency: "KZT"},
						},
					}},
				},
				{
					SegmentID: hotelSegID, Type: "hotel_stay", Title: "Check-in: Shinjuku Hotel",
					Date: t.StartDate, DayNumber: 1, Icon: "bed.double.fill", Status: "selected",
					LinkedMarkerIDs: []string{"marker-tky-hotel"}, LinkedRouteIDs: []string{},
					Price: &MobileMoney{Amount: priceNight * float64(nights), Currency: "KZT"},
					Labels: []string{ratingLabel, fmt.Sprintf("%d nights", nights)},
					Details: MobileSegmentDetails{Kind: "hotel", Payload: MobileHotelPayload{
						HotelID: "hotel-tky-001", Name: "Shinjuku Hotel", District: &district,
						Stars: &stars, Rating: &rating, RatingLabel: &ratingLabel, ReviewShortSummary: &summary,
						SelectedRoomID: &roomID, SelectedRoomName: &roomName,
						PricePerNight: MobileMoney{Amount: priceNight, Currency: "KZT"}, Nights: nights,
						Reason: "Best access to Shinjuku, Harajuku, and Shibuya.",
					}},
				},
				{
					SegmentID: "seg-departure-nrt", Type: "departure", Title: "Return to Almaty",
					Date: t.EndDate, DayNumber: nights, StartTime: strPtr("17:00"),
					Icon: "airplane.departure", Status: "planned",
					LinkedMarkerIDs: []string{"marker-nrt-airport"}, LinkedRouteIDs: []string{},
					Price: &MobileMoney{Amount: 480000, Currency: "KZT"},
					Labels: []string{"1 stop", "Economy"},
					Details: MobileSegmentDetails{Kind: "departure", Payload: MobileDeparturePayload{
						Flight: MobileFlightInfo{
							FromAirport: "NRT", ToAirport: "ALA", Airline: &airline, FlightNumber: strPtr("JL722"),
							DepartureTime: t.EndDate + "T17:00:00", ArrivalTime: t.EndDate + "T23:55:00",
							DurationMinutes: 570, Stops: 1, CabinClass: "economy",
						},
						CheckoutTime: strPtr("11:00"),
					}},
				},
			}
		},
	}
}
