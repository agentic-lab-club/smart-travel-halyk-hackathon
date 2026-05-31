import SwiftUI

struct FlightTimingRoute: View {
    let plan: FlightPlan

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                FlightTimeBlock(
                    airport: plan.flight.fromAirport,
                    time: FlightDisplay.time(plan.flight.departureTime),
                    date: FlightDisplay.shortDate(plan.flight.departureTime),
                    alignment: .leading
                )

                VStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(Color(.separator))
                            .frame(height: 1)
                        Image(systemName: "airplane")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                        Rectangle()
                            .fill(Color(.separator))
                            .frame(height: 1)
                    }
                    Text(FlightDisplay.duration(plan.flight.durationMinutes))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                FlightTimeBlock(
                    airport: plan.flight.toAirport,
                    time: FlightDisplay.time(plan.flight.arrivalTime),
                    date: FlightDisplay.shortDate(plan.flight.arrivalTime),
                    alignment: .trailing
                )
            }
        }
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}
