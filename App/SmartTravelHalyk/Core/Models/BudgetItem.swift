import Foundation

struct BudgetItem: Codable, Equatable, Identifiable {
    var id: String { "\(category.rawValue)-\(title)" }

    let amount: Double
    let currency: CurrencyCode
    let category: BudgetCategory
    let title: String
}
