import SwiftUI

struct FeedSegmentChip: View {
    let segment: RecommendationFeedSegment
    let count: Int
    let isSelected: Bool

    var body: some View {
        Label {
            HStack {
                Text("\(self.segment.title) ")
                Text("\(self.count)")
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: self.segment.systemImage)
        }
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .foregroundStyle(isSelected ? .white : .primary)
        .glassEffect(
            .clear
                .interactive()
                .tint(isSelected ? Color.green : Color(.secondarySystemGroupedBackground))
        )
    }
}
