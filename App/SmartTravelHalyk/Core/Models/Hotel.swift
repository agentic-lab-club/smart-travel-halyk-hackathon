import Foundation

struct Hotel: Codable, Equatable, Identifiable {
    enum Style: String, Codable, CaseIterable {
        case economy
        case balanced
        case comfort
    }

    var id: String { hotelId }

    let hotelId: String
    let city: String
    let name: String
    let lat: Double
    let lng: Double
    let pricePerNight: Double
    let currency: CurrencyCode
    let rating: Double?
    let stars: Int?
    let style: Style
    let district: String?
    let tags: [String]
}
