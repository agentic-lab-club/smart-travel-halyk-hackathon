import SwiftUI

struct ReviewSourceGroup: View {
    let group: HotelReviewsSourceGroup
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onToggle) {
                HStack {
                    Text(group.source.rawValue)
                        .font(.subheadline.weight(.semibold))
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f", group.averageRating))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.green)
                    Text("/ \(Int(group.scale))")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("(\(group.totalReviews))")
                        .font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                ForEach(group.reviews, id: \.reviewId) { review in
                    IndividualReviewCard(review: review)
                }
            }
        }
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}
