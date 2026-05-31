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

    @State private var chatService: ClaudeChatService
    @State private var inputText = ""
    @State private var didSendOpener = false
    @Environment(\.dismiss) private var dismiss

    private var city: String { viewModel.destinationCity }

    init(viewModel: SelectedTripViewModel, mode: ChatbotMode) {
        self.viewModel = viewModel
        self.mode = mode
        _chatService = State(initialValue: ClaudeChatService(sessionId: viewModel.trip.tripId))
    }

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
            await chatService.loadHistory(opener: openerMessage)
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
                            isPlaceAdded: { place in isPlaceAlreadyAdded(place) },
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
        guard !isPlaceAlreadyAdded(place) else { return }

        let ref = viewModel.lastDaySegment
        let seg = place.toSegment(
            dayNumber: ref?.dayNumber ?? viewModel.trip.durationDays,
            date: ref?.date ?? viewModel.trip.endDate,
            city: city
        )
        viewModel.addSegment(seg)
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

    private func isPlaceAlreadyAdded(_ place: SuggestedPlace) -> Bool {
        let normalizedTitle = normalizedPlaceTitle(place.title)
        return viewModel.segments.contains { segment in
            normalizedPlaceTitle(segment.title) == normalizedTitle
        }
    }

    private func normalizedPlaceTitle(_ title: String) -> String {
        title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
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

struct ItineraryChatbotSheet_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ItineraryChatbotSheet(viewModel: .preview, mode: .addPlaces)
        }
    }
}
