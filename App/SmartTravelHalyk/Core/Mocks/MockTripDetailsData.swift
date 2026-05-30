import Foundation

extension MockTravelData {
    static let tripDetails = TripDetailsResponse(
        tripId: "trip-istanbul-001",
        title: "Istanbul food and Bosphorus weekend",
        subtitle: "5 days, visa-free, balanced comfort from Almaty",
        startDate: "2026-06-12",
        endDate: "2026-06-16",
        durationDays: 5,
        peopleCount: 2,
        currency: .kzt,
        selectedMode: .balanced,
        availableModes: TripMode.allCases,
        summary: TripSummary(
            estimatedTotalCost: Money(amount: 742_000, currency: .kzt),
            estimatedTotalCashback: Money(amount: 31_500, currency: .kzt),
            weatherSummary: "Warm, mostly sunny, 24-28 C. Light rain risk on day 3.",
            visaStatus: .visaFree,
            mainLabels: ["Visa-free", "4.2% cashback", "Central hotel", "Low transfer stress"]
        ),
        routeNavigator: routeStops,
        map: tripMap,
        segments: itinerarySegments,
        budget: budgetBreakdown,
        modeVariants: modeVariants,
        visa: visaInfo,
        cashback: cashbackInfo,
        challenges: travelChallenges,
        warnings: smartWarnings
    )
}
