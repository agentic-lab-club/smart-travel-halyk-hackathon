import SwiftUI
import UIKit

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
        switch viewModel.state {
        case .idle, .loading:
            loadingView
        case .loaded:
            entryContent
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
        let planningBinding = Binding(
            get: { viewModel.isPlanning },
            set: { if !$0 && viewModel.planningState != .confirmed { viewModel.resetPlanning() } }
        )
        return ScrollView {
            RecommendationFeedPager(viewModel: self.viewModel)
        }
        .contentMargins(16, for: .scrollContent)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                FeedSegmentBar(viewModel: self.viewModel)
                    .contentMargins(.horizontal, 16, for: .scrollContent)

                ChatbotInputCapsule(viewModel: self.viewModel)
                    .padding(.horizontal, 16)
            }
            .padding(.bottom, 10)
        }
        .sheet(isPresented: planningBinding) {
            PlanningSheet(viewModel: self.viewModel)
        }
    }
}

// MARK: - Planning sheet

private let PSColor = (
    bg: Color(red: 0.07, green: 0.09, blue: 0.14),
    card: Color(red: 0.13, green: 0.16, blue: 0.22),
    accent: Color.green
)

private struct PlanningSheet: View {
    @Bindable var viewModel: EntryFlowViewModel

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                PSColor.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        if case .failed(let msg) = viewModel.planningState {
                            errorBanner(msg)
                        }
                        if case .creating = viewModel.planningState {
                            statusRow(icon: "ellipsis.circle", text: "Starting session…")
                        }
                        if !viewModel.missingFields.isEmpty {
                            missingFieldsSection
                        }
                        if viewModel.canConfirm {
                            readyBanner
                        }
                        if case .confirming = viewModel.planningState {
                            statusRow(icon: "sparkles", text: "Generating your trip plan…", tint: PSColor.accent)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 120)
                }
