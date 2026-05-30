import Foundation

struct RecommendationsResponse: Codable, Equatable {
    let userId: String
    let generatedAt: String
    let selectedMode: TripMode
    let recommendations: [TripRecommendation]
}
