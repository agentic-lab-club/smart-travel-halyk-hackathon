import Foundation

extension MockTravelData {
    static let hotels: [Hotel] = [
        Hotel(
            hotelId: "hotel-galata-balance",
            city: "Istanbul",
            name: "Galata Balance Hotel",
            lat: 41.0256,
            lng: 28.9741,
            pricePerNight: 68_000,
            currency: .kzt,
            rating: 8.8,
            stars: 4,
            style: .balanced,
            district: "Karakoy / Galata",
            tags: ["central", "breakfast", "walkable"]
        ),
        Hotel(
            hotelId: "hotel-kadikoy-economy",
            city: "Istanbul",
            name: "Kadikoy Smart Stay",
            lat: 40.9903,
            lng: 29.0271,
            pricePerNight: 44_000,
            currency: .kzt,
            rating: 8.2,
            stars: 3,
            style: .economy,
            district: "Kadikoy",
            tags: ["cheaper", "ferry", "longer_transfers"]
        ),
        Hotel(
            hotelId: "hotel-sultanahmet-comfort",
            city: "Istanbul",
            name: "Sultanahmet Comfort House",
            lat: 41.0089,
            lng: 28.9797,
            pricePerNight: 92_000,
            currency: .kzt,
            rating: 9.1,
            stars: 4,
            style: .comfort,
            district: "Sultanahmet",
            tags: ["closest_to_sights", "quiet", "premium"]
        )
    ]
}
