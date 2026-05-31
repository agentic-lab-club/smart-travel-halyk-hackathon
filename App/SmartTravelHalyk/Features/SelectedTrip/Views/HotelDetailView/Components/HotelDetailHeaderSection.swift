import SwiftUI

struct HotelDetailHeaderSection: View {
    let hotel: HotelDetails
    let full: HotelDetailsFull

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Overall rating")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(String(format: "%.1f", full.rating.overall))
                            .font(.largeTitle.bold())
                            .foregroundStyle(.green)
                        Text("/ \(Int(full.rating.scale))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if let label = hotel.ratingLabel {
                        Text(label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text("\(full.rating.reviewCount.formatted()) reviews")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    ForEach(full.sourceRatings, id: \.source) { r in
                        HStack(spacing: 6) {
                            Text(r.source.rawValue)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.1f", r.rating))
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.primary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(.secondarySystemGroupedBackground), in: Capsule())
                    }
                }
            }

            Text(full.reviewSummary.shortSummary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: 12) {
                ReviewTagsColumn(
                    icon: "hand.thumbsup.fill",
                    color: .green,
                    tags: full.reviewSummary.bestFor,
                    label: "Best for"
                )
                ReviewTagsColumn(
                    icon: "hand.thumbsdown.fill",
                    color: .secondary,
                    tags: full.reviewSummary.notIdealFor,
                    label: "Not ideal for"
                )
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
