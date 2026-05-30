import Foundation

struct HotelReviewsSourceGroup: Codable, Equatable, Identifiable {
    var id: String { source.rawValue }

    let source: HotelReviewSource
    let totalReviews: Int
    let averageRating: Double
    let scale: Double
    let reviews: [HotelReview]
}
