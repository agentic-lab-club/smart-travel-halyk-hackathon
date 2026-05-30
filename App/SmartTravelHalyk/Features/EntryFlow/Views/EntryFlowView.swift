import SwiftUI

struct EntryFlowView: View {
    @StateObject private var viewModel = EntryFlowViewModel(apiClient: .mockingFallback())

    var body: some View {
        NavigationStack {
            Group {
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
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Halyk Travel")
            .task {
                await viewModel.load()
            }
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
            VStack(alignment: .leading, spacing: 20) {
                EntryHeroView(profile: viewModel.profile)
                PreferenceInputPanel(viewModel: viewModel)

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        title: "Ready trips",
                        subtitle: "Personalized from profile, season, budget and cashback."
                    )

                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.recommendations) { recommendation in
                            NavigationLink {
                                TripEntryPreviewView(recommendation: recommendation)
                            } label: {
                                RecommendationCard(recommendation: recommendation)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(16)
        }
    }
}
