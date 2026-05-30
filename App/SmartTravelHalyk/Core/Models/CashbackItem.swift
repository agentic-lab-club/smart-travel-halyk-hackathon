import Foundation

struct CashbackItem: Codable, Equatable, Identifiable {
    enum Category: String, Codable, CaseIterable {
        case hotel
        case flight
        case transport
        case activity
        case insurance
        case other
    }

    var id: String { "\(category.rawValue)-\(condition)" }

    let category: Category
    let amount: Double
    let currency: CurrencyCode
    let condition: String
}
