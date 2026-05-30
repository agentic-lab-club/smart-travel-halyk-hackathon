import Foundation

struct TripRecommendation: Codable, Equatable, Identifiable {
    var id: String { tripId }

    let tripId: String
    let destinationTitle: String
    let countryCode: String
    let cityCodes: [String]
    let startDate: String?
    let endDate: String?
    let durationDays: Int
    let imageUrl: String?
    let estimatedTotalCost: EstimatedMoney
    let cashbackEstimate: CashbackEstimate?
    let mainReason: String
    let reasonLabels: [String]
    let recommendationType: RecommendationType
    let score: Double
}
