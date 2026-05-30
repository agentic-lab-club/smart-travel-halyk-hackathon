import Foundation

struct ModeVariant: Codable, Equatable {
    enum HotelStrategy: String, Codable, CaseIterable {
        case fartherButCheaper = "farther_but_cheaper"
        case balancedLocationPrice = "balanced_location_price"
        case closerToActivities = "closer_to_activities"
    }

    enum TransportStrategy: String, Codable, CaseIterable {
        case publicTransportFirst = "public_transport_first"
        case mixed
        case taxiAndDirectRoutes = "taxi_and_direct_routes"
    }

    let totalCost: Double
    let hotelStrategy: HotelStrategy
    let transportStrategy: TransportStrategy
    let estimatedTravelTimeMinutes: Int
    let savingsComparedToBalanced: Double?
    let extraCostComparedToBalanced: Double?
    let tradeoffLabel: String
}
