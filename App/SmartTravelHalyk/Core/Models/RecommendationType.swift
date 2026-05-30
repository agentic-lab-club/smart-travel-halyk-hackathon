import Foundation

enum RecommendationType: String, Codable, CaseIterable {
    case similarToPrevious = "similar_to_previous"
    case oppositeToPrevious = "opposite_to_previous"
    case seasonal
    case eventBased = "event_based"
    case budgetFriendly = "budget_friendly"
    case cashbackBoosted = "cashback_boosted"
    case visaFree = "visa_free"
    case weekendTrip = "weekend_trip"
}
