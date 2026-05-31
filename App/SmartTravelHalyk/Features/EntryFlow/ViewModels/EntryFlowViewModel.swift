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

    enum PlanningState: Equatable {
        case idle
        case creating
        case collecting
        case readyToConfirm
        case confirming
        case confirmed
        case failed(String)
    }

    let apiClient: TravelAPIClient

    // MARK: - Discovery state

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

    // MARK: - Planning workflow state

    var planningState: PlanningState = .idle
    var activeTripId: String?
    var planningMessages: [PlanningMessage] = []
    var normalizedPlanningFields: [String: JSONValue] = [:]
    var missingFields: [MissingField] = []
    var missingFieldInputs: [String: String] = [:]
    var generatedTrip: TripDetailsResponse?

    var isPlanning: Bool {
        switch planningState {
        case .idle, .confirmed: return false
        default: return true
        }
    }

    var canConfirm: Bool { planningState == .readyToConfirm }

    var createdTrips: [TripDetailsResponse] = []

    var isShowingGeneratedTrip: Bool {
        get { generatedTrip != nil }
        set { if !newValue { resetPlanning() } }
    }

    // MARK: - Discovery helpers

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

    // MARK: - Discovery loading

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

    // MARK: - Planning workflow

    /// Submits the chatbot prompt to the backend planning workflow.
    /// On first call: creates a new trip draft. On subsequent calls: appends to the existing session.
    func submitChatbotPrompt() async {
        let prompt = chatbotPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }

        if let validationError = validatePrompt(prompt, isInitial: activeTripId == nil) {
            planningState = .failed(validationError)
            return
        }

        chatbotPrompt = ""

        if activeTripId == nil {
            await startPlanningSession(prompt: prompt)
        } else {
            await continuePlanning(prompt: prompt)
        }
    }

    private func startPlanningSession(prompt: String) async {
        planningState = .creating
        do {
            let creation = try await apiClient.createTrip(title: prompt)
            activeTripId = creation.tripId
            applyPlanningTrip(creation)
            await continuePlanning(prompt: prompt)
        } catch {
            planningState = .failed("Could not start planning session. \(error.localizedDescription)")
        }
    }

    private func continuePlanning(prompt: String) async {
        guard let tripId = activeTripId else { return }
        planningState = .collecting
        do {
            let response = try await apiClient.sendPlanningMessage(tripId: tripId, content: prompt)
            planningMessages = response.messages
            applyPlanningTrip(response.trip)
        } catch {
            planningState = .failed("Could not send message. \(error.localizedDescription)")
        }
    }

    func bindingValue(for fieldKey: String) -> String {
        missingFieldInputs[fieldKey] ?? prefilledValue(for: fieldKey)
    }

    func setBindingValue(_ value: String, for fieldKey: String) {
        missingFieldInputs[fieldKey] = value
    }

    func submitMissingFields() async {
        guard let tripId = activeTripId else { return }

        if let validationError = validateBudget() ?? validateDates() {
            planningState = .failed(validationError)
            return
        }

        let request = makePatchTripRequest()

        planningState = .collecting
        do {
            let response = try await apiClient.patchTrip(tripId: tripId, request: request)
            applyPlanningTrip(response)
        } catch {
            planningState = .failed("Could not save trip details. \(error.localizedDescription)")
        }
    }

    /// Explicitly confirms the trip and fetches the final generated bundle.
    func confirmTrip() async {
        guard let tripId = activeTripId else { return }
        planningState = .confirming
        do {
            let trip = try await apiClient.confirmTrip(tripId: tripId)
            generatedTrip = trip
            createdTrips.append(trip)
            planningState = .confirmed
        } catch {
            planningState = .failed(error.localizedDescription)
        }
    }

    /// Resets planning state so the user can start a new session.
    func resetPlanning() {
        activeTripId = nil
        planningMessages = []
        normalizedPlanningFields = [:]
        missingFields = []
        missingFieldInputs = [:]
        generatedTrip = nil
        planningState = .idle
        // createdTrips intentionally preserved across sessions
    }

    // MARK: - Private helpers

    private func validatePrompt(_ prompt: String, isInitial: Bool) -> String? {
        let minLength = isInitial ? Self.minInitialPromptLength : Self.minChatPromptLength
        if prompt.count < minLength {
            return "Please enter at least \(minLength) characters."
        }
        return nil
    }

    private func validateBudget() -> String? {
        guard missingFields.contains(where: { $0.key == "budget" }) else { return nil }
        let raw = missingFieldInputs["budget"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if raw.isEmpty {
            return "Budget is required."
        }
        guard let budget = Int(raw) else {
            return "Budget must be a number."
        }
        if budget <= 0 {
            return "Budget must be greater than 0."
        }
        return nil
    }

    private func validateDates() -> String? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let minStartDate = calendar.date(byAdding: .day, value: 1, to: today) else {
            return nil
        }

        if let startDate = parseDate(fieldKey: "start_date") {
            let startDay = calendar.startOfDay(for: startDate)
            if startDay < minStartDate {
                return "Start date must be after today."
            }
        }

        if let startDate = parseDate(fieldKey: "start_date"),
           let endDate = parseDate(fieldKey: "end_date") {
            let startDay = calendar.startOfDay(for: startDate)
            let endDay = calendar.startOfDay(for: endDate)
            if endDay < startDay {
                return "End date cannot be earlier than the start date."
            }
        }

        return nil
    }

    private static let planningDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    private func parseDate(fieldKey: String) -> Date? {
        guard let raw = normalizedInput(for: fieldKey) else { return nil }
        return Self.planningDateFormatter.date(from: raw)
    }

    private static let minInitialPromptLength = 3
    private static let minChatPromptLength = 2

    private func apply(profile: UserProfileResponse, recommendations: RecommendationsResponse) {
        self.profile = profile
        self.recommendations = recommendations.recommendations
        selectedMode = recommendations.selectedMode
        state = .loaded
    }

    private func applyPlanningTrip(_ trip: PlanningTripResponse) {
        activeTripId = trip.tripId
        normalizedPlanningFields = trip.normalizedFields
        missingFields = trip.missingFields.filter { field in
            let camelKey = Self.snakeToCamel(field.key)
            let value = (trip.normalizedFields[camelKey] ?? trip.normalizedFields[field.key])?.stringValue
            guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return true }
            if field.key == "budget", let n = Int(value), n <= 0 { return true }
            return false
        }

        if case .failed = planningState {
            planningState = .collecting
        }

        if trip.readyForConfirmation {
            planningState = .readyToConfirm
        } else {
            planningState = .collecting
        }

        for field in trip.missingFields {
            if missingFieldInputs[field.key]?.isEmpty != false {
                missingFieldInputs[field.key] = prefilledValue(for: field.key)
            }
        }
    }

    private func prefilledValue(for fieldKey: String) -> String {
        // normalizedPlanningFields keys are camelCase (JSONDecoder convertFromSnakeCase converts dict keys too)
        // so look up both the camelCase version and the original snake_case key
        let camelKey = Self.snakeToCamel(fieldKey)
        return normalizedPlanningFields[camelKey]?.stringValue
            ?? normalizedPlanningFields[fieldKey]?.stringValue
            ?? ""
    }

    private static func snakeToCamel(_ key: String) -> String {
        let parts = key.split(separator: "_")
        guard parts.count > 1 else { return key }
        return parts[0] + parts.dropFirst().map { $0.capitalized }.joined()
    }

    private func makePatchTripRequest() -> PatchTripRequest {
        PatchTripRequest(
            originCity: normalizedInput(for: "origin_city"),
            destinationCountry: normalizedInput(for: "destination_country"),
            destinationCity: normalizedInput(for: "destination_city"),
            startDate: normalizedInput(for: "start_date"),
            endDate: normalizedInput(for: "end_date"),
            budget: normalizedBudgetInput(),
            transportType: normalizedInput(for: "transport_type"),
            tripPurpose: normalizedInput(for: "trip_purpose"),
            citizenship: normalizedInput(for: "citizenship"),
            hotelPreferences: nil,
            eventInterest: nil,
            insuranceNeeded: nil,
            interests: nil
        )
    }

    private func normalizedInput(for fieldKey: String) -> String? {
        let value = missingFieldInputs[fieldKey]?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value, !value.isEmpty else { return nil }
        return value
    }

    private func normalizedBudgetInput() -> Int? {
        guard let budgetString = missingFieldInputs["budget"],
              let budget = Int(budgetString.trimmingCharacters(in: .whitespacesAndNewlines)),
              budget > 0 else { return nil }
        return budget
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
