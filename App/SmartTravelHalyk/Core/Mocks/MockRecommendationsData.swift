import Foundation

extension MockTravelData {
    static let recommendations = RecommendationsResponse(
        userId: userProfile.userId,
        generatedAt: "2026-05-30T15:20:00+05:00",
        selectedMode: .balanced,
        recommendations: [
            TripRecommendation(
                tripId: "trip-istanbul-001",
                destinationTitle: "Istanbul food and Bosphorus weekend",
                countryCode: "TR",
                cityCodes: ["IST"],
                startDate: "2026-06-12",
                endDate: "2026-06-16",
                durationDays: 5,
                imageUrl: "https://images.unsplash.com/photo-1524231757912-21f4fe3a7200",
                estimatedTotalCost: EstimatedMoney(amount: 742_000, currency: .kzt, confidence: .high),
                cashbackEstimate: CashbackEstimate(amount: 31_500, currency: .kzt, percent: 4.2),
                mainReason: "Visa-free, direct flight from Almaty, strong food and history match.",
                reasonLabels: ["Visa-free", "Direct flight", "Food match", "Cashback boost"],
                recommendationType: .cashbackBoosted,
                score: 0.94
            ),
            TripRecommendation(
                tripId: "trip-tbilisi-001",
                destinationTitle: "Tbilisi old town and wine route",
                countryCode: "GE",
                cityCodes: ["TBS", "KAKHETI"],
                startDate: "2026-06-20",
                endDate: "2026-06-24",
                durationDays: 5,
                imageUrl: "https://images.unsplash.com/photo-1565008576549-57569a49371d",
                estimatedTotalCost: EstimatedMoney(amount: 586_000, currency: .kzt, confidence: .medium),
                cashbackEstimate: CashbackEstimate(amount: 18_000, currency: .kzt, percent: 3),
                mainReason: "Short flight, familiar cuisine, and easy intercity day trips.",
                reasonLabels: ["Budget friendly", "Weekend trip", "Food", "Mountains"],
                recommendationType: .budgetFriendly,
                score: 0.87
            ),
            TripRecommendation(
                tripId: "trip-almaty-weekend-001",
                destinationTitle: "Almaty mountain reset weekend",
                countryCode: "KZ",
                cityCodes: ["ALA"],
                startDate: "2026-06-27",
                endDate: "2026-06-29",
                durationDays: 3,
                imageUrl: "https://images.unsplash.com/photo-1551632811-561732d1e306",
                estimatedTotalCost: EstimatedMoney(amount: 218_000, currency: .kzt, confidence: .high),
                cashbackEstimate: CashbackEstimate(amount: 9_800, currency: .kzt, percent: 4.5),
                mainReason: "Low planning friction, mountain air, and strong card cashback on local partners.",
                reasonLabels: ["No flight", "Mountains", "Low cost", "Weekend"],
                recommendationType: .weekendTrip,
                score: 0.82
            ),
            TripRecommendation(
                tripId: "trip-seoul-seasonal-001",
                destinationTitle: "Seoul summer shopping and street food",
                countryCode: "KR",
                cityCodes: ["SEL"],
                startDate: "2026-07-05",
                endDate: "2026-07-11",
                durationDays: 7,
                imageUrl: "https://images.unsplash.com/photo-1538485399081-7c8ed553c8f0",
                estimatedTotalCost: EstimatedMoney(amount: 1_248_000, currency: .kzt, confidence: .medium),
                cashbackEstimate: CashbackEstimate(amount: 42_000, currency: .kzt, percent: 3.4),
                mainReason: "Seasonal shopping match with food markets and direct urban transit routes.",
                reasonLabels: ["Seasonal", "Shopping", "Street food", "Transit easy"],
                recommendationType: .seasonal,
                score: 0.79
            ),
            TripRecommendation(
                tripId: "trip-dubai-comfort-001",
                destinationTitle: "Dubai comfort escape",
                countryCode: "AE",
                cityCodes: ["DXB"],
                startDate: "2026-06-18",
                endDate: "2026-06-22",
                durationDays: 5,
                imageUrl: "https://images.unsplash.com/photo-1512453979798-5ea266f8880c",
                estimatedTotalCost: EstimatedMoney(amount: 964_000, currency: .kzt, confidence: .high),
                cashbackEstimate: CashbackEstimate(amount: 36_000, currency: .kzt, percent: 3.7),
                mainReason: "Comfort mode trip with simple logistics, hotels, malls and family-friendly routes.",
                reasonLabels: ["Comfort", "Direct flight", "Shopping", "Family friendly"],
                recommendationType: .similarToPrevious,
                score: 0.76
            ),
            TripRecommendation(
                tripId: "trip-jordan-route-001",
                destinationTitle: "Jordan route: Amman, Petra and Dead Sea",
                countryCode: "JO",
                cityCodes: ["AMM", "PETRA", "DEADSEA"],
                startDate: "2026-09-10",
                endDate: "2026-09-17",
                durationDays: 8,
                imageUrl: "https://images.unsplash.com/photo-1579606032821-4e6161c81bd3",
                estimatedTotalCost: EstimatedMoney(amount: 1_126_000, currency: .kzt, confidence: .medium),
                cashbackEstimate: CashbackEstimate(amount: 28_000, currency: .kzt, percent: 2.5),
                mainReason: "Multi-city route is a strong demo for timeline, map and intercity segments.",
                reasonLabels: ["Multi-city", "Culture", "Route demo", "September"],
                recommendationType: .oppositeToPrevious,
                score: 0.73
            )
        ]
    )
}
