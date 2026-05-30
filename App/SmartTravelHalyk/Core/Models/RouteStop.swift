import Foundation

struct RouteStop: Codable, Equatable, Identifiable {
    var id: String { stopId }

    let stopId: String
    let title: String
    let startDate: String
    let endDate: String
    let transportToNext: TransportType?
    let coordinates: Coordinates?
}
