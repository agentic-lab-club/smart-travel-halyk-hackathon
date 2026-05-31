import SwiftUI

struct BookTripFooter: View {
    let totalCost: Money
    let onBook: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total estimate")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(totalCost.displayString)
                        .font(.headline.bold())
                        .contentTransition(.numericText())
                        .animation(.smooth(duration: 0.3), value: totalCost.amount)
                }

                Spacer()

                Button(action: onBook) {
                    Label("Book Trip", systemImage: "bolt.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 13)
                        .background(
                            Capsule()
                                .fill(Color.green)
                                .shadow(color: .green.opacity(0.35), radius: 10, y: 4)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemGroupedBackground))
        }
    }
}
