import SwiftUI

struct FlightRouteSummaryCard: View {
    let flights: [FlightPlan]

    private var totalPrice: Money? {
        let pricedFlights = flights.compactMap(\.flight.price)
        guard let currency = pricedFlights.first?.currency, pricedFlights.allSatisfy({ $0.currency == currency }) else {
            return nil
        }
        return Money(amount: pricedFlights.reduce(0) { $0 + $1.amount }, currency: currency)
    }

    private var totalDuration: String {
        FlightDisplay.duration(flights.reduce(0) { $0 + $1.flight.durationMinutes })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Flight plan")
                        .font(.headline)
                    Text(flights.count == 1 ? "One confirmed leg" : "Round trip with \(flights.count) legs")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "airplane.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.green)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(flights) { plan in
                        FlightAirportBadge(code: plan.flight.fromAirport, label: FlightDisplay.shortDate(plan.flight.departureTime))

                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        FlightAirportBadge(code: plan.flight.toAirport, label: FlightDisplay.shortDate(plan.flight.arrivalTime))
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 10) {
                FlightMetricPill(title: "Duration", value: totalDuration, icon: "clock.fill")
                FlightMetricPill(title: "Stops", value: flights.allSatisfy { $0.flight.stops == 0 } ? "Direct" : "With stops", icon: "checkmark.circle.fill")
                if let totalPrice {
                    FlightMetricPill(title: "Total", value: totalPrice.displayString, icon: "creditcard.fill")
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}
