import SwiftUI

struct RecommendationFeedPager: View {
    @Bindable var viewModel: EntryFlowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.selectedFeedSummary)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            RecommendationFeedPage(
                segment: viewModel.selectedFeedSegment,
                recommendations: viewModel.filteredRecommendations
            )
        }
        .navigationTitle(viewModel.selectedFeedSegment.title)
    }
}

private struct RecommendationFeedPage: View {
    let segment: RecommendationFeedSegment
    let recommendations: [TripRecommendation]

    var body: some View {
        LazyVStack(spacing: 12) {
            if recommendations.isEmpty {
                ContentUnavailableView(
                    "No \(segment.title.lowercased()) trips",
                    systemImage: "airplane.circle",
                    description: Text("Try a wider budget, another destination, or clear the search.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ForEach(recommendations) { recommendation in
                    NavigationLink {
                        TripEntryPreviewView(recommendation: recommendation)
                    } label: {
                        RecommendationCard(recommendation: recommendation)
                            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
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
