import SwiftUI

struct FlightDetailCard: View {
    let plan: FlightPlan
    let onSelect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: plan.direction.icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(.green, in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(plan.direction.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                    Text(plan.segment.title)
                        .font(.headline)
                    Text("Day \(plan.segment.dayNumber) · \(FlightDisplay.shortDate(plan.flight.departureTime))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let price = plan.flight.price {
                    Text(price.displayString)
                        .font(.subheadline.weight(.bold))
                        .multilineTextAlignment(.trailing)
                }
            }

            FlightTimingRoute(plan: plan)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                FlightInfoTile(title: "Airline", value: plan.flight.airline ?? "TBA", icon: "tag.fill")
                FlightInfoTile(title: "Flight", value: plan.flight.flightNumber ?? "TBA", icon: "number")
                FlightInfoTile(title: "Cabin", value: plan.flight.cabinClass.title, icon: "person.crop.square.fill")
                FlightInfoTile(title: "Stops", value: plan.flight.stops == 0 ? "Direct" : "\(plan.flight.stops) stop(s)", icon: "arrow.triangle.branch")
            }

            if let description = plan.segment.description {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.green)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            }

            FlightChecklist(plan: plan)

            Button(action: onSelect) {
                HStack(spacing: 8) {
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.subheadline.weight(.semibold))
                    Text("Select Seats")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.green)
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}
