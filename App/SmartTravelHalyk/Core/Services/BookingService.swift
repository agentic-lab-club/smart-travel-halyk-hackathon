import Foundation
import Observation

@MainActor
@Observable
final class BookingService {

    private(set) var bookedTrips: [BookedTrip] = []

    var upcomingTrips: [BookedTrip] { bookedTrips.filter(\.isUpcoming).sorted { lhsDate($0) < lhsDate($1) } }
    var pastTrips:     [BookedTrip] { bookedTrips.filter(\.isPast).sorted    { lhsDate($0) > lhsDate($1) } }

    // MARK: Aggregate stats

    var totalTripsCount: Int  { bookedTrips.count }
    var totalCashback: Double { bookedTrips.reduce(0) { $0 + $1.cashbackEarned.amount } }
    var totalSpent: Double    { bookedTrips.reduce(0) { $0 + $1.totalPaid.amount } }

    var countriesVisited: [String] {
        var seen: Set<String> = []
        return pastTrips.compactMap { trip -> String? in
            let city = trip.trip.title
            guard !seen.contains(city) else { return nil }
            seen.insert(city)
            return city
        }
    }

    // MARK: - Lifecycle

    func load() {
        bookedTrips = persisted() + MockBookingHistory.seedTrips
    }

    // MARK: - Book

    @discardableResult
    func book(
        trip: TripDetailsResponse,
        addOnIds: [String],
        allAddOns: [TripAddOn],
        total: Money,
        cashback: Money
    ) -> BookedTrip {
        let ref = "HTK-\(Int.random(in: 100_000...999_999))"
        let passes = makeBoardingPasses(trip: trip, ref: ref)
        let hotel  = makeHotelConfirmation(trip: trip, ref: ref)

        let booked = BookedTrip(
            id: ref,
            trip: trip,
            addOnIds: addOnIds,
            totalPaid: total,
            cashbackEarned: cashback,
            bookedAt: Date(),
            boardingPasses: passes,
            hotelConfirmation: hotel
        )
        bookedTrips.insert(booked, at: 0)
        persist()
        return booked
    }

    // MARK: - Boarding pass generation

    private func makeBoardingPasses(trip: TripDetailsResponse, ref: String) -> [BoardingPassInfo] {
        var passes: [BoardingPassInfo] = []
        let passenger = "Artem Bagin"
        let gates = ["A2","A4","B7","B12","C1","C3","D6","E9"]
        let seatLetters = ["A","B","C","D","F"]

        for seg in trip.segments {
            switch seg.details {
            case .arrival(let d):
                let f = d.flight
                passes.append(BoardingPassInfo(
                    id: "\(ref)-1",
                    direction: "Outbound",
                    passengerName: passenger,
                    bookingRef: ref,
                    airline: f.airline ?? "Air Astana",
                    flightNumber: f.flightNumber ?? "KC721",
                    fromAirport: f.fromAirport,
                    fromCity: cityName(for: f.fromAirport),
                    toAirport: f.toAirport,
                    toCity: cityName(for: f.toAirport),
                    departureTime: f.departureTime,
                    arrivalTime: f.arrivalTime,
                    gate: gates.randomElement()!,
                    seat: "\(Int.random(in: 8...34))\(seatLetters.randomElement()!)",
                    cabinClass: f.cabinClass,
                    durationMinutes: f.durationMinutes
                ))
            case .departure(let d):
                let f = d.flight
                passes.append(BoardingPassInfo(
                    id: "\(ref)-2",
                    direction: "Return",
                    passengerName: passenger,
                    bookingRef: ref,
                    airline: f.airline ?? "Air Astana",
                    flightNumber: f.flightNumber ?? "KC722",
                    fromAirport: f.fromAirport,
                    fromCity: cityName(for: f.fromAirport),
                    toAirport: f.toAirport,
                    toCity: cityName(for: f.toAirport),
                    departureTime: f.departureTime,
                    arrivalTime: f.arrivalTime,
                    gate: gates.randomElement()!,
                    seat: "\(Int.random(in: 8...34))\(seatLetters.randomElement()!)",
                    cabinClass: f.cabinClass,
                    durationMinutes: f.durationMinutes
                ))
            default:
                break
            }
        }
        return passes
    }

    private func makeHotelConfirmation(trip: TripDetailsResponse, ref: String) -> HotelConfirmationInfo? {
        for seg in trip.segments {
            if case .hotel(let h) = seg.details {
                return HotelConfirmationInfo(
                    confirmationNumber: "HB-\(Int.random(in: 10_000...99_999))",
                    passengerName: "Artem Bagin",
                    hotelName: h.name,
                    stars: h.stars ?? 4,
                    checkIn: trip.startDate,
                    checkOut: trip.endDate,
                    nights: h.nights,
                    roomType: h.selectedRoomName ?? "Superior Room",
                    address: h.district.map { "\($0), \(trip.title)" } ?? trip.title
                )
            }
        }
        return nil
    }

    private func cityName(for code: String) -> String {
        let map: [String: String] = [
            "ALA": "Almaty", "NQZ": "Astana", "DXB": "Dubai",
            "IST": "Istanbul", "BKK": "Bangkok", "LHR": "London",
            "CDG": "Paris", "FCO": "Rome", "JFK": "New York",
            "GRU": "São Paulo", "SIN": "Singapore", "HKG": "Hong Kong",
            "TBS": "Tbilisi", "TSE": "Astana", "LED": "St. Petersburg",
            "SVO": "Moscow", "VKO": "Moscow", "AYT": "Antalya",
            "SAW": "Istanbul", "BCN": "Barcelona", "MAD": "Madrid"
        ]
        return map[code] ?? code
    }

    // MARK: - Persistence

    private let storageKey = "halyk.bookedTrips"

