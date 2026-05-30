import Foundation
import Observation

@MainActor
@Observable
final class MyTripsViewModel {
    private let bookingService: BookingService

    var displayedMonth: Date = Calendar.current.startOfMonth(for: Date())

    init(bookingService: BookingService) {
        self.bookingService = bookingService
    }

    // MARK: - Data

    var upcomingTrips: [BookedTrip] { bookingService.upcomingTrips }
    var pastTrips: [BookedTrip]     { bookingService.pastTrips }

    var totalTrips: Int       { bookingService.totalTripsCount }
    var totalCashback: Double { bookingService.totalCashback }
    var totalSpent: Double    { bookingService.totalSpent }
    var countriesCount: Int   { bookingService.countriesVisited.count }

    var currency: CurrencyCode { bookingService.bookedTrips.first?.totalPaid.currency ?? .kzt }

    // MARK: - Calendar

    /// All days occupied by any booked trip in the displayed month.
    var tripDays: Set<Date> {
        let monthStart = displayedMonth
        let monthEnd   = Calendar.current.date(byAdding: .month, value: 1, to: monthStart)!

        return bookingService.bookedTrips.reduce(into: Set<Date>()) { acc, trip in
            for day in trip.occupiedDays {
                if day >= monthStart && day < monthEnd {
                    acc.insert(day)
                }
            }
        }
    }

    var calendarDays: [Date?] {
        let cal = Calendar.current
        let firstWeekday = cal.component(.weekday, from: displayedMonth)
        let offset = (firstWeekday - cal.firstWeekday + 7) % 7
        let daysInMonth = cal.range(of: .day, in: .month, for: displayedMonth)!.count

        var days: [Date?] = Array(repeating: nil, count: offset)
        for day in 1...daysInMonth {
            days.append(cal.date(byAdding: .day, value: day - 1, to: displayedMonth)!)
        }
        // pad to complete weeks
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy"
        return f.string(from: displayedMonth)
    }

    func stepMonth(by delta: Int) {
        guard let next = Calendar.current.date(byAdding: .month, value: delta, to: displayedMonth) else { return }
        displayedMonth = next
    }

    func tripForDay(_ day: Date) -> BookedTrip? {
        let start = Calendar.current.startOfDay(for: day)
        return bookingService.bookedTrips.first { $0.occupiedDays.contains(start) }
    }
}

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps)!
    }
}
