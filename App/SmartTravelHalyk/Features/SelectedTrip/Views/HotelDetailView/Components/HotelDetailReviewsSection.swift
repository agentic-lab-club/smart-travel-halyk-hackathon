import SwiftUI

struct HotelDetailReviewsSection: View {
    let full: HotelDetailsFull
    @State private var expandedSource: HotelReviewSource?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HotelSectionHeading("Guest reviews")

            VStack(alignment: .leading, spacing: 6) {
                ForEach(full.reviewSummary.positivePoints, id: \.self) { point in
                    HStack(spacing: 6) {
                        Image(systemName: "hand.thumbsup.fill").font(.caption2).foregroundStyle(.green)
                        Text(point).font(.caption)
                    }
                }
                ForEach(full.reviewSummary.negativePoints, id: \.self) { point in
                    HStack(spacing: 6) {
                        Image(systemName: "hand.thumbsdown.fill").font(.caption2).foregroundStyle(.secondary)
                        Text(point).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

            ForEach(full.reviewsBySource, id: \.source) { group in
                ReviewSourceGroup(group: group, isExpanded: expandedSource == group.source) {
                    withAnimation(.smooth(duration: 0.25)) {
                        expandedSource = expandedSource == group.source ? nil : group.source
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
