import Foundation

struct CashbackInfo: Codable, Equatable {
    let estimatedTotal: Money
    let basePercent: Double
    let boostedPercent: Double?
    let items: [CashbackItem]
}
