import Foundation

struct PlaceActivity: Codable, Equatable, Identifiable {
    enum PlaceType: String, Codable, CaseIterable {
        case attraction
        case event
        case restaurant
        case shopping
        case viewpoint
    }

    var id: String { placeId }

    let placeId: String
    let city: String
    let title: String
    let type: PlaceType
    let lat: Double
    let lng: Double
    let durationMinutes: Int
    let estimatedPrice: Double?
    let currency: CurrencyCode?
    let tags: [String]
    let rating: Double?
}
