import Foundation

struct HotelLocationInfo: Codable, Equatable {
    let distanceToAirportKm: Double?
    let taxiFromAirport: Money?
    let distanceToMainClusterKm: Double?
    let averageTaxiToActivities: Money?
    let walkablePlacesCount: Int?
    let locationScore: Double?
    let priceScore: Double?
    let convenienceScore: Double?
}
