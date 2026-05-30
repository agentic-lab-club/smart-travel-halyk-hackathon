import Foundation

extension MockTravelData {
    static let itinerarySegments: [ItinerarySegment] = [
        ItinerarySegment(
            segmentId: "segment-arrival",
            type: .arrival,
            title: "Arrival in Istanbul",
            date: "2026-06-12",
            dayNumber: 1,
            startTime: "09:30",
            endTime: "10:15",
            icon: "airplane.arrival",
            status: .planned,
            linkedMarkerIds: ["marker-ist-airport"],
            linkedRouteIds: [],
            price: Money(amount: 246_000, currency: .kzt),
            labels: ["Direct flight", "Morning arrival"],
            description: "Direct flight from Almaty with enough buffer before hotel check-in.",
            details: .arrival(ArrivalDetails(flight: inboundFlight))
        ),
        ItinerarySegment(
            segmentId: "segment-transfer",
            type: .transfer,
            title: "Airport transfer to Galata",
            date: "2026-06-12",
            dayNumber: 1,
            startTime: "10:25",
            endTime: "11:20",
            icon: "bus.fill",
            status: .recommended,
            linkedMarkerIds: ["marker-ist-airport", "marker-galata-hotel"],
            linkedRouteIds: ["route-airport-hotel"],
            price: Money(amount: 12_000, currency: .kzt),
            labels: ["Lower stress", "Balanced"],
            description: "Shuttle is slower than taxi but cheaper and easier with luggage.",
            details: .transfer(TransferDetails(
                from: "Istanbul Airport",
                to: "Galata Balance Hotel",
                recommendedTransport: .shuttle,
                distanceKm: 39.5,
                durationMinutes: 55,
                taxiEstimate: Money(amount: 19_000, currency: .kzt),
                publicTransportEstimate: PublicTransportEstimate(amount: 1_100, currency: .kzt, durationMinutes: 82),
                reason: "Best balance of cost, predictability and luggage comfort."
            ))
        ),
        ItinerarySegment(
            segmentId: "segment-hotel",
            type: .hotelStay,
            title: "Stay at Galata Balance Hotel",
            date: "2026-06-12",
            dayNumber: 1,
            startTime: "14:00",
            endTime: nil,
            icon: "bed.double.fill",
            status: .selected,
            linkedMarkerIds: ["marker-galata-hotel"],
            linkedRouteIds: [],
            price: Money(amount: 272_000, currency: .kzt),
            labels: ["4 nights", "8.8 rating", "Walkable"],
            description: "Central hotel selected for lower daily transport friction.",
            details: .hotel(HotelDetails(
                hotelId: "hotel-galata-balance",
                name: "Galata Balance Hotel",
                district: "Karakoy / Galata",
                stars: 4,
                rating: 8.8,
                ratingLabel: "Excellent location",
                reviewShortSummary: "Walkable, clean, good breakfast view; standard rooms are compact.",
                selectedRoomId: "room-comfort-queen",
                selectedRoomName: "Comfort Queen Room",
                pricePerNight: Money(amount: 68_000, currency: .kzt),
                nights: 4,
                downgradeLabel: "Save 48 000 KZT",
                upgradeLabel: "Add Bosphorus view",
                distanceToMainClusterKm: 1.2,
                averageTaxiToActivities: Money(amount: 2_800, currency: .kzt),
                locationScore: 9.1,
                priceScore: 8.4,
                reason: "Balances room quality, breakfast and short rides to planned activities."
            ))
        ),
        ItinerarySegment(
            segmentId: "segment-day-2",
            type: .dayItinerary,
            title: "Food walk and Bosphorus evening",
            date: "2026-06-13",
            dayNumber: 2,
            startTime: "10:30",
            endTime: "22:30",
            icon: "map.fill",
            status: .planned,
            linkedMarkerIds: ["marker-spice-bazaar", "marker-bosphorus"],
            linkedRouteIds: ["route-hotel-bazaar"],
            price: Money(amount: 102_000, currency: .kzt),
            labels: ["Food", "Sea", "Medium pace"],
            description: "A full but manageable day with indoor backup if weather turns.",
            details: .dayItinerary(DayItineraryDetails(
                city: "Istanbul",
                experienceCount: 3,
                weather: WeatherInfo(temperatureC: 26, condition: .sunny, rainChancePercent: 18, windKph: 12),
                pace: .medium,
                overloadScore: 0.42,
                activities: [
                    ActivityItem(
                        activityId: "activity-spice-bazaar",
                        title: "Spice Bazaar food walk",
                        type: .shopping,
                        startTime: "11:00",
                        durationMinutes: 90,
                        price: Money(amount: 12_000, currency: .kzt),
                        markerId: "marker-spice-bazaar",
                        reason: "Matches food interest and works even with light rain."
                    ),
                    ActivityItem(
                        activityId: "activity-galata",
                        title: "Galata Tower viewpoint",
                        type: .attraction,
                        startTime: "15:00",
                        durationMinutes: 75,
                        price: Money(amount: 8_500, currency: .kzt),
                        markerId: "marker-galata-hotel",
                        reason: "Near the hotel, good sunset option."
                    ),
                    ActivityItem(
                        activityId: "activity-bosphorus",
                        title: "Bosphorus dinner cruise",
                        type: .event,
                        startTime: "19:30",
                        durationMinutes: 180,
                        price: Money(amount: 39_000, currency: .kzt),
                        markerId: "marker-bosphorus",
                        reason: "Strong demo moment for event-based personalization."
                    )
                ]
            ))
        ),
        ItinerarySegment(
            segmentId: "segment-cashback",
            type: .cashbackChallenge,
            title: "Unlock extra hotel cashback",
            date: "2026-06-13",
            dayNumber: 2,
            startTime: nil,
            endTime: nil,
            icon: "creditcard.fill",
            status: .optional,
            linkedMarkerIds: [],
            linkedRouteIds: [],
            price: nil,
            labels: ["+1.5% cashback", "2 payments left"],
            description: "Complete two Halyk card payments before checkout to boost hotel cashback.",
            details: .cashbackChallenge(CashbackChallengeDetails(challenge: travelChallenges[0]))
        ),
        ItinerarySegment(
            segmentId: "segment-departure",
            type: .departure,
            title: "Return flight to Almaty",
            date: "2026-06-15",
            dayNumber: 4,
            startTime: "23:45",
            endTime: "06:10+1",
            icon: "airplane.departure",
            status: .planned,
            linkedMarkerIds: ["marker-ist-airport"],
            linkedRouteIds: [],
            price: Money(amount: 123_000, currency: .kzt),
            labels: ["Direct flight", "Night flight"],
            description: "Check out before 12:00. Recommended hotel departure at 20:00.",
            details: .departure(DepartureDetails(
                flight: outboundFlight,
                checkoutTime: "12:00",
                recommendedLeaveHotelTime: "20:00"
            ))
        )
    ]
}
