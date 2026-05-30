import Foundation

final class TravelAPIClient {
    enum APIError: Error {
        case missingBaseURL
        case invalidResponse
    }

    private let baseURL: URL?
    private let session: URLSession
    private let decoder: JSONDecoder
    private let useMockFallback: Bool

    init(
        baseURL: URL? = nil,
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        useMockFallback: Bool = true
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
        self.useMockFallback = useMockFallback
    }

    static func mockingFallback(baseURL: URL? = nil) -> TravelAPIClient {
        TravelAPIClient(baseURL: baseURL, useMockFallback: true)
    }

    func fetchUserProfile() async throws -> UserProfileResponse {
        try await request(path: "user-profile", fallback: MockTravelData.userProfile)
    }

    func fetchRecommendations() async throws -> RecommendationsResponse {
        try await request(path: "recommendations", fallback: MockTravelData.recommendations)
    }

    func fetchTripDetails(tripId: String) async throws -> TripDetailsResponse {
        try await request(path: "trips/\(tripId)", fallback: MockTravelData.tripDetails)
    }

    func fetchHotelDetails(hotelId: String) async throws -> HotelDetailsFull {
        try await request(path: "hotels/\(hotelId)", fallback: MockTravelData.hotelDetailsFull)
    }

    private func request<Response: Decodable>(path: String, fallback: Response) async throws -> Response {
        guard let baseURL else {
            if useMockFallback { return fallback }
            throw APIError.missingBaseURL
        }

        do {
            let url = baseURL.appending(path: path)
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
                throw APIError.invalidResponse
            }
            return try decoder.decode(Response.self, from: data)
        } catch {
            if useMockFallback { return fallback }
            throw error
        }
    }
}
