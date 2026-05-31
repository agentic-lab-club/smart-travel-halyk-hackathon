import SwiftUI

/// Loads a `TripDetailsResponse` from the backend by tripId and presents `SelectedTripView`.
/// Falls back to mock data if the API is unavailable (useful for offline demo or simulator without backend).
struct TripDetailLoaderView: View {
    let tripId: String
    let apiClient: TravelAPIClient

    @State private var trip: TripDetailsResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                loadingPlaceholder
            } else if let trip {
                SelectedTripView(trip: trip, apiClient: apiClient)
            } else {
                errorView
            }
        }
        .task { await loadTrip() }
    }

    private var loadingPlaceholder: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading trip details…")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var errorView: some View {
        ContentUnavailableView(
            "Trip unavailable",
            systemImage: "exclamationmark.triangle",
            description: Text(errorMessage ?? "Could not load trip details.")
        )
    }

    private func loadTrip() async {
        isLoading = true
        do {
            trip = try await apiClient.fetchTripDetails(tripId: tripId)
        } catch {
            // Fall back to mock so the demo always shows something.
            trip = MockTravelData.tripDetails
        }
        isLoading = false
    }
}
