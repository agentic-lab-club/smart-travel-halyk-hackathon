import SwiftUI

struct PlaceSuggestionCard: View {
    let place: SuggestedPlace
    let actionLabel: String
    let actionIcon: String
    let isAdded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: place.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.green)
                    .frame(width: 20)

                Text(place.title)
                    .font(.subheadline.weight(.semibold))
            }

            Text(place.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            Button(action: onTap) {
                Label(actionLabel, systemImage: actionIcon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isAdded ? Color.secondary.opacity(0.45) : .green, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isAdded)
        }
        .padding(12)
        .frame(maxWidth: 280, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
