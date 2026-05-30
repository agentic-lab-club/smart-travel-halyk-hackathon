import Foundation

struct DepartureDetails: Codable, Equatable {
    let flight: FlightInfo
    let checkoutTime: String?
    let recommendedLeaveHotelTime: String?
}
