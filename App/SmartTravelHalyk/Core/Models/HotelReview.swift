import Foundation

struct HotelReview: Codable, Equatable, Identifiable {
    var id: String { reviewId }

    let reviewId: String
    let authorName: String?
    let rating: Double
    let scale: Double
    let date: String?
    let language: String?
    let title: String?
    let text: String
    let pros: [String]?
    let cons: [String]?
}
