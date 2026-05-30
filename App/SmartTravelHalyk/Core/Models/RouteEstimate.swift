import Foundation

struct RouteEstimate: Codable, Equatable, Identifiable {
    var id: String { "\(fromId)-\(toId)-\(transportType.rawValue)" }

    let fromId: String
    let toId: String
    let transportType: TransportType
    let distanceKm: Double
    let durationMinutes: Int
    let estimatedCost: Double?
    let currency: CurrencyCode?
}
