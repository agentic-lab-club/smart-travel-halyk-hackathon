import SwiftUI

struct FlightDetailCard: View {
    let plan: FlightPlan
    let onSelect: () -> Void

    var body: some View {
        VStack {
            HStack {
                Rectangle()
                    .frame(height: 1)
                    
                Text(plan.direction.title)
                    .fontDesign(.monospaced)
                
                Rectangle()
                    .frame(height: 1)
            }
            .foregroundStyle(.secondary.tertiary)
            .padding(.vertical, 6)
            
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: plan.direction.icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(.green, in: Circle())
                    
                    VStack(alignment: .leading, spacing: 3) {
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
                
                Button(action: onSelect) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.grid.3x3.fill")
                            .font(.subheadline.weight(.semibold))
                        Text("Select Seats")
                            .font(.subheadline.weight(.bold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 16)
                    .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        }
    }
}

#Preview {
    let flight = FlightInfo(
        fromAirport: "PAR",
        toAirport: "IST",
        airline: "Air Halyk",
        flightNumber: "HL1234",
        departureTime: "2026-06-12T09:30:00",
        arrivalTime: "2026-06-12T12:10:00",
        durationMinutes: 160,
        stops: 0,
        cabinClass: .economy,
        price: Money(amount: 350, currency: .usd)
    )

    let segment = ItinerarySegment(
        segmentId: "segment-arrival",
        type: .arrival,
        title: "Flight to Paris",
        date: "2026-06-12",
        dayNumber: 2,
        startTime: "09:30",
        endTime: "12:10",
        icon: "airplane.arrival",
        status: .planned,
        linkedMarkerIds: [],
        linkedRouteIds: [],
        price: Money(amount: 350, currency: .usd),
        labels: ["Direct flight"],
        description: "Enjoy your flight with complimentary meals and in-flight entertainment.",
        details: .arrival(ArrivalDetails(flight: flight))
    )

    VStack {
        FlightDetailCard(
            plan: FlightPlan(
                id: segment.segmentId,
                segment: segment,
                flight: flight,
                direction: .arrival,
                checkoutTime: nil,
                recommendedLeaveHotelTime: nil
            ),
            onSelect: ({})
        )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemGroupedBackground))
}
