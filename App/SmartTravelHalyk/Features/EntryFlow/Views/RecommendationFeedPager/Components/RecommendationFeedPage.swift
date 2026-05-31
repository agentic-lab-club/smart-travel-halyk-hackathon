import SwiftUI

struct RecommendationFeedPage: View {
    let segment: RecommendationFeedSegment
    let recommendations: [TripRecommendation]
    let apiClient: TravelAPIClient

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
                        TripDetailLoaderView(tripId: recommendation.tripId, apiClient: apiClient)
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
