import Foundation

struct IntercityMovementDetails: Codable, Equatable {
    let fromCity: String
    let toCity: String
    let transportType: TransportType
    let distanceKm: Double
    let durationMinutes: Int
    let estimatedCost: Money?
    let reason: String
}
