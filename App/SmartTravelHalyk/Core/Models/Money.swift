import Foundation

struct Money: Codable, Equatable {
    let amount: Double
    let currency: CurrencyCode
}
