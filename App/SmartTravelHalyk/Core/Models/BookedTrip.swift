import Foundation

struct BookedTrip: Codable, Identifiable {
    let id: String                          // booking reference e.g. "HTK-482910"
    let trip: TripDetailsResponse
    let addOnIds: [String]
    let totalPaid: Money
    let cashbackEarned: Money
    let bookedAt: Date

    let boardingPasses: [BoardingPassInfo]
    let hotelConfirmation: HotelConfirmationInfo?

    var isUpcoming: Bool {
        guard let start = trip.startDate.asDate else { return false }
        return start >= Calendar.current.startOfDay(for: Date())
    }

    var isPast: Bool { !isUpcoming }

    /// Date range that this trip occupies as a set of day-start Date values.
    var occupiedDays: Set<Date> {
        guard let start = trip.startDate.asDate, let end = trip.endDate.asDate else { return [] }
        var days: Set<Date> = []
        var cursor = Calendar.current.startOfDay(for: start)
        let last   = Calendar.current.startOfDay(for: end)
        while cursor <= last {
            days.insert(cursor)
            cursor = Calendar.current.date(byAdding: .day, value: 1, to: cursor)!
        }
        return days
    }
}

struct BoardingPassInfo: Codable, Identifiable {
    let id: String
    let direction: String           // "Outbound" / "Return"
    let passengerName: String
    let bookingRef: String
    let airline: String
    let flightNumber: String
    let fromAirport: String
    let fromCity: String
    let toAirport: String
    let toCity: String
    let departureTime: String       // ISO-8601
    let arrivalTime: String
    let gate: String
    let seat: String
    let cabinClass: FlightInfo.CabinClass
    let durationMinutes: Int
}

struct HotelConfirmationInfo: Codable {
    let confirmationNumber: String
    let passengerName: String
    let hotelName: String
    let stars: Int
    let checkIn: String             // ISO-8601 date
    let checkOut: String
    let nights: Int
    let roomType: String
    let address: String
}

// MARK: - String date helper

extension String {
    var asDate: Date? {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        for format in ["yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd"] {
            fmt.dateFormat = format
            if let d = fmt.date(from: self) { return d }
        }
        return nil
    }
}
