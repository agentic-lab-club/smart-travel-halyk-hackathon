import SwiftUI

let planningColors = (
    bg: Color(red: 0.07, green: 0.09, blue: 0.14),
    card: Color(red: 0.13, green: 0.16, blue: 0.22),
    accent: Color.green
)

struct PlanningSheet: View {
    @Bindable var viewModel: EntryFlowViewModel

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                planningColors.bg.ignoresSafeArea()

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
                            statusRow(icon: "sparkles", text: "Generating your trip plan…", tint: planningColors.accent)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 120)
                }

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
                    .foregroundStyle(planningColors.accent)
            case .confirming:
                Label("Generating", systemImage: "sparkles")
                    .foregroundStyle(planningColors.accent)
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
                .foregroundStyle(planningColors.accent)
            Text("All details collected")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(planningColors.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
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
        .background(planningColors.card, in: RoundedRectangle(cornerRadius: 14))
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
                        .background(ready ? planningColors.accent : planningColors.card, in: Capsule())
                        .foregroundStyle(ready ? .black : .white.opacity(0.4))
                }
                .buttonStyle(.plain)
                .disabled(!ready)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .animation(.easeInOut(duration: 0.2), value: ready)
            }
        }
        .background(planningColors.bg)
    }
}
