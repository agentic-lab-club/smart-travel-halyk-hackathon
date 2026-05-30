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
                // TODO: Hide if chatbot input is focused with animation blurreplace
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

private struct ManualSearchView: View {
    @Bindable var viewModel: EntryFlowViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField("Destination or hotel", text: self.$viewModel.manualSearchText)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.search)
                    .onSubmit(self.viewModel.submitManualSearch)
            }
            .padding(.horizontal, 18)
            .frame(height: 60)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))

            Menu {
                ForEach(self.viewModel.dateWindows, id: \.self) { dateWindow in
                    Button(dateWindow) {
                        self.viewModel.dateWindow = dateWindow
                    }
                }
            } label: {
                ManualSearchRow(systemImage: "calendar", title: self.viewModel.dateWindow)
            }
            .buttonStyle(.plain)

            Stepper(value: self.$viewModel.peopleCount, in: 1...6) {
                ManualSearchRow(
                    systemImage: "person.2.fill",
                    title: self.viewModel.peopleCount == 1 ? "1 guest" : "\(self.viewModel.peopleCount) guests"
                )
            }

            Button(action: self.viewModel.submitManualSearch) {
                Text("Search")
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .foregroundStyle(.black)
                    .background(.yellow, in: .rect(cornerRadius: 20))
            }
            .buttonStyle(.plain)
        }
    }
}

private struct ManualSearchRow: View {
    let systemImage: String
    let title: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: self.systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 28)

            Text(self.title)
                .font(.title3.weight(.medium))
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(.horizontal, 18)
        .frame(height: 60)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
    }
}

private struct EntryFiltersView: View {
    @Bindable var viewModel: EntryFlowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Stepper(value: self.$viewModel.peopleCount, in: 1...6) {
                MetricPill(title: "People", value: "\(self.viewModel.peopleCount)")
            }

            Picker("Budget", selection: self.$viewModel.selectedMode) {
                ForEach(TripMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Menu {
                        ForEach(self.viewModel.dateWindows, id: \.self) { dateWindow in
                            Button(dateWindow) {
                                self.viewModel.dateWindow = dateWindow
                            }
                        }
                    } label: {
                        FilterChip(title: self.viewModel.dateWindow, systemImage: "calendar")
                    }

                    Menu {
                        ForEach(self.viewModel.destinationFilters, id: \.self) { destination in
                            Button(destination) {
                                self.viewModel.selectedDestination = destination
                            }
                        }
                    } label: {
                        FilterChip(title: self.viewModel.selectedDestination, systemImage: "mappin.and.ellipse")
                    }

                    ForEach(self.viewModel.quickPreferences, id: \.self) { preference in
                        Button {
                            self.viewModel.selectedPreference = preference
                        } label: {
                            Text(preference)
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .foregroundStyle(self.viewModel.selectedPreference == preference ? .white : .primary)
                                .background(
                                    self.viewModel.selectedPreference == preference ? Color.green : Color(.secondarySystemGroupedBackground),
                                    in: .capsule
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
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

private struct FilterChip: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(self.title, systemImage: self.systemImage)
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(.primary)
            .background(Color(.secondarySystemGroupedBackground), in: .capsule)
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
