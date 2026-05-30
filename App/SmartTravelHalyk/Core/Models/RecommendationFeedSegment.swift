import Foundation

enum RecommendationFeedSegment: String, CaseIterable, Identifiable {
    case forYou
    case similar
    case newStyle
    case seasonal
    case cashback

    var id: String { rawValue }
}
