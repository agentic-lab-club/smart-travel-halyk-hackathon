import Foundation

struct MapMarker: Codable, Equatable, Identifiable {
    var id: String { markerId }

    let markerId: String
    let segmentId: String?
    let type: MarkerType
    let title: String
    let subtitle: String?
    let lat: Double
    let lng: Double
    let icon: String?
    let price: MoneyWithUnit?
    let labels: [String]?
}
