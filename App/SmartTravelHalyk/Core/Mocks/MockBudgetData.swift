import Foundation

extension MockTravelData {

    // MARK: - Balanced (default)

    static let budgetBreakdown = BudgetBreakdown(
        total: EstimatedMoney(amount: 742_000, currency: .kzt, confidence: .high),
        items: [
            BudgetItem(amount: 246_000, currency: .kzt, category: .flights,         title: "Round-trip flights for 2"),
            BudgetItem(amount: 272_000, currency: .kzt, category: .hotels,          title: "4 nights at Galata Balance Hotel"),
            BudgetItem(amount: 48_000,  currency: .kzt, category: .localTransport,  title: "Airport and city transfers"),
            BudgetItem(amount: 118_000, currency: .kzt, category: .food,            title: "Food and restaurants"),
            BudgetItem(amount: 89_500,  currency: .kzt, category: .activities,      title: "Attractions and events"),
            BudgetItem(amount: -31_500, currency: .kzt, category: .cashbackDiscount,title: "Estimated Halyk cashback"),
        ]
    )

    // MARK: - Economy  (total 624 000)

    static let budgetEconomy = BudgetBreakdown(
        total: EstimatedMoney(amount: 624_000, currency: .kzt, confidence: .medium),
        items: [
            BudgetItem(amount: 246_000, currency: .kzt, category: .flights,         title: "Round-trip flights for 2"),
            BudgetItem(amount: 200_000, currency: .kzt, category: .hotels,          title: "4 nights at budget hotel"),
            BudgetItem(amount: 22_000,  currency: .kzt, category: .localTransport,  title: "Public transport + 1 taxi"),
            BudgetItem(amount: 104_000, currency: .kzt, category: .food,            title: "Local cafes and markets"),
            BudgetItem(amount: 68_000,  currency: .kzt, category: .activities,      title: "Key attractions only"),
            BudgetItem(amount: -16_000, currency: .kzt, category: .cashbackDiscount,title: "Estimated Halyk cashback"),
        ]
    )

    // MARK: - Comfort  (total 888 000)

    static let budgetComfort = BudgetBreakdown(
        total: EstimatedMoney(amount: 888_000, currency: .kzt, confidence: .medium),
        items: [
            BudgetItem(amount: 246_000, currency: .kzt, category: .flights,         title: "Round-trip flights for 2"),
            BudgetItem(amount: 358_000, currency: .kzt, category: .hotels,          title: "4 nights Bosphorus View Room"),
            BudgetItem(amount: 68_000,  currency: .kzt, category: .localTransport,  title: "Taxi and direct routes"),
            BudgetItem(amount: 148_000, currency: .kzt, category: .food,            title: "Restaurants and experiences"),
            BudgetItem(amount: 107_000, currency: .kzt, category: .activities,      title: "Premium events and tours"),
            BudgetItem(amount: -39_000, currency: .kzt, category: .cashbackDiscount,title: "Estimated Halyk cashback"),
        ]
    )

    // MARK: - Lookup

    static func budget(for mode: TripMode) -> BudgetBreakdown {
        switch mode {
        case .economy:  return budgetEconomy
        case .balanced: return budgetBreakdown
        case .comfort:  return budgetComfort
        }
    }
}
