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

// MARK: - Factory helpers (derive from real FlightInfo)

extension PlaneClassOption {
    /// Builds the three cabin-class options using the real booked price as the anchor.
    /// Economy is the baseline; business ≈ 2×, first ≈ 3.5×.
    static func makeOptions(for flight: FlightInfo) -> [PlaneClassOption] {
        let currency = flight.price?.currency ?? .kzt
        let bookedAmount = flight.price?.amount ?? 0

        let economyAmount: Double
        switch flight.cabinClass {
        case .economy:  economyAmount = bookedAmount
        case .business: economyAmount = bookedAmount / 2.0
        case .first:    economyAmount = bookedAmount / 3.5
        }

        func option(
            _ cls: FlightInfo.CabinClass,
            displayName: String,
            multiplier: Double,
            startRow: Int, endRow: Int,
            features: [String]
        ) -> PlaneClassOption {
            let adult = economyAmount * multiplier
            return PlaneClassOption(
                id: cls,
                displayName: displayName,
                pricePerAdult: Money(amount: adult, currency: currency),
                pricePerChild: Money(amount: adult * 0.75, currency: currency),
                startRow: startRow, endRow: endRow,
                features: features
            )
        }

        return [
            option(.economy, displayName: "Economy", multiplier: 1.0, startRow: 10, endRow: 30,
                   features: ["Standard seat (32\" pitch)", "23 kg checked baggage", "Complimentary meal", "Personal screen"]),
            option(.business, displayName: "Business", multiplier: 2.0, startRow: 4, endRow: 9,
                   features: ["Lie-flat seat (78\")", "32 kg checked baggage", "Premium dining", "Lounge access", "Priority boarding"]),
            option(.first, displayName: "First", multiplier: 3.5, startRow: 1, endRow: 3,
                   features: ["Private suite", "40 kg checked baggage", "À la carte dining", "Chauffeur service", "Spa access"]),
        ]
    }
}

extension PlaneSeat {
    /// Deterministic seat map seeded per flight so different flights show different occupancy.
    static func makeSeatMap(for flight: FlightInfo) -> [PlaneSeat] {
        let flightSeed = flight.flightNumber ?? (flight.fromAirport + flight.toAirport)
        let exitRows: Set<Int> = [10, 21]
        var seats: [PlaneSeat] = []

        func occupied(_ seatId: String, threshold: Int) -> Bool {
            let combined = flightSeed + seatId
            let hash = combined.unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) }
            return abs(hash) % 10 < threshold
        }

        for row in 1...3 {
            for letter in ["A", "C", "D", "F"] {
                let id = "\(row)\(letter)"
                seats.append(PlaneSeat(id: id, row: row, letter: letter,
                    isOccupied: occupied(id, threshold: 4), isExitRow: false, cabinClass: .first))
            }
        }
        for row in 4...9 {
            for letter in ["A", "B", "C", "D", "E", "F"] {
                let id = "\(row)\(letter)"
                seats.append(PlaneSeat(id: id, row: row, letter: letter,
                    isOccupied: occupied(id, threshold: 5), isExitRow: false, cabinClass: .business))
            }
        }
        for row in 10...30 {
            for letter in ["A", "B", "C", "D", "E", "F"] {
                let id = "\(row)\(letter)"
                seats.append(PlaneSeat(id: id, row: row, letter: letter,
                    isOccupied: occupied(id, threshold: 7), isExitRow: exitRows.contains(row), cabinClass: .economy))
            }
        }
        return seats
    }
}
