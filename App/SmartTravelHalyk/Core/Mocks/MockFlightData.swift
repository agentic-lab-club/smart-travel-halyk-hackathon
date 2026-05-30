import Foundation

extension MockTravelData {
    static let inboundFlight = FlightInfo(
        fromAirport: "ALA",
        toAirport: "IST",
        airline: "Air Astana",
        flightNumber: "KC911",
        departureTime: "2026-06-12T06:05:00+05:00",
        arrivalTime: "2026-06-12T09:30:00+03:00",
        durationMinutes: 325,
        stops: 0,
        cabinClass: .economy,
        price: Money(amount: 123_000, currency: .kzt)
    )
}
