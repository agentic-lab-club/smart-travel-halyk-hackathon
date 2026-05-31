import SwiftUI

struct RecommendationFeedPager: View {
    @Bindable var viewModel: EntryFlowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !viewModel.createdTrips.isEmpty {
                CreatedTripsFeedSection(trips: viewModel.createdTrips, apiClient: viewModel.apiClient)
            }

            Text(viewModel.selectedFeedSummary)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            RecommendationFeedPage(
                segment: viewModel.selectedFeedSegment,
                recommendations: viewModel.filteredRecommendations,
                apiClient: viewModel.apiClient
            )
        }
        .navigationTitle(viewModel.selectedFeedSegment.title)
    }
}

struct RecommendationFeedPager_Previews: PreviewProvider {
    static var previews: some View {
        EntryFlowViewPreview()
    }

    private struct EntryFlowViewPreview: View {
        @State private var viewModel = EntryFlowViewModel.previewLoaded

        var body: some View {
            NavigationStack {
                EntryFlowView()
            }
            .environment(viewModel)
        }
    }
}
