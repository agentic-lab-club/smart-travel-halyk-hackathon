import Foundation

struct TravelProfile: Codable, Equatable {
    enum TravelFrequency: String, Codable, CaseIterable {
        case low
        case medium
        case high
    }

    enum HotelPreference: String, Codable, CaseIterable {
        case cheapest
        case balancedLocationPrice = "balanced_location_price"
        case central
        case comfort
    }

    enum TransportPreference: String, Codable, CaseIterable {
        case publicTransport = "public_transport"
        case mixed
        case taxi
        case rentalCar = "rental_car"
    }

    let budgetLevel: TripMode
    let travelFrequency: TravelFrequency
    let preferredTripLengthDays: Int
    let preferredCategories: [String]
    let avoidCategories: [String]
    let hotelPreference: HotelPreference
    let transportPreference: TransportPreference
}
