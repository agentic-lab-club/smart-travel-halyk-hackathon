import Foundation

struct MapRoute: Codable, Equatable, Identifiable {
    var id: String { routeId }

    let routeId: String
    let fromMarkerId: String
    let toMarkerId: String
    let segmentId: String?
    let transportType: TransportType
    let distanceKm: Double
    let durationMinutes: Int
    let estimatedCost: Money?
    let polyline: String?
    let alternativeRoutes: [AlternativeRoute]?
}