    private func persist() {
        guard let data = try? JSONEncoder().encode(bookedTrips) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func persisted() -> [BookedTrip] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let trips = try? JSONDecoder().decode([BookedTrip].self, from: data) else { return [] }
        return trips
    }

    private func lhsDate(_ b: BookedTrip) -> Date {
        b.trip.startDate.asDate ?? Date.distantPast
    }
}

// MARK: - Seed history

private enum MockBookingHistory {
    static var seedTrips: [BookedTrip] {
        guard !UserDefaults.standard.bool(forKey: "halyk.seedApplied") else { return [] }
        UserDefaults.standard.set(true, forKey: "halyk.seedApplied")
        return [dubaiTrip, istanbulTrip]
    }

    private static var dubaiTrip: BookedTrip {
        BookedTrip(
            id: "HTK-391042",
            trip: pastTripStub(
                id: "past-dxb",
                title: "Dubai",
                subtitle: "5 nights · luxury desert escape",
                start: "2025-01-12",
                end: "2025-01-17",
                days: 5
            ),
            addOnIds: ["ins_premium", "taxi_arrival", "taxi_departure"],
            totalPaid: Money(amount: 485_000, currency: .kzt),
            cashbackEarned: Money(amount: 14_550, currency: .kzt),
            bookedAt: Date(timeIntervalSinceNow: -60 * 60 * 24 * 145),
            boardingPasses: [
                BoardingPassInfo(
                    id: "HTK-391042-1", direction: "Outbound",
                    passengerName: "Artem Bagin", bookingRef: "HTK-391042",
                    airline: "flydubai", flightNumber: "FZ711",
                    fromAirport: "ALA", fromCity: "Almaty",
                    toAirport: "DXB", toCity: "Dubai",
                    departureTime: "2025-01-12T06:30:00",
                    arrivalTime: "2025-01-12T09:10:00",
                    gate: "C3", seat: "14A",
                    cabinClass: .business, durationMinutes: 280
                ),
                BoardingPassInfo(
                    id: "HTK-391042-2", direction: "Return",
                    passengerName: "Artem Bagin", bookingRef: "HTK-391042",
                    airline: "flydubai", flightNumber: "FZ712",
                    fromAirport: "DXB", fromCity: "Dubai",
                    toAirport: "ALA", toCity: "Almaty",
                    departureTime: "2025-01-17T21:45:00",
                    arrivalTime: "2025-01-18T04:20:00",
                    gate: "B7", seat: "22C",
                    cabinClass: .economy, durationMinutes: 275
                )
            ],
            hotelConfirmation: HotelConfirmationInfo(
                confirmationNumber: "HB-73921",
                passengerName: "Artem Bagin",
                hotelName: "Address Downtown Dubai",
                stars: 5,
                checkIn: "2025-01-12",
                checkOut: "2025-01-17",
                nights: 5,
                roomType: "Deluxe Room with Burj Khalifa View",
                address: "Downtown Dubai, Sheikh Mohammed bin Rashid Blvd"
            )
        )
    }

    private static var istanbulTrip: BookedTrip {
        BookedTrip(
            id: "HTK-204817",
            trip: pastTripStub(
                id: "past-ist",
                title: "Istanbul",
                subtitle: "4 nights · culture & gastronomy",
                start: "2025-03-20",
                end: "2025-03-24",
                days: 4
            ),
            addOnIds: ["ins_basic", "esim"],
            totalPaid: Money(amount: 320_000, currency: .kzt),
            cashbackEarned: Money(amount: 9_600, currency: .kzt),
            bookedAt: Date(timeIntervalSinceNow: -60 * 60 * 24 * 70),
            boardingPasses: [
                BoardingPassInfo(
                    id: "HTK-204817-1", direction: "Outbound",
                    passengerName: "Artem Bagin", bookingRef: "HTK-204817",
                    airline: "Turkish Airlines", flightNumber: "TK362",
                    fromAirport: "ALA", fromCity: "Almaty",
                    toAirport: "IST", toCity: "Istanbul",
                    departureTime: "2025-03-20T03:15:00",
                    arrivalTime: "2025-03-20T07:40:00",
                    gate: "A4", seat: "31F",
                    cabinClass: .economy, durationMinutes: 385
                )
            ],
            hotelConfirmation: HotelConfirmationInfo(
                confirmationNumber: "HB-48203",
                passengerName: "Artem Bagin",
                hotelName: "Pera Palace Hotel",
                stars: 5,
                checkIn: "2025-03-20",
                checkOut: "2025-03-24",
                nights: 4,
                roomType: "Orient Express Room",
                address: "Meşrutiyet Cd. No:52, Tepebaşı, Beyoğlu"
            )
        )
    }

    private static func pastTripStub(
        id: String, title: String, subtitle: String,
        start: String, end: String, days: Int
    ) -> TripDetailsResponse {
        MockTravelData.tripDetails.withOverride(id: id, title: title, subtitle: subtitle, start: start, end: end, days: days)
    }
}

// Quick helper to produce a modified TripDetailsResponse for seed data
private extension TripDetailsResponse {
    func withOverride(id: String, title: String, subtitle: String, start: String, end: String, days: Int) -> TripDetailsResponse {
        TripDetailsResponse(
            tripId: id, title: title, subtitle: subtitle,
            startDate: start, endDate: end, durationDays: days,
            peopleCount: self.peopleCount, currency: self.currency,
            selectedMode: self.selectedMode, availableModes: self.availableModes,
            summary: self.summary, routeNavigator: self.routeNavigator,
            map: self.map, segments: self.segments, budget: self.budget,
            modeVariants: self.modeVariants, visa: self.visa,
            cashback: self.cashback, challenges: self.challenges,
            warnings: self.warnings
        )
    }
}
