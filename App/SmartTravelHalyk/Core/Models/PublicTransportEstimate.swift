import Foundation

struct PublicTransportEstimate: Codable, Equatable {
    let amount: Double
    let currency: CurrencyCode
    let durationMinutes: Int
}
