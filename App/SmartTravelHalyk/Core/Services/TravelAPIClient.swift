import Foundation

// MARK: - Error

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case emptyResponse(Int)
    case decoding(Error)
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:        return "Invalid request URL."
        case .invalidResponse:   return "Unexpected server response."
        case .httpStatus(let c): return "Server returned status \(c)."
        case .emptyResponse(let c): return "Server returned an empty response (status \(c))."
        case .decoding(let e):   return "Could not decode response: \(e.localizedDescription)"
        case .network(let e):    return "Network error: \(e.localizedDescription)"
        }
    }
}

// MARK: - Client

final class TravelAPIClient {

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    let useMockFallback: Bool

    init(
        baseURL: URL = APIConfig.baseURL,
        session: URLSession = .shared,
        useMockFallback: Bool = false
    ) {
        self.baseURL = baseURL
        self.session = session
        self.useMockFallback = useMockFallback

        let d = JSONDecoder()
        // Planning endpoints return snake_case; the mobile bundle uses camelCase.
        // convertFromSnakeCase handles both: camelCase keys are unchanged,
        // snake_case keys (like session_id, missing_fields) are converted.
        d.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = d

        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        self.encoder = e
    }

    /// Client that always returns mock data without attempting network calls.
    static func mockingFallback(baseURL: URL = APIConfig.baseURL) -> TravelAPIClient {
        TravelAPIClient(baseURL: baseURL, useMockFallback: true)
    }

    // MARK: - Read Contracts

    func fetchUserProfile() async throws -> UserProfileResponse {
        try await get("user-profile", fallback: MockTravelData.userProfile)
    }

    func fetchRecommendations() async throws -> RecommendationsResponse {
        try await get("recommendations", fallback: MockTravelData.recommendations)
    }

    func fetchTripDetails(tripId: String) async throws -> TripDetailsResponse {
        try await get("trips/\(tripId)", fallback: MockTravelData.tripDetails)
    }

    func fetchHotelDetails(hotelId: String) async throws -> HotelDetailsFull {
        try await get("hotels/\(hotelId)", fallback: MockTravelData.hotelDetailsFull)
    }

    // MARK: - Planning Workflow Contracts

    func createTrip(title: String) async throws -> PlanningTripResponse {
        let body = CreateTripRequest(title: title)
        return try await post("trips", body: body)
    }

    func sendPlanningMessage(tripId: String, content: String, action: String = "collect_fields") async throws -> PlanningChatResponse {
        let body = ChatMessageRequest(content: content, action: action)
        return try await post("trips/\(tripId)/chat/messages", body: body)
    }

    func patchTrip(tripId: String, request: PatchTripRequest) async throws -> PlanningTripResponse {
        try await patch("trips/\(tripId)", body: request)
    }

    func confirmTrip(tripId: String) async throws -> TripDetailsResponse {
        try await postEmpty("trips/\(tripId)/confirm")
    }

    func regenerateTrip(tripId: String) async throws -> TripDetailsResponse {
        try await postEmpty("trips/\(tripId)/regenerate")
    }

    func getPlanningState(tripId: String) async throws -> PlanningChatResponse {
        try await get("trips/\(tripId)/chat/messages")
    }

    // MARK: - Private helpers

    private func url(for path: String) throws -> URL {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        return url
    }

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let url = try url(for: path)
        return try await execute(URLRequest(url: url))
    }

    private func get<T: Decodable>(_ path: String, fallback: T) async throws -> T {
        if useMockFallback { return fallback }
        let url = try url(for: path)
        do {
            return try await execute(URLRequest(url: url))
        } catch {
            return fallback
        }
    }

    private func post<Body: Encodable, Response: Decodable>(_ path: String, body: Body) async throws -> Response {
        let url = try url(for: path)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try encoder.encode(body)
        return try await execute(req)
    }

    private func patch<Body: Encodable, Response: Decodable>(_ path: String, body: Body) async throws -> Response {
        let url = try url(for: path)
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try encoder.encode(body)
        return try await execute(req)
    }

    private func postEmpty<T: Decodable>(_ path: String) async throws -> T {
        let url = try url(for: path)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        return try await execute(req)
    }

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.network(error)
        }
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.httpStatus(http.statusCode)
        }
        guard !data.isEmpty else {
            throw APIError.emptyResponse(http.statusCode)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            #if DEBUG
            if let body = String(data: data, encoding: .utf8) {
                print("[TravelAPIClient] Decode failed for \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? ""): \(body)")
            }
            #endif
            throw APIError.decoding(error)
        }
    }
}
