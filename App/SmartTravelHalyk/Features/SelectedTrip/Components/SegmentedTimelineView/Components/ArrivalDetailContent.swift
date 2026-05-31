import SwiftUI

struct ArrivalDetailContent: View {
    let details: ArrivalDetails
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            DetailRow(icon: "airplane", label: "\(details.flight.fromAirport) → \(details.flight.toAirport)")
            if let airline = details.flight.airline {
                DetailRow(icon: "tag", label: "\(airline) · \(details.flight.flightNumber ?? "")")
            }
            DetailRow(icon: "clock", label: "\(details.flight.departureTime) – \(details.flight.arrivalTime) · \(details.flight.durationMinutes / 60)h \(details.flight.durationMinutes % 60)m")
            if details.flight.stops == 0 {
                DetailRow(icon: "checkmark.circle", label: "Direct flight")
            } else {
                DetailRow(icon: "arrow.triangle.branch", label: "\(details.flight.stops) stop(s)")
            }
        }.padding(.top, 4)
    }
}
