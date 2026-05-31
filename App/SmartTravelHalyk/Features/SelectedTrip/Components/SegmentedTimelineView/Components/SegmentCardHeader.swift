import SwiftUI

struct SegmentCardHeader: View {
    let segment: ItinerarySegment

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(segment.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Day \(segment.dayNumber)")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)

                    if let price = segment.price {
                        Text(price.displayString)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.primary)
                    }
                }
            }

            if let start = segment.startTime {
                Text(timeLabel(start: start, end: segment.endTime))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !segment.labels.isEmpty {
                LabelsFlow(labels: segment.labels)
            }
        }
    }

    private func timeLabel(start: String, end: String?) -> String {
        guard let end else { return start }
        return "\(start) – \(end)"
    }
}
