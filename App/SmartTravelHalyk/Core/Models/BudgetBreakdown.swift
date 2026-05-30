import Foundation

struct BudgetBreakdown: Codable, Equatable {
    let total: EstimatedMoney
    let items: [BudgetItem]
}
