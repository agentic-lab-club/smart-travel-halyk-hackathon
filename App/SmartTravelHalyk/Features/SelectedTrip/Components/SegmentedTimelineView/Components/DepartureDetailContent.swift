import SwiftUI

struct DepartureDetailContent: View {
    let details: DepartureDetails
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            DetailRow(icon: "airplane.departure", label: "\(details.flight.fromAirport) → \(details.flight.toAirport)")
            if let airline = details.flight.airline {
                DetailRow(icon: "tag", label: "\(airline) · \(details.flight.flightNumber ?? "")")
            }
            DetailRow(icon: "clock", label: "\(details.flight.departureTime) – \(details.flight.arrivalTime) · \(details.flight.durationMinutes / 60)h \(details.flight.durationMinutes % 60)m")
            if details.flight.stops == 0 {
                DetailRow(icon: "checkmark.circle", label: "Direct flight")
            } else {
                DetailRow(icon: "arrow.triangle.branch", label: "\(details.flight.stops) stop(s)")
            }
            if let checkout = details.checkoutTime {
                DetailRow(icon: "door.right.hand.open", label: "Check-out by \(checkout)")
            }
            if let leave = details.recommendedLeaveHotelTime {
                DetailRow(icon: "figure.walk", label: "Leave hotel by \(leave)")
            }
        }.padding(.top, 4)
    }
}
