import Foundation

extension MockTravelData {

    static let planeClassOptions: [PlaneClassOption] = [
        PlaneClassOption(
            id: .economy,
            displayName: "Economy",
            pricePerAdult: Money(amount: 123_000, currency: .kzt),
            pricePerChild: Money(amount: 89_000, currency: .kzt),
            startRow: 10,
            endRow: 30,
            features: ["Standard seat (32\" pitch)", "23 kg checked baggage", "Complimentary meal", "Personal screen"]
        ),
        PlaneClassOption(
            id: .business,
            displayName: "Business",
            pricePerAdult: Money(amount: 245_000, currency: .kzt),
            pricePerChild: Money(amount: 179_000, currency: .kzt),
            startRow: 4,
            endRow: 9,
            features: ["Lie-flat seat (78\")", "32 kg checked baggage", "Premium dining", "Lounge access", "Priority boarding"]
        ),
        PlaneClassOption(
            id: .first,
            displayName: "First",
            pricePerAdult: Money(amount: 389_000, currency: .kzt),
            pricePerChild: Money(amount: 289_000, currency: .kzt),
            startRow: 1,
            endRow: 3,
            features: ["Private suite", "40 kg checked baggage", "À la carte dining", "Chauffeur service", "Spa access"]
        )
    ]

    static let planeSeatMap: [PlaneSeat] = buildSeatMap()

    private static func buildSeatMap() -> [PlaneSeat] {
        var seats: [PlaneSeat] = []
        let exitRows: Set<Int> = [10, 21]

        // First class: rows 1–3, 2+2 layout — letters A, C, D, F only
        for row in 1...3 {
            for letter in ["A", "C", "D", "F"] {
                let id = "\(row)\(letter)"
                seats.append(PlaneSeat(
                    id: id, row: row, letter: letter,
                    isOccupied: deterministicOccupied(id, threshold: 4),
                    isExitRow: false,
                    cabinClass: .first
                ))
            }
        }

        // Business: rows 4–9, 3+3 layout
        for row in 4...9 {
            for letter in ["A", "B", "C", "D", "E", "F"] {
                let id = "\(row)\(letter)"
                seats.append(PlaneSeat(
                    id: id, row: row, letter: letter,
                    isOccupied: deterministicOccupied(id, threshold: 5),
                    isExitRow: false,
                    cabinClass: .business
                ))
            }
        }

        // Economy: rows 10–30, 3+3 layout
        for row in 10...30 {
            for letter in ["A", "B", "C", "D", "E", "F"] {
                let id = "\(row)\(letter)"
                seats.append(PlaneSeat(
                    id: id, row: row, letter: letter,
                    isOccupied: deterministicOccupied(id, threshold: 7),
                    isExitRow: exitRows.contains(row),
                    cabinClass: .economy
                ))
            }
        }

        return seats
    }

    private static func deterministicOccupied(_ seatId: String, threshold: Int) -> Bool {
        let hash = seatId.unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) }
        return abs(hash) % 10 < threshold
    }
}
