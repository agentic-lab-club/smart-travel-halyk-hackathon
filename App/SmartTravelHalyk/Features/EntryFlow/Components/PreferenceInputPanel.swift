import SwiftUI

struct PreferenceInputPanel: View {
    @Environment(EntryFlowViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "Quick preferences",
                subtitle: "No long questionnaire. Just enough to refresh the feed."
            )

            HStack(spacing: 12) {
                Stepper(value: $viewModel.peopleCount, in: 1...6) {
                    MetricPill(title: "People", value: "\(viewModel.peopleCount)")
                }

                Menu {
                    Button("Jun - Sep") { viewModel.dateWindow = "Jun - Sep" }
                    Button("Weekend") { viewModel.dateWindow = "Weekend" }
                    Button("Next month") { viewModel.dateWindow = "Next month" }
                } label: {
                    MetricPill(title: "Dates", value: viewModel.dateWindow)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.quickPreferences, id: \.self) { preference in
                        Button {
                            viewModel.selectedPreference = preference
                        } label: {
                            Text(preference)
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .foregroundStyle(viewModel.selectedPreference == preference ? .white : .primary)
                                .background(
                                    viewModel.selectedPreference == preference ? Color.green : Color(.secondarySystemGroupedBackground),
                                    in: .capsule
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Picker("Budget style", selection: $viewModel.selectedMode) {
                Text("Minimum").tag(TripMode.economy)
                Text("Balanced").tag(TripMode.balanced)
                Text("Comfort").tag(TripMode.comfort)
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .background(.background, in: .rect(cornerRadius: 8))
    }
}

struct PreferenceInputPanel_Previews: PreviewProvider {
    static var previews: some View {
        PreferenceInputPanelPreview()
            .padding()
            .background(Color(.systemGroupedBackground))
    }

    private struct PreferenceInputPanelPreview: View {
        @State private var viewModel = EntryFlowViewModel(apiClient: .mockingFallback())

        var body: some View {
            PreferenceInputPanel()
                .environment(viewModel)
        }
    }
}
