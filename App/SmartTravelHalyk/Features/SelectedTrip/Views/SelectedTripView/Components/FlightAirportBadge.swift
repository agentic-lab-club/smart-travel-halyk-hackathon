import SwiftUI

struct FlightAirportBadge: View {
    let code: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(code)
                .font(.caption.weight(.bold))
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        
    }
}
