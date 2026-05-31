import SwiftUI

struct TimelineRow: View {
    let segment: ItinerarySegment
    let isSelected: Bool
    let isLast: Bool
    let onTap: () -> Void
    var onDelete: (() -> Void)?
    var onReplace: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            TimelineIndicator(segment: segment, isSelected: isSelected, isLast: isLast)

            if segment.type.isReplaceable {
                SwipeView {
                    SegmentCard(segment: segment, isSelected: isSelected)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 12)
                        .onTapGesture(perform: onTap)
                } trailingActions: { _ in
                    SwipeAction("Replace", systemImage: "arrow.triangle.2.circlepath", backgroundColor: .orange) {
                        onReplace?()
                    }
                    SwipeAction("Delete", systemImage: "trash", backgroundColor: .red) {
                        onDelete?()
                    }
                    .allowSwipeToTrigger()
                }
                .swipeActionCornerRadius(12)
                .swipeActionsMaskCornerRadius(12)
                .swipeActionWidth(88)
                .swipeSpacing(8)
            } else {
                SegmentCard(segment: segment, isSelected: isSelected)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 12)
                    .onTapGesture(perform: onTap)
            }
        }
    }
}
