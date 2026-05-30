import Foundation

extension MockTravelData {
    static let userProfile = UserProfileResponse(
        userId: "user-001",
        name: "Aigerim",
        citizenship: "KZ",
        homeCity: "Almaty",
        homeAirport: "ALA",
        currency: .kzt,
        preferredLanguage: .ru,
        travelProfile: TravelProfile(
            budgetLevel: .balanced,
            travelFrequency: .medium,
            preferredTripLengthDays: 5,
            preferredCategories: ["food", "history", "sea", "walkable"],
            avoidCategories: ["nightlife", "extreme_sports"],
            hotelPreference: .balancedLocationPrice,
            transportPreference: .mixed
        )
    )
}
