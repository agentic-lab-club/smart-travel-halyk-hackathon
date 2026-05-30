import Foundation

struct FlightInfo: Codable, Equatable {
    enum CabinClass: String, Codable, CaseIterable {
        case economy
        case business
        case first
    }

    let fromAirport: String
    let toAirport: String
    let airline: String?
    let flightNumber: String?
    let departureTime: String
    let arrivalTime: String
    let durationMinutes: Int
    let stops: Int
    let cabinClass: CabinClass
    let price: Money?
}
