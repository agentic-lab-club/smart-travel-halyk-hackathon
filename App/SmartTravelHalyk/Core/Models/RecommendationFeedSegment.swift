import Foundation

enum RecommendationFeedSegment: String, CaseIterable, Identifiable {
    case similar
    case newStyle
    case seasonal

    var id: String { rawValue }
}
