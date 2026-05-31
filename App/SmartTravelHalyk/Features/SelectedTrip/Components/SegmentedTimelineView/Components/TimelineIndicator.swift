import SwiftUI

struct TimelineIndicator: View {
    let segment: ItinerarySegment
    let isSelected: Bool
    let isLast: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.green : Color(.tertiarySystemGroupedBackground))
                    .frame(width: 36, height: 36)
                    .overlay {
                        Circle().stroke(isSelected ? Color.green : Color(.separator), lineWidth: 1.5)
                    }

                Image(systemName: segment.effectiveIcon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : .secondary)
            }
            .animation(.smooth(duration: 0.2), value: isSelected)

            if !isLast {
                Rectangle()
                    .fill(Color(.separator))
                    .frame(width: 1.5)
                    .frame(minHeight: 28)
            }
        }
    }
}
