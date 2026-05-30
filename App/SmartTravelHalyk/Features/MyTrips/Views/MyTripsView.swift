import SwiftUI

struct MyTripsView: View {
    @State private var viewModel: MyTripsViewModel
    @State private var selectedTrip: BookedTrip?
    @State private var showDocuments = false
    @State private var documentsTrip: BookedTrip?

    init(bookingService: BookingService) {
        _viewModel = State(initialValue: MyTripsViewModel(bookingService: bookingService))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    statsRow
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 24)

                    calendarSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)

                    upcomingSection

                    historySection
                }
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("My Trips")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(item: $documentsTrip) { trip in
            TripDocumentsView(bookedTrip: trip)
        }
    }

    // MARK: - Stats row

    private var statsRow: some View {
        HStack(spacing: 10) {
            StatCard(
                value: "\(viewModel.totalTrips)",
                label: "Trips",
                icon: "airplane.circle.fill",
                color: .green
            )
            StatCard(
                value: "\(viewModel.countriesCount)",
                label: "Destinations",
                icon: "globe",
                color: .blue
            )
            StatCard(
                value: Money(amount: viewModel.totalCashback, currency: viewModel.currency).displayString,
                label: "Cashback",
                icon: "sparkles",
                color: .orange
            )
        }
    }

    // MARK: - Calendar section

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Calendar")
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Button { viewModel.stepMonth(by: -1) } label: {
                        Image(systemName: "chevron.left")
                            .font(.caption.weight(.semibold))
                            .padding(6)
                            .background(Color(.tertiarySystemGroupedBackground), in: Circle())
                    }
                    .buttonStyle(.plain)

                    Text(viewModel.monthTitle)
                        .font(.subheadline.weight(.semibold))
                        .frame(minWidth: 110)
                        .animation(.smooth, value: viewModel.monthTitle)
                        .contentTransition(.numericText())

                    Button { viewModel.stepMonth(by: 1) } label: {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .padding(6)
                            .background(Color(.tertiarySystemGroupedBackground), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }

            TripCalendarGrid(viewModel: viewModel, onDayTap: { trip in
                documentsTrip = trip
            })
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Upcoming section

    @ViewBuilder
    private var upcomingSection: some View {
        if !viewModel.upcomingTrips.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(title: "Upcoming", badge: "\(viewModel.upcomingTrips.count)")
                    .padding(.horizontal, 20)

                ForEach(viewModel.upcomingTrips) { trip in
                    BookedTripCard(trip: trip, style: .upcoming) {
                        documentsTrip = trip
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 28)
        } else {
            VStack(spacing: 10) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 42))
                    .foregroundStyle(.secondary)
                Text("No upcoming trips")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Head to Discover to plan your next adventure")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 16)
        }
    }

    // MARK: - History section

    @ViewBuilder
    private var historySection: some View {
        if !viewModel.pastTrips.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(title: "History", badge: "\(viewModel.pastTrips.count)")
                    .padding(.horizontal, 20)

                ForEach(viewModel.pastTrips) { trip in
                    BookedTripCard(trip: trip, style: .past) {
                        documentsTrip = trip
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}

// MARK: - Stat card

private struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)

            Text(value)
                .font(.subheadline.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Calendar grid

private struct TripCalendarGrid: View {
    let viewModel: MyTripsViewModel
    let onDayTap: (BookedTrip) -> Void

    private let weekdays = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        VStack(spacing: 4) {
            // Weekday headers
            HStack(spacing: 4) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day cells
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(viewModel.calendarDays.enumerated()), id: \.offset) { _, date in
                    if let date {
                        DayCell(
                            date: date,
                            isToday: Calendar.current.isDateInToday(date),
                            isTrip: viewModel.tripDays.contains(Calendar.current.startOfDay(for: date))
                        )
                        .onTapGesture {
                            if let trip = viewModel.tripForDay(date) {
                                onDayTap(trip)
                            }
                        }
                    } else {
                        Color.clear.frame(height: 34)
                    }
                }
            }
        }
    }
}

private struct DayCell: View {
    let date: Date
    let isToday: Bool
    let isTrip: Bool

    private var dayNumber: String {
        "\(Calendar.current.component(.day, from: date))"
    }

    var body: some View {
        ZStack {
            if isTrip {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green.opacity(0.18))
            }
            if isToday {
                Circle()
                    .strokeBorder(Color.green, lineWidth: 2)
                    .padding(2)
            }

            Text(dayNumber)
                .font(.caption.weight(isToday || isTrip ? .bold : .regular))
                .foregroundStyle(isTrip ? .green : isToday ? .green : .primary)
        }
        .frame(height: 34)
    }
}

// MARK: - Booked trip card

private enum TripCardStyle { case upcoming, past }

private struct BookedTripCard: View {
    let trip: BookedTrip
    let style: TripCardStyle
    let onDocuments: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(style == .upcoming ? Color.green.opacity(0.15) : Color(.tertiarySystemGroupedBackground))
                        .frame(width: 46, height: 46)
                    Image(systemName: style == .upcoming ? "airplane.departure" : "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(style == .upcoming ? .green : .secondary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(trip.trip.title)
                            .font(.headline)
                        if style == .upcoming {
                            Text("Upcoming")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.12), in: Capsule())
                        }
                    }
                    Text(trip.trip.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text(dateRangeText)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(trip.totalPaid.displayString)
                        .font(.subheadline.weight(.bold))
                    Text("Paid")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 8) {
                Label(trip.id, systemImage: "ticket.fill")
                    .font(.caption.weight(.semibold).monospaced())
                    .foregroundStyle(.secondary)

                Spacer()

                Label(cashbackText, systemImage: "sparkles")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
            }

            if !trip.boardingPasses.isEmpty || trip.hotelConfirmation != nil {
                Button(action: onDocuments) {
                    Label("View Documents", systemImage: "doc.text.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var dateRangeText: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        let start = trip.trip.startDate.asDate.map { fmt.string(from: $0) } ?? trip.trip.startDate
        let end   = trip.trip.endDate.asDate.map   { fmt.string(from: $0) } ?? trip.trip.endDate
        return "\(start) – \(end)"
    }

    private var cashbackText: String {
        "+ \(trip.cashbackEarned.displayString)"
    }
}

// MARK: - Section label

private struct SectionLabel: View {
    let title: String
    let badge: String

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.title3.bold())
            Text(badge)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
        }
    }
}

// MARK: - Preview

#Preview {
    let service = BookingService()
    service.load()
    return MyTripsView(bookingService: service)
}
