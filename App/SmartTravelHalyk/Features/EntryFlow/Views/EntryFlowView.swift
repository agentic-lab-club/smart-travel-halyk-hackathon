import SwiftUI

struct EntryFlowView: View {
    @Environment(EntryFlowViewModel.self) private var viewModel

    var body: some View {
        @Bindable var vm = viewModel
        stateContent
            .navigationDestination(isPresented: $vm.isShowingGeneratedTrip) {
                if let trip = vm.generatedTrip {
                    SelectedTripView(trip: trip, apiClient: vm.apiClient)
                }
            }
    }

    @ViewBuilder
    private var stateContent: some View {
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
            VStack(spacing: 8) {
                FeedSegmentBar(viewModel: self.viewModel)
                    .contentMargins(.horizontal, 16, for: .scrollContent)

                if self.viewModel.isPlanning {
                    PlanningStatusBanner(viewModel: self.viewModel)
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                ChatbotInputCapsule(viewModel: self.viewModel)
                    .padding(.horizontal, 16)
            }
            .animation(.smooth(duration: 0.3), value: self.viewModel.isPlanning)
            .padding(.bottom, 10)
        }
    }
}

private struct PlanningStatusBanner: View {
    @Bindable var viewModel: EntryFlowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                statusLabel
                Spacer()
                if viewModel.isPlanning {
                    Button {
                        viewModel.resetPlanning()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            if !viewModel.missingFields.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Still needed:")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    MissingFieldsRow(fields: viewModel.missingFields)
                }
            }

            if viewModel.canConfirm {
                Button {
                    Task { await viewModel.confirmTrip() }
                } label: {
                    Label("Generate my trip plan", systemImage: "sparkles")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.green, in: .capsule)
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }

            if case .confirming = viewModel.planningState {
                HStack(spacing: 8) {
                    ProgressView().tint(.green)
                    Text("Generating your trip…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.green.opacity(0.3), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var statusLabel: some View {
        switch viewModel.planningState {
        case .creating:
            Label("Starting session…", systemImage: "ellipsis.circle")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        case .collecting:
            Label("Collecting trip details", systemImage: "doc.text.magnifyingglass")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        case .readyToConfirm:
            Label("Ready to generate", systemImage: "checkmark.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.green)
        case .confirming:
            Label("Generating plan…", systemImage: "sparkles")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.green)
        case .failed(let msg):
            Label(msg, systemImage: "exclamationmark.triangle")
                .font(.subheadline)
                .foregroundStyle(.red)
        default:
            EmptyView()
        }
    }
}

private struct MissingFieldsRow: View {
    let fields: [String]
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(fields, id: \.self) { field in
                    Text(field)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(.orange.opacity(0.15), in: .capsule)
                        .foregroundStyle(.orange)
                }
            }
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
                .onSubmit { Task { await self.viewModel.submitChatbotPrompt() } }

            if !self.viewModel.chatbotPrompt.isEmpty {
                Button { Task { await self.viewModel.submitChatbotPrompt() } } label: {
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
