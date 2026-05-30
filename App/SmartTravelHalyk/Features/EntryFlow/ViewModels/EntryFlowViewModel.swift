import Foundation
import Observation

@MainActor
@Observable
final class EntryFlowViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private let apiClient: TravelAPIClient

    var state: LoadState = .idle
    var profile: UserProfileResponse?
    var recommendations: [TripRecommendation] = []
    var selectedMode: TripMode = .balanced
    var peopleCount = 2
    var dateWindow = "Jun - Sep"
    var selectedPreference = "Food"
    var selectedDestination = "All"
    var selectedFeedSegment: RecommendationFeedSegment = .similar
    var manualSearchText = ""
    var chatbotPrompt = ""

    let quickPreferences = ["Beach", "Mountains", "Culture", "Quiet", "Shopping", "Food"]
    let dateWindows = ["Jun - Sep", "Weekend", "Next month"]
    let feedSegments = RecommendationFeedSegment.allCases

    var destinationFilters: [String] {
        ["All"] + recommendations.map(\.destinationName).uniqued()
    }

    var filteredRecommendations: [TripRecommendation] {
        recommendations(for: selectedFeedSegment)
    }

    var selectedFeedSummary: String {
        selectedFeedSegment.subtitle
    }

    func recommendations(for segment: RecommendationFeedSegment) -> [TripRecommendation] {
        recommendations.filter { recommendation in
            matchesBudget(recommendation)
            && (selectedDestination == "All" || recommendation.destinationName == selectedDestination)
            && matchesFeedSegment(segment, recommendation: recommendation)
            && matchesManualSearch(recommendation)
        }
        .sorted { $0.score > $1.score }
    }

    var bestCashbackDisplay: String {
        let bestPercent = recommendations.compactMap { $0.cashbackEstimate?.percent }.max() ?? 0
        return "\(bestPercent.formatted(.number.precision(.fractionLength(0...1))))%"
    }

    init(apiClient: TravelAPIClient) {
        self.apiClient = apiClient
    }

    static var previewLoaded: EntryFlowViewModel {
        let viewModel = EntryFlowViewModel(apiClient: .mockingFallback())
        viewModel.apply(
            profile: MockTravelData.userProfile,
            recommendations: MockTravelData.recommendations
        )
        return viewModel
    }

    func load() async {
        guard state != .loading else { return }

        state = .loading
        do {
            async let profile = apiClient.fetchUserProfile()
            async let recommendations = apiClient.fetchRecommendations()

            let loadedProfile = try await profile
            let loadedRecommendations = try await recommendations

            apply(profile: loadedProfile, recommendations: loadedRecommendations)
        } catch {
            state = .failed("Could not load travel data.")
        }
    }

    func submitManualSearch() {
        selectedDestination = "All"
    }

    func submitChatbotPrompt() {
        selectedPreference = chatbotPrompt.isEmpty ? selectedPreference : chatbotPrompt
        chatbotPrompt = ""
    }

    private func apply(profile: UserProfileResponse, recommendations: RecommendationsResponse) {
        self.profile = profile
        self.recommendations = recommendations.recommendations
        selectedMode = recommendations.selectedMode
        state = .loaded
    }

    private func matchesBudget(_ recommendation: TripRecommendation) -> Bool {
        switch selectedMode {
        case .economy:
            return recommendation.estimatedTotalCost.amount <= 700_000
        case .balanced:
            return recommendation.estimatedTotalCost.amount <= 1_000_000
        case .comfort:
            return true
        }
    }

    private func matchesFeedSegment(_ segment: RecommendationFeedSegment, recommendation: TripRecommendation) -> Bool {
        switch segment {
  
        case .similar:
            return recommendation.recommendationType == .similarToPrevious
        case .newStyle:
            return recommendation.recommendationType == .oppositeToPrevious
        case .seasonal:
            return recommendation.recommendationType == .seasonal || recommendation.recommendationType == .eventBased
     
        }
    }

    private func matchesManualSearch(_ recommendation: TripRecommendation) -> Bool {
        let query = manualSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }

        let searchableText = [
            recommendation.destinationName,
            recommendation.destinationTitle,
            recommendation.countryCode,
            recommendation.cityCodes.joined(separator: " "),
            recommendation.reasonLabels.joined(separator: " "),
            recommendation.mainReason
        ]
        .joined(separator: " ")

        return searchableText.localizedCaseInsensitiveContains(query)
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
