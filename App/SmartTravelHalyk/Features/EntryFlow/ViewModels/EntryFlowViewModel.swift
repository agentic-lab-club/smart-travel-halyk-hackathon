import Foundation

@MainActor
final class EntryFlowViewModel: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private let apiClient: TravelAPIClient

    @Published var state: LoadState = .idle
    @Published var profile: UserProfileResponse?
    @Published var recommendations: [TripRecommendation] = []
    @Published var selectedMode: TripMode = .balanced
    @Published var peopleCount = 2
    @Published var dateWindow = "Jun - Sep"
    @Published var selectedPreference = "Food"

    let quickPreferences = ["Beach", "Mountains", "Culture", "Quiet", "Shopping", "Food"]

    init(apiClient: TravelAPIClient) {
        self.apiClient = apiClient
    }

    func load() async {
        guard state != .loading else { return }

        state = .loading
        do {
            async let profile = apiClient.fetchUserProfile()
            async let recommendations = apiClient.fetchRecommendations()

            let loadedProfile = try await profile
            let loadedRecommendations = try await recommendations

            self.profile = loadedProfile
            self.recommendations = loadedRecommendations.recommendations
            selectedMode = loadedRecommendations.selectedMode
            state = .loaded
        } catch {
            state = .failed("Could not load travel data.")
        }
    }
}
