import Foundation

struct PlaneClassOption: Identifiable {
    let id: FlightInfo.CabinClass
    let displayName: String
    let pricePerAdult: Money
    let pricePerChild: Money
    let startRow: Int
    let endRow: Int
    let features: [String]

    func totalPrice(adults: Int, children: Int) -> Money {
        Money(
            amount: pricePerAdult.amount * Double(adults) + pricePerChild.amount * Double(children),
            currency: pricePerAdult.currency
        )
    }
}

struct PlaneSeat: Identifiable {
    let id: String
    let row: Int
    let letter: String
    let isOccupied: Bool
    let isExitRow: Bool
    let cabinClass: FlightInfo.CabinClass
}
