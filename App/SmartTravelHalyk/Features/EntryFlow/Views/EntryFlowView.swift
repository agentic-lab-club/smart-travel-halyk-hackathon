import SwiftUI

struct EntryFlowView: View {
    @Environment(EntryFlowViewModel.self) private var viewModel

    var body: some View {
        switch self.viewModel.state {
        case .idle, .loading:
            self.loadingView
        case .loaded:
            self.entryContent
        case .failed(let message):
            ContentUnavailableView(
                "Travel is unavailable",
                systemImage: "wifi.exclamationmark",
                description: Text(message)
            )
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Preparing smart trips")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var entryContent: some View {
        ScrollView {
            RecommendationFeedPager(viewModel: self.viewModel)
        }
        .contentMargins(16, for: .scrollContent)
        .safeAreaInset(edge: .bottom) {
            VStack {
                FeedSegmentBar(viewModel: self.viewModel)
                    .contentMargins(.horizontal, 16, for: .scrollContent)

                ChatbotInputCapsule(viewModel: self.viewModel)
                    .padding(.horizontal, 16)
            }
            .padding(.bottom, 10)
        }
    }
}

private struct FeedSegmentBar: View {
    @Bindable var viewModel: EntryFlowViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            GlassEffectContainer {
                HStack(spacing: 8) {
                    ForEach(self.viewModel.feedSegments) { segment in
                        Button {
                            withAnimation(.snappy) {
                                self.viewModel.selectedFeedSegment = segment
                            }
                        } label: {
                            FeedSegmentChip(
                                segment: segment,
                                count: self.viewModel.recommendations(for: segment).count,
                                isSelected: self.viewModel.selectedFeedSegment == segment
                            )
                        }
                        .buttonStyle(.plain)
                        .scrollTargetLayout()
                    }
                }
            }
        }
        .scrollTargetBehavior(.viewAligned)
    }
}

private struct FeedSegmentChip: View {
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
        .foregroundStyle(self.isSelected ? .white : .primary)
        .glassEffect(
            .clear
                .interactive()
                .tint(self.isSelected ? Color.green : Color(.secondarySystemGroupedBackground))
        )
    }
}

private struct ChatbotInputCapsule: View {
    @Bindable var viewModel: EntryFlowViewModel

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.green)

            TextField("Tell us about your trip", text: self.$viewModel.chatbotPrompt)
                .submitLabel(.send)
                .onSubmit(self.viewModel.submitChatbotPrompt)

            if !self.viewModel.chatbotPrompt.isEmpty {
                Button(action: self.viewModel.submitChatbotPrompt) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                        .foregroundStyle(.green)
                }
                .buttonStyle(.plain)
                .disabled(self.viewModel.chatbotPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .transition(.move(edge: .trailing).combined(with: .blurReplace))
            }
        }
        .animation(.default, value: self.viewModel.chatbotPrompt)
        .padding(.horizontal, 16)
        .frame(height: 54)
        .liquidGlassCapsule()
    }
}



private extension View {
    @ViewBuilder
    func liquidGlassCapsule() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.interactive(), in: .capsule)
        } else {
            self.background(.ultraThinMaterial, in: .capsule)
                .overlay {
                    Capsule()
                        .stroke(.white.opacity(0.28), lineWidth: 1)
                }
        }
    }
}

struct EntryFlowView_Previews: PreviewProvider {
    static var previews: some View {
        EntryFlowViewPreview()
    }

    private struct EntryFlowViewPreview: View {
        @State private var viewModel = EntryFlowViewModel.previewLoaded

        var body: some View {
            EntryFlowView()
                .environment(self.viewModel)
        }
    }
}
