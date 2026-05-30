import Foundation

extension MockTravelData {
    static let routeEstimates: [RouteEstimate] = [
        RouteEstimate(
            fromId: "marker-ist-airport",
            toId: "marker-galata-hotel",
            transportType: .shuttle,
            distanceKm: 39.5,
            durationMinutes: 55,
            estimatedCost: 12_000,
            currency: .kzt
        ),
        RouteEstimate(
            fromId: "marker-galata-hotel",
            toId: "marker-spice-bazaar",
            transportType: .publicTransport,
            distanceKm: 2.4,
            durationMinutes: 18,
            estimatedCost: 650,
            currency: .kzt
        )
    ]
}
