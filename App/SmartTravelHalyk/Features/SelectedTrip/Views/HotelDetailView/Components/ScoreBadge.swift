import SwiftUI

struct ScoreBadge: View {
    let label: String
    let score: Double
    let scale: Double

    var body: some View {
        VStack(spacing: 3) {
            Text(String(format: "%.1f", score))
                .font(.title3.bold())
                .foregroundStyle(scoreColor)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
    }

    private var scoreColor: Color {
        score >= 8.5 ? .green : score >= 7.0 ? .orange : .red
    }
}
