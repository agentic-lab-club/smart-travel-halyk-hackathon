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
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(flights) { plan in
                        Text(plan.direction.shortTitle)
                            .font(.caption)
                            .foregroundStyle(.secondary.tertiary)
                            .fontDesign(.monospaced)

                        FlightAirportBadge(code: plan.flight.fromAirport, label: FlightDisplay.shortDate(plan.flight.departureTime))

                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        FlightAirportBadge(code: plan.flight.toAirport, label: FlightDisplay.shortDate(plan.flight.arrivalTime))

                        if plan.id != flights.last?.id {
                            Rectangle()
                                .fill(Color(.separator))
                                .frame(width: 1, height: 28)
                                .padding(.horizontal, 6)
                        }
                    }
                }
            }
            .padding(10)
            .frame(height: 50)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 10) {
                FlightMetricPill(title: "Duration", value: totalDuration, icon: "clock.fill")
                FlightMetricPill(title: "Stops", value: flights.allSatisfy { $0.flight.stops == 0 } ? "Direct" : "With stops", icon: "checkmark.circle.fill")
                if let totalPrice {
                    FlightMetricPill(title: "Total", value: totalPrice.displayString, icon: "creditcard.fill")
                }
            }
        }
    }
}
