import Foundation

extension MockTravelData {
    static let routeStops: [RouteStop] = [
        RouteStop(
            stopId: "stop-arrival",
            title: "Arrive at Istanbul Airport",
            startDate: "2026-06-12T09:30:00+03:00",
            endDate: "2026-06-12T10:15:00+03:00",
            transportToNext: .shuttle,
            coordinates: Coordinates(lat: 41.2753, lng: 28.7519)
        ),
        RouteStop(
            stopId: "stop-galata",
            title: "Check in near Galata",
            startDate: "2026-06-12T11:20:00+03:00",
            endDate: "2026-06-16T10:30:00+03:00",
            transportToNext: .walk,
            coordinates: Coordinates(lat: 41.0256, lng: 28.9741)
        ),
        RouteStop(
            stopId: "stop-food-walk",
            title: "Spice Bazaar food walk",
            startDate: "2026-06-13T11:00:00+03:00",
            endDate: "2026-06-13T12:30:00+03:00",
            transportToNext: .taxi,
            coordinates: Coordinates(lat: 41.0165, lng: 28.9705)
        )
    ]
}
