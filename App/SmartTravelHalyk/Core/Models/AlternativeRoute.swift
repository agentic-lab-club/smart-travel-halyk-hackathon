import Foundation

struct AlternativeRoute: Codable, Equatable {
    let transportType: TransportType
    let durationMinutes: Int
    let estimatedCost: Money?
    let reason: String
}
