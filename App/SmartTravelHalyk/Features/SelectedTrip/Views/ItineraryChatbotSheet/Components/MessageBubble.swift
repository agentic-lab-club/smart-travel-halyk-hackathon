import SwiftUI

struct MessageBubble: View {
    let message: ClaudeChatService.ChatMessage
    let onAddPlace: (SuggestedPlace) -> Void
    let onReplacePlace: (SuggestedPlace) -> Void
    let isPlaceAdded: (SuggestedPlace) -> Bool
    let isReplaceMode: Bool

    var body: some View {
        VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
            if !message.text.isEmpty {
                Text(message.text)
                    .font(.subheadline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        message.role == .assistant
                            ? Color.green
                            : Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                    .foregroundStyle(message.role == .assistant ? .white : .secondary)
                    .frame(maxWidth: 280, alignment: message.role == .user ? .trailing : .leading)
                    .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
                    .multilineTextAlignment(message.role == .user ? .trailing : .leading)
            }

            if !message.places.isEmpty {
                VStack(spacing: 8) {
                    ForEach(message.places) { place in
                        let isAdded = !isReplaceMode && isPlaceAdded(place)
                        PlaceSuggestionCard(
                            place: place,
                            actionLabel: isAdded ? "Added" : (isReplaceMode ? "Use this" : "Add to trip"),
                            actionIcon: isAdded ? "checkmark.circle.fill" : (isReplaceMode ? "arrow.triangle.2.circlepath" : "plus.circle.fill"),
                            isAdded: isAdded
                        ) {
                            guard !isAdded else { return }
                            if isReplaceMode {
                                onReplacePlace(place)
                            } else {
                                onAddPlace(place)
                            }
                        }
                    }
                }
            }
        }
    }
}
