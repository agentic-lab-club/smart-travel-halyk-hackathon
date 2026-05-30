import Foundation

extension MockTravelData {
    static let hotelDetailsFull = HotelDetailsFull(
        hotelId: "hotel-galata-balance",
        name: "Galata Balance Hotel",
        city: "Istanbul",
        district: "Karakoy / Galata",
        address: "Bereketzade, Galata Tower area, Istanbul",
        lat: 41.0256,
        lng: 28.9741,
        stars: 4,
        mainImageUrl: "https://images.unsplash.com/photo-1566073771259-6a8506099945",
        rating: HotelRating(overall: 8.8, scale: 10, label: "Excellent location", reviewCount: 1842),
        sourceRatings: [
            HotelSourceRating(source: .booking, rating: 8.9, scale: 10, reviewCount: 912, url: nil),
            HotelSourceRating(source: .googleHotels, rating: 4.5, scale: 5, reviewCount: 641, url: nil),
            HotelSourceRating(source: .tripadvisor, rating: 4.4, scale: 5, reviewCount: 289, url: nil)
        ],
        reviewSummary: HotelReviewSummary(
            shortSummary: "Guests like the walkable Galata location, clean rooms, and rooftop breakfast. Some rooms are compact.",
            positivePoints: ["Walkable to tram and ferry", "Strong breakfast view", "Helpful staff"],
            negativePoints: ["Compact standard rooms", "Street noise on lower floors"],
            bestFor: ["First Istanbul trip", "Couples", "Walkable itinerary"],
            notIdealFor: ["Large families", "Travelers needing quiet suburban stays"],
            confidence: .high,
            basedOnSources: ["Booking.com", "Google Hotels", "Tripadvisor"]
        ),
        reviewsBySource: [
            HotelReviewsSourceGroup(
                source: .booking,
                totalReviews: 912,
                averageRating: 8.9,
                scale: 10,
                reviews: [
                    HotelReview(
                        reviewId: "review-booking-001",
                        authorName: "Aigerim",
                        rating: 9.2,
                        scale: 10,
                        date: "2026-04-18",
                        language: "ru",
                        title: "Great base for the first visit",
                        text: "We walked to Galata, Karakoy and the ferry. Breakfast view was the best part.",
                        pros: ["Location", "Breakfast", "Clean room"],
                        cons: ["Room was small"]
                    )
                ]
            ),
            HotelReviewsSourceGroup(
                source: .googleHotels,
                totalReviews: 641,
                averageRating: 4.5,
                scale: 5,
                reviews: [
                    HotelReview(
                        reviewId: "review-google-001",
                        authorName: "Murat",
                        rating: 4.6,
                        scale: 5,
                        date: "2026-03-02",
                        language: "en",
                        title: "Central and practical",
                        text: "Good value for Karakoy. Staff helped with airport transfer timing.",
                        pros: ["Staff", "Transport access"],
                        cons: ["Elevator can be busy"]
                    ),
                    HotelReview(
                        reviewId: "review-google-002",
                        authorName: "Damir",
                        rating: 4.3,
                        scale: 5,
                        date: "2026-02-14",
                        language: "ru",
                        title: "Great rooftop",
                        text: "Breakfast on the rooftop with Galata Tower view is absolutely worth it. Room was cosy if small.",
                        pros: ["Rooftop breakfast", "View"],
                        cons: ["Small room", "No elevator to top floor"]
                    )
                ]
            ),
            HotelReviewsSourceGroup(
                source: .tripadvisor,
                totalReviews: 289,
                averageRating: 4.4,
                scale: 5,
                reviews: [
                    HotelReview(
                        reviewId: "review-ta-001",
                        authorName: "Sophia",
                        rating: 4.5,
                        scale: 5,
                        date: "2026-01-22",
                        language: "en",
                        title: "Lovely boutique feel",
                        text: "Charming hotel with attentive staff and a perfect Galata location. Great for exploring on foot.",
                        pros: ["Location", "Staff", "Atmosphere"],
                        cons: ["Wi-Fi spotty on lower floors"]
                    )
                ]
            )
        ],
        rooms: hotelRooms,
        selectedRoomId: "room-comfort-queen",
        roomOptions: HotelRoomOptions(
            selectedRoomId: "room-comfort-queen",
            downgradeRoomId: "room-economy-double",
            upgradeRoomId: "room-bosphorus-view",
            selectedReason: "Best balance of room size, breakfast, and central location.",
            downgradeLabel: "Save 48 000 KZT with a smaller room",
            upgradeLabel: "Add Bosphorus view for 86 000 KZT"
        ),
        locationInfo: HotelLocationInfo(
            distanceToAirportKm: 39.5,
            taxiFromAirport: Money(amount: 19_000, currency: .kzt),
            distanceToMainClusterKm: 1.2,
            distanceToBeachKm: 0.35,
            averageTaxiToActivities: Money(amount: 2_800, currency: .kzt),
            walkablePlacesCount: 9,
            locationScore: 9.1,
            priceScore: 8.4,
            convenienceScore: 8.8
        ),
        reason: "Central enough to reduce taxi spend while staying below comfort-mode hotel pricing."
    )
}
