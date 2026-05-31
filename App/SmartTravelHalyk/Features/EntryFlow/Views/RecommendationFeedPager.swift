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

// MARK: - Created Trips Section

private struct CreatedTripsFeedSection: View {
    let trips: [TripDetailsResponse]
    let apiClient: TravelAPIClient

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.green)
                Text("Created trips")
                    .font(.headline)
                Text("\(trips.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
            }

            ForEach(trips.reversed()) { trip in
                NavigationLink {
                    SelectedTripView(trip: trip, apiClient: apiClient)
                } label: {
                    CreatedTripCard(trip: trip)
                        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 4)
    }
}

private struct CreatedTripCard: View {
    let trip: TripDetailsResponse

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.green)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(trip.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(trip.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(dateRangeText)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private var dateRangeText: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        let start = asDate(trip.startDate).map { fmt.string(from: $0) } ?? trip.startDate
        let end   = asDate(trip.endDate).map { fmt.string(from: $0) } ?? trip.endDate
        return "\(start) – \(end)"
    }

    private func asDate(_ string: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.date(from: string)
    }
}

private struct RecommendationFeedPage: View {
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
