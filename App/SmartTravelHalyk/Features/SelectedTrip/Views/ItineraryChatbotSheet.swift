import SwiftUI

// MARK: - Mode

enum ChatbotMode: Identifiable {
    case addPlaces
    case replaceSegment(ItinerarySegment)

    var id: String {
        switch self {
        case .addPlaces: return "add"
        case .replaceSegment(let seg): return "replace-\(seg.segmentId)"
        }
    }

    var title: String {
        switch self {
        case .addPlaces: return "Add places to visit"
        case .replaceSegment(let seg): return "Replace: \(seg.title)"
        }
    }
}

// MARK: - Sheet

struct ItineraryChatbotSheet: View {
    let viewModel: SelectedTripViewModel
    let mode: ChatbotMode

    @State private var chatService = ClaudeChatService()
    @State private var inputText = ""
    @State private var didSendOpener = false
    @Environment(\.dismiss) private var dismiss

    private var city: String { viewModel.destinationCity }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                messageList
                inputBar
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
        .task {
            guard !didSendOpener else { return }
            didSendOpener = true
            await chatService.send(openerMessage, systemPrompt: systemPrompt)
        }
    }

    // MARK: - Subviews

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(chatService.messages) { msg in
                        MessageBubble(
                            message: msg,
                            onAddPlace: { place in addPlace(place) },
                            onReplacePlace: { place in replacePlace(with: place) },
                            isReplaceMode: isReplaceMode
                        )
                        .id(msg.id)
                    }

                    if chatService.isLoading && chatService.messages.last?.role == .assistant
                        && chatService.messages.last?.text.isEmpty == true
                    {
                        TypingIndicator()
                            .padding(.leading, 16)
                    }
                }
                .padding(16)
            }
            .onChange(of: chatService.messages.count) { _, _ in
                if let last = chatService.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !chatService.isLoading
    }

    private var inputBar: some View {
        GlassEffectContainer {
            HStack(spacing: 8) {
                TextField("Message…", text: $inputText, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                Button(action: send) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(canSend ? Color.green : Color.secondary)
                        .frame(width: 36, height: 36)
                }
                .glassEffect(in: Circle())
                .disabled(!canSend)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Actions

    private func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        Task { await chatService.send(text, systemPrompt: systemPrompt) }
    }

    private func addPlace(_ place: SuggestedPlace) {
        let ref = viewModel.lastDaySegment
        let seg = place.toSegment(
            dayNumber: ref?.dayNumber ?? viewModel.trip.durationDays,
            date: ref?.date ?? viewModel.trip.endDate,
            city: city
        )
        viewModel.addSegment(seg)
        dismiss()
    }

    private func replacePlace(with place: SuggestedPlace) {
        guard case .replaceSegment(let old) = mode else { return }
        let newSeg = place.toSegment(
            dayNumber: old.dayNumber,
            date: old.date,
            city: city,
            replacingId: old.segmentId
        )
        viewModel.replaceSegment(old.segmentId, with: newSeg)
        dismiss()
    }

    private var isReplaceMode: Bool {
        if case .replaceSegment = mode { return true }
        return false
    }

    // MARK: - Prompts

    private var openerMessage: String {
        switch mode {
        case .addPlaces:
            return "What kind of places would you like to add to your \(city) trip? (e.g. museums, hidden gems, restaurants, viewpoints)"
        case .replaceSegment(let seg):
            return "I'd like to replace \"\(seg.title)\" with something else in \(city). Can you suggest alternatives?"
        }
    }

    private var systemPrompt: String {
        let existingTitles = viewModel.segments
            .filter { $0.type.isReplaceable }
            .map { $0.title }
            .joined(separator: ", ")

        switch mode {
        case .addPlaces:
            return """
            You are a knowledgeable travel assistant helping a user discover more places to visit in \(city).
            The trip runs from \(viewModel.trip.startDate) to \(viewModel.trip.endDate).
            Already planned places: \(existingTitles.isEmpty ? "none yet" : existingTitles).
            Do not suggest places already in the itinerary.
            When you suggest specific places, append a <places> JSON block at the end of your message like this:
            <places>
            [{"title":"Place Name","description":"Short reason to visit (1-2 sentences)","icon":"star.fill","type":"attraction"}]
            </places>
            Valid types: attraction, restaurant, event, shopping, free_time.
            Valid icons: any SF Symbol name relevant to the place (e.g. binoculars.fill, fork.knife, building.columns, cart, sun.horizon).
            Suggest 1–3 places per reply. Keep your text response friendly and concise.
            """
        case .replaceSegment(let seg):
            return """
            You are a travel assistant helping a user replace "\(seg.title)" in their \(city) itinerary.
            The trip runs from \(viewModel.trip.startDate) to \(viewModel.trip.endDate).
            Other planned places: \(existingTitles.isEmpty ? "none" : existingTitles).
            When you suggest a replacement, append a <places> JSON block at the end:
            <places>
            [{"title":"Place Name","description":"Short reason (1-2 sentences)","icon":"star.fill","type":"attraction"}]
            </places>
            Valid types: attraction, restaurant, event, shopping, free_time.
            Suggest 1–3 alternatives. Keep the response concise.
            """
        }
    }
}

// MARK: - MessageBubble

private struct MessageBubble: View {
    let message: ClaudeChatService.ChatMessage
    let onAddPlace: (SuggestedPlace) -> Void
    let onReplacePlace: (SuggestedPlace) -> Void
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
                        PlaceSuggestionCard(
                            place: place,
                            actionLabel: isReplaceMode ? "Use this" : "Add to trip",
                            actionIcon: isReplaceMode ? "arrow.triangle.2.circlepath" : "plus.circle.fill"
                        ) {
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

// MARK: - PlaceSuggestionCard

private struct PlaceSuggestionCard: View {
    let place: SuggestedPlace
    let actionLabel: String
    let actionIcon: String
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
                    .background(.green, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(maxWidth: 280, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - TypingIndicator

private struct TypingIndicator: View {
    @State private var phase = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0 ..< 3, id: \.self) { i in
                Circle()
                    .fill(Color.secondary.opacity(0.5))
                    .frame(width: 6, height: 6)
                    .scaleEffect(phase == i ? 1.3 : 0.9)
                    .animation(
                        .easeInOut(duration: 0.4).repeatForever().delay(Double(i) * 0.15),
                        value: phase
                    )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .onAppear { phase = 1 }
    }
}

struct ItineraryChatbotSheet_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ItineraryChatbotSheet(viewModel: .preview, mode: .addPlaces)
        }
    }
}
