import Foundation

struct TransferDetails: Codable, Equatable {
    let from: String
    let to: String
    let recommendedTransport: TransportType
    let distanceKm: Double
    let durationMinutes: Int
    let taxiEstimate: Money?
    let publicTransportEstimate: PublicTransportEstimate?
    let reason: String
}
