import SwiftUI

struct SegmentCard: View {
    let segment: ItinerarySegment
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SegmentCardHeader(segment: segment)

            if isSelected {
                SegmentCardExpanded(segment: segment)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.green.opacity(0.6) : Color.clear, lineWidth: 1.5)
                }
        )
        .animation(.smooth(duration: 0.25), value: isSelected)
    }
}
