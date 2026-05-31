import SwiftUI

struct IndividualReviewCard: View {
    let review: HotelReview

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(review.authorName ?? "Guest")
                    .font(.caption.weight(.semibold))
                Spacer()
                HStack(spacing: 3) {
                    Text(String(format: "%.1f", review.rating))
                        .font(.caption.weight(.bold)).foregroundStyle(.green)
                    Text("/ \(Int(review.scale))").font(.caption2).foregroundStyle(.secondary)
                }
                Text("·").foregroundStyle(.secondary)
                if let date = review.date { Text(date).font(.caption2).foregroundStyle(.secondary) }
            }
            if let title = review.title {
                Text(title).font(.caption.weight(.medium))
            }
            Text(review.text).font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let pros = review.pros, !pros.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill").font(.caption2).foregroundStyle(.green)
                    Text(pros.joined(separator: " · ")).font(.caption2).foregroundStyle(.secondary)
                }
            }
            if let cons = review.cons, !cons.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "minus.circle.fill").font(.caption2).foregroundStyle(.secondary)
                    Text(cons.joined(separator: " · ")).font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
    }
}
