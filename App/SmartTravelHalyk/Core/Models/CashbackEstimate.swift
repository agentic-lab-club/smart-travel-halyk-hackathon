import Foundation

struct CashbackEstimate: Codable, Equatable {
    let amount: Double
    let currency: CurrencyCode
    let percent: Double
}
