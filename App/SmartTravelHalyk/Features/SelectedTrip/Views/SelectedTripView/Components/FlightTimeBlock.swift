import SwiftUI

struct FlightTimeBlock: View {
    let airport: String
    let time: String
    let date: String
    let alignment: HorizontalAlignment

    var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(time)
                .font(.title3.weight(.bold))
                .monospacedDigit()
            Text(airport)
                .font(.caption.weight(.semibold))
            Text(date)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: 74, alignment: alignment == .leading ? .leading : .trailing)
    }
}
