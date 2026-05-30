import Foundation

extension MockTravelData {
    static let budgetBreakdown = BudgetBreakdown(
        total: EstimatedMoney(amount: 742_000, currency: .kzt, confidence: .high),
        items: [
            BudgetItem(amount: 246_000, currency: .kzt, category: .flights, title: "Round-trip flights for 2"),
            BudgetItem(amount: 272_000, currency: .kzt, category: .hotels, title: "4 nights at Galata Balance Hotel"),
            BudgetItem(amount: 48_000, currency: .kzt, category: .localTransport, title: "Airport and city transfers"),
            BudgetItem(amount: 118_000, currency: .kzt, category: .food, title: "Food and restaurants"),
            BudgetItem(amount: 89_500, currency: .kzt, category: .activities, title: "Attractions and events"),
            BudgetItem(amount: -31_500, currency: .kzt, category: .cashbackDiscount, title: "Estimated Halyk cashback")
        ]
    )
}
