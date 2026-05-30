import Foundation

struct EstimatedMoney: Codable, Equatable {
    let amount: Double
    let currency: CurrencyCode
    let confidence: Confidence
}
