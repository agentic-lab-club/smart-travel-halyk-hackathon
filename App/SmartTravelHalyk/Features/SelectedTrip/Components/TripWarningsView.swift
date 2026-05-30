import SwiftUI

struct TripWarningsView: View {
    let warnings: [SmartWarning]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Heads up")
                .font(.subheadline.weight(.semibold))

            ForEach(warnings) { warning in
                WarningRow(warning: warning)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct WarningRow: View {
    let warning: SmartWarning

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: severityIcon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(severityColor)
                .frame(width: 16)

            Text(warning.message)
                .font(.caption)
                .foregroundStyle(.primary)
        }
    }

    private var severityIcon: String {
        switch warning.severity {
        case .low:    return "info.circle.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .high:   return "xmark.octagon.fill"
        }
    }

    private var severityColor: Color {
        switch warning.severity {
        case .low:    return .blue
        case .medium: return .orange
        case .high:   return .red
        }
    }
}
