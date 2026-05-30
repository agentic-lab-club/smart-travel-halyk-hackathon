import Foundation

struct BudgetItem: Codable, Equatable, Identifiable {
    var id: String { "\(category.rawValue)-\(title)" }

    let amount: Double
    let currency: CurrencyCode
    let category: BudgetCategory
    let title: String
}

extension BudgetItem {
    var absDisplayString: String {
        "\(Int(abs(amount)).formatted(.number.grouping(.automatic))) \(currency.rawValue)"
    }
}
