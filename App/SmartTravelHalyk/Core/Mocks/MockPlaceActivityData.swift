import Foundation

extension MockTravelData {
    static let placeActivities: [PlaceActivity] = [
        PlaceActivity(
            placeId: "place-galata-tower",
            city: "Istanbul",
            title: "Galata Tower",
            type: .viewpoint,
            lat: 41.0256,
            lng: 28.9741,
            durationMinutes: 75,
            estimatedPrice: 8_500,
            currency: .kzt,
            tags: ["view", "history", "walkable"],
            rating: 4.6
        ),
        PlaceActivity(
            placeId: "place-spice-bazaar",
            city: "Istanbul",
            title: "Spice Bazaar food walk",
            type: .shopping,
            lat: 41.0165,
            lng: 28.9705,
            durationMinutes: 90,
            estimatedPrice: 12_000,
            currency: .kzt,
            tags: ["food", "local", "covered"],
            rating: 4.7
        ),
        PlaceActivity(
            placeId: "place-bosphorus-dinner",
            city: "Istanbul",
            title: "Bosphorus dinner cruise",
            type: .event,
            lat: 41.0409,
            lng: 29.0053,
            durationMinutes: 180,
            estimatedPrice: 39_000,
            currency: .kzt,
            tags: ["sea", "dinner", "event"],
            rating: 4.5
        )
    ]
}
