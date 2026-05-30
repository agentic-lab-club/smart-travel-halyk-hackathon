import Foundation

extension MockTravelData {
    static let modeVariants: [TripMode: ModeVariant] = [
        .economy: ModeVariant(
            totalCost: 624_000,
            hotelStrategy: .fartherButCheaper,
            transportStrategy: .publicTransportFirst,
            estimatedTravelTimeMinutes: 640,
            savingsComparedToBalanced: 118_000,
            extraCostComparedToBalanced: nil,
            tradeoffLabel: "Save 118 000 KZT, but add about 2 hours of transit."
        ),
        .balanced: ModeVariant(
            totalCost: 742_000,
            hotelStrategy: .balancedLocationPrice,
            transportStrategy: .mixed,
            estimatedTravelTimeMinutes: 510,
            savingsComparedToBalanced: nil,
            extraCostComparedToBalanced: nil,
            tradeoffLabel: "Best balance of central hotel, shuttle transfer and walking routes."
        ),
        .comfort: ModeVariant(
            totalCost: 888_000,
            hotelStrategy: .closerToActivities,
            transportStrategy: .taxiAndDirectRoutes,
            estimatedTravelTimeMinutes: 390,
            savingsComparedToBalanced: nil,
            extraCostComparedToBalanced: 146_000,
            tradeoffLabel: "Spend 146 000 KZT more to reduce transport time and upgrade room."
        )
    ]
}
