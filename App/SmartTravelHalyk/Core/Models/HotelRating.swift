import Foundation

struct HotelRating: Codable, Equatable {
    let overall: Double
    let scale: Double
    let label: String?
    let reviewCount: Int
}
