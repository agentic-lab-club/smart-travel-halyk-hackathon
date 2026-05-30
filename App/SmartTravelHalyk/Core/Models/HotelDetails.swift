import Foundation

struct HotelDetails: Codable, Equatable {
    let hotelId: String
    let name: String
    let district: String?
    let stars: Int?
    let rating: Double?
    let ratingLabel: String?
    let reviewShortSummary: String?
    let selectedRoomId: String?
    let selectedRoomName: String?
    let pricePerNight: Money
    let nights: Int
    let downgradeLabel: String?
    let upgradeLabel: String?
    let distanceToMainClusterKm: Double?
    let averageTaxiToActivities: Money?
    let locationScore: Double?
    let priceScore: Double?
    let reason: String
}
