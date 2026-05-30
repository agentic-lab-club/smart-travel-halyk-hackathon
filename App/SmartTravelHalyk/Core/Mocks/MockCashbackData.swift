import Foundation

extension MockTravelData {
    static let cashbackInfo = CashbackInfo(
        estimatedTotal: Money(amount: 31_500, currency: .kzt),
        basePercent: 3,
        boostedPercent: 4.5,
        items: [
            CashbackItem(category: .flight, amount: 7_400, currency: .kzt, condition: "Paid with Halyk Travel"),
            CashbackItem(category: .hotel, amount: 18_300, currency: .kzt, condition: "Hotel cashback boost challenge"),
            CashbackItem(category: .transport, amount: 1_800, currency: .kzt, condition: "Card payments during trip"),
            CashbackItem(category: .activity, amount: 4_000, currency: .kzt, condition: "Partner event booking")
        ]
    )
}
