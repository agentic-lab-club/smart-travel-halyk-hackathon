import Foundation

struct CarRentalDetails: Codable, Equatable {
    enum Transmission: String, Codable, CaseIterable {
        case manual
        case automatic
    }

    let provider: String?
    let carName: String
    let carClass: String?
    let transmission: Transmission?
    let seats: Int?
    let pricePerDay: Money
    let days: Int
    let pickupLocation: String
    let dropoffLocation: String?
    let reason: String?
}
