import Foundation

struct MoneyWithUnit: Codable, Equatable {
    enum Unit: String, Codable, CaseIterable {
        case person
        case night
        case ride
        case day
        case total
    }

    let amount: Double
    let currency: CurrencyCode
    let unit: Unit?
}