//                .ignoresSafeArea(edges: .top)

                bottomAction
            }
            .toolbar {
                ToolbarItem {
                    Button {
                        viewModel.resetPlanning()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }

                ToolbarItem(placement: .title) {
                    statusPill
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackgroundInteraction(.enabled)
        .interactiveDismissDisabled()
    }

    // MARK: - Header

    private var statusPill: some View {
        Group {
            switch viewModel.planningState {
            case .creating:
                Label("Starting", systemImage: "ellipsis.circle")
            case .collecting:
                Label("Collecting", systemImage: "doc.text.magnifyingglass")
            case .readyToConfirm:
                Label("Ready", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(PSColor.accent)
            case .confirming:
                Label("Generating", systemImage: "sparkles")
                    .foregroundStyle(PSColor.accent)
            case .failed:
                Label("Error", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
            default:
                EmptyView()
            }
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.white.opacity(0.12), in: Capsule())
        .foregroundStyle(.white)
        .fixedSize(horizontal: true, vertical: false)
    }

    private var headerTitle: String {
        switch viewModel.planningState {
        case .readyToConfirm: return "All set!"
        case .confirming: return "Building your trip…"
        case .failed: return "Something went wrong"
        default: return "Tell us about your trip"
        }
    }

    private var headerSubtitle: String {
        switch viewModel.planningState {
        case .readyToConfirm: return "Review the details and generate your trip plan."
        case .confirming: return "This takes a few seconds."
        default: return "Fill in the missing details below."
        }
    }

    // MARK: - Fields

    private var missingFieldsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(viewModel.missingFields) { field in
                FieldCard(field: field, viewModel: viewModel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var readyBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(PSColor.accent)
            Text("All details collected")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PSColor.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
    }

    private func errorBanner(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.triangle")
            .font(.subheadline)
            .foregroundStyle(.red)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
    }

    private func statusRow(icon: String, text: String, tint: Color = .white) -> some View {
        HStack(spacing: 10) {
            if icon == "ellipsis.circle" || icon == "sparkles" {
                ProgressView().tint(tint)
            } else {
                Image(systemName: icon).foregroundStyle(tint)
            }
            Text(text).font(.subheadline).foregroundStyle(.white.opacity(0.65))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PSColor.card, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Bottom action

    private var bottomAction: some View {
        VStack(spacing: 0) {
            Divider().overlay(Color.white.opacity(0.1))
            if viewModel.canConfirm || !viewModel.missingFields.isEmpty {
                let ready = viewModel.canConfirm || viewModel.allMissingFieldsFilled
                Button {
                    Task { await viewModel.submitAndConfirm() }
                } label: {
                    Label("Generate my trip plan", systemImage: "sparkles")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(ready ? PSColor.accent : PSColor.card, in: Capsule())
                        .foregroundStyle(ready ? .black : .white.opacity(0.4))
                }
                .buttonStyle(.plain)
                .disabled(!ready)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .animation(.easeInOut(duration: 0.2), value: ready)
            }
        }
        .background(PSColor.bg)
    }
}

private struct MissingFieldsRow: View {
    let fields: [MissingField]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(fields) { field in
                    Text(field.label)
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

// MARK: - FieldCard (date-aware, dark-styled)

private struct FieldCard: View {
    let field: MissingField
    @Bindable var viewModel: EntryFlowViewModel

    private var isDateField: Bool { field.key == "start_date" || field.key == "end_date" }
    private var isStartDate: Bool { field.key == "start_date" }
    private var isEndDate: Bool { field.key == "end_date" }
    private var isBudget: Bool { field.key == "budget" }

    // ISO 8601 formatter for storage
    private static let isoFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private var minimumStartDate: Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: 1, to: today) ?? today
    }

    private var minimumEndDate: Date {
        let startRaw = viewModel.bindingValue(for: "start_date")
        let startDate = Self.isoFormatter.date(from: startRaw) ?? minimumStartDate
        return startDate < minimumStartDate ? minimumStartDate : startDate
    }

    private var dateRange: ClosedRange<Date> {
        if isStartDate {
            return minimumStartDate...Date.distantFuture
        }
        if isEndDate {
            return minimumEndDate...Date.distantFuture
        }
        return minimumStartDate...Date.distantFuture
    }

    private var dateBinding: Binding<Date> {
        Binding(
            get: {
                let raw = viewModel.bindingValue(for: field.key)
                let fallback = isStartDate ? minimumStartDate : minimumEndDate
                let parsed = Self.isoFormatter.date(from: raw) ?? fallback
                return parsed < fallback ? fallback : parsed
            },
            set: { date in
                let normalized = Self.isoFormatter.string(from: date)
                viewModel.setBindingValue(normalized, for: field.key)

                guard isStartDate else { return }
                let minEndDate = date < minimumStartDate ? minimumStartDate : date
                let currentEndRaw = viewModel.bindingValue(for: "end_date")
                if let currentEnd = Self.isoFormatter.date(from: currentEndRaw), currentEnd < minEndDate {
                    viewModel.setBindingValue(Self.isoFormatter.string(from: minEndDate), for: "end_date")
                }
            }
        )
    }

    private var textBinding: Binding<String> {
        Binding(
            get: { viewModel.bindingValue(for: field.key) },
            set: { viewModel.setBindingValue($0, for: field.key) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(field.label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(0.5)
                .frame(maxWidth: .infinity, alignment: .leading)

            if isDateField {
                DatePicker(
                    "",
                    selection: dateBinding,
                    in: dateRange,
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(PSColor.accent)
                .colorScheme(.dark)
            } else {
                HStack(spacing: 8) {
                    TextField(field.prompt, text: textBinding)
                        .keyboardType(isBudget ? .numberPad : .default)
                        .textInputAutocapitalization(isBudget ? .never : .words)
                        .font(.body)
                        .foregroundStyle(.white)
                        .tint(PSColor.accent)

                    if isBudget {
                        Text("KZT")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(PSColor.card, in: RoundedRectangle(cornerRadius: 14))
        .onAppear {
            if isDateField {
                let fallback = isStartDate ? minimumStartDate : minimumEndDate
                let current = viewModel.bindingValue(for: field.key)
                let parsed = Self.isoFormatter.date(from: current) ?? fallback
                let clamped = parsed < fallback ? fallback : parsed
                viewModel.setBindingValue(Self.isoFormatter.string(from: clamped), for: field.key)

                if isStartDate {
                    let endRaw = viewModel.bindingValue(for: "end_date")
                    if let endDate = Self.isoFormatter.date(from: endRaw), endDate < clamped {
                        viewModel.setBindingValue(Self.isoFormatter.string(from: clamped), for: "end_date")
                    }
                }
            } else if isBudget {
                let current = viewModel.bindingValue(for: field.key)
                if let value = Int(current), value <= 0 {
                    viewModel.setBindingValue("", for: field.key)
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
        .foregroundStyle(isSelected ? .white : .primary)
        .glassEffect(
            .clear
                .interactive()
                .tint(isSelected ? Color.green : Color(.secondarySystemGroupedBackground))
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
        .animation(.default, value: viewModel.chatbotPrompt)
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
            background(.ultraThinMaterial, in: .capsule)
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
                .environment(viewModel)
        }
    }
}

struct PlanningSheet_Previews: PreviewProvider {
    static var previews: some View {
        EntryFlowViewPreview()
    }

    private struct EntryFlowViewPreview: View {
        var body: some View {
            PlanningSheet(viewModel: .previewLoaded)
        }
    }
}
