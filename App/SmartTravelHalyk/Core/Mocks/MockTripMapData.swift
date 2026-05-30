import Foundation

extension MockTravelData {
    static let tripMap = TripMap(
        initialCamera: MapCamera(centerLat: 41.033, centerLng: 28.985, zoom: 11.5),
        markers: [
            MapMarker(
                markerId: "marker-ist-airport",
                segmentId: "segment-arrival",
                type: .airport,
                title: "Istanbul Airport",
                subtitle: "Arrival from Almaty",
                lat: 41.2753,
                lng: 28.7519,
                icon: "airplane.arrival",
                price: nil,
                labels: ["Arrival"]
            ),
            MapMarker(
                markerId: "marker-galata-hotel",
                segmentId: "segment-hotel",
                type: .hotel,
                title: "Galata Balance Hotel",
                subtitle: "Balanced location and price",
                lat: 41.0256,
                lng: 28.9741,
                icon: "bed.double.fill",
                price: MoneyWithUnit(amount: 68_000, currency: .kzt, unit: .night),
                labels: ["8.8 rating", "Central"]
            ),
            MapMarker(
                markerId: "marker-spice-bazaar",
                segmentId: "segment-day-2",
                type: .attraction,
                title: "Spice Bazaar",
                subtitle: "Food walk",
                lat: 41.0165,
                lng: 28.9705,
                icon: "fork.knife",
                price: MoneyWithUnit(amount: 12_000, currency: .kzt, unit: .person),
                labels: ["Food", "Indoor"]
            ),
            MapMarker(
                markerId: "marker-bosphorus",
                segmentId: "segment-day-2",
                type: .event,
                title: "Bosphorus dinner cruise",
                subtitle: "Evening event",
                lat: 41.0409,
                lng: 29.0053,
                icon: "ferry.fill",
                price: MoneyWithUnit(amount: 39_000, currency: .kzt, unit: .person),
                labels: ["Dinner", "Sea"]
            )
        ],
        routes: [
            MapRoute(
                routeId: "route-airport-hotel",
                fromMarkerId: "marker-ist-airport",
                toMarkerId: "marker-galata-hotel",
                segmentId: "segment-transfer",
                transportType: .shuttle,
                distanceKm: 39.5,
                durationMinutes: 55,
                estimatedCost: Money(amount: 12_000, currency: .kzt),
                polyline: nil,
                alternativeRoutes: [
                    AlternativeRoute(
                        transportType: .taxi,
                        durationMinutes: 45,
                        estimatedCost: Money(amount: 19_000, currency: .kzt),
                        reason: "Faster, but less predictable in evening traffic."
                    ),
                    AlternativeRoute(
                        transportType: .publicTransport,
                        durationMinutes: 82,
                        estimatedCost: Money(amount: 1_100, currency: .kzt),
                        reason: "Cheapest, but requires one transfer with bags."
                    )
                ]
            ),
            MapRoute(
                routeId: "route-hotel-bazaar",
                fromMarkerId: "marker-galata-hotel",
                toMarkerId: "marker-spice-bazaar",
                segmentId: "segment-day-2",
                transportType: .publicTransport,
                distanceKm: 2.4,
                durationMinutes: 18,
                estimatedCost: Money(amount: 650, currency: .kzt),
                polyline: nil,
                alternativeRoutes: nil
            )
        ]
    )
}
