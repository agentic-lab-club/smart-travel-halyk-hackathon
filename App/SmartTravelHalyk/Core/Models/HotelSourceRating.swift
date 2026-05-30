import Foundation

struct HotelSourceRating: Codable, Equatable, Identifiable {
    var id: String { source.rawValue }

    let source: HotelReviewSource
    let rating: Double
    let scale: Double
    let reviewCount: Int
    let url: String?
}
