import Foundation

struct HotelReviewSummary: Codable, Equatable {
    let shortSummary: String
    let positivePoints: [String]
    let negativePoints: [String]
    let bestFor: [String]
    let notIdealFor: [String]
    let confidence: Confidence
    let basedOnSources: [String]
}
