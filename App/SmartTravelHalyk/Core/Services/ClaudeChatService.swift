import Foundation
import Observation

// MARK: - Domain types

struct SuggestedPlace: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String       // SF Symbol name
    let activityType: String
}

// MARK: - Backend agent request/response

private struct AgentRequest: Encodable {
    let inputText: String
    let userId: Int
    let sessionId: String
}

private struct AgentResponse: Decodable {
    let answer: String
}

private struct AgentHistoryResponse: Decodable {
    let messages: [AgentHistoryMessage]
}

private struct AgentHistoryMessage: Decodable {
    let role: String
    let content: String
}

// MARK: - Service

@MainActor
@Observable
final class ClaudeChatService {

    struct ChatMessage: Identifiable {
        let id = UUID()
        let role: Role
        var text: String
        var places: [SuggestedPlace] = []

        enum Role { case user, assistant }
    }

    private(set) var messages: [ChatMessage] = []
    private(set) var isLoading = false
    private(set) var error: String?

    private let userId = 1
    private let sessionId: String
    private let agentURL = APIConfig.agentURL
    private let agentBaseURL = APIConfig.agentBaseURL

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    init(sessionId: String = UUID().uuidString) {
        self.sessionId = Self.agentSessionId(for: sessionId)
    }

    // MARK: - Opener (shown as assistant message, no API call)

    func addOpener(_ text: String) {
        guard messages.isEmpty else { return }
        messages.append(ChatMessage(role: .assistant, text: text))
    }

    func loadHistory(opener: String) async {
        error = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let historyURL = agentBaseURL
                .appendingPathComponent("agent")
                .appendingPathComponent("sessions")
                .appendingPathComponent(sessionId)
                .appendingPathComponent("messages")

            var components = URLComponents(url: historyURL, resolvingAgainstBaseURL: false)
            components?.queryItems = [URLQueryItem(name: "user_id", value: "\(userId)")]
            guard let url = components?.url else {
                addOpener(opener)
                return
            }

            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try decoder.decode(AgentHistoryResponse.self, from: data)
            messages = response.messages.compactMap(historyMessage)
            addOpener(opener)
        } catch {
            addOpener(opener)
            self.error = error.localizedDescription
        }
    }

    // MARK: - Send

    func send(_ userText: String, systemPrompt: String) async {
        error = nil
        messages.append(ChatMessage(role: .user, text: userText))

        let assistantMsg = ChatMessage(role: .assistant, text: "")
        messages.append(assistantMsg)
        let idx = messages.count - 1

        isLoading = true
        defer { isLoading = false }

        // Embed the trip context and format instructions into the agent input.
        let enrichedInput = """
        \(systemPrompt)

        User message: \(userText)
        """

        do {
            let body = AgentRequest(inputText: enrichedInput, userId: userId, sessionId: sessionId)
            var req = URLRequest(url: agentURL)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try encoder.encode(body)

            let (data, _) = try await URLSession.shared.data(for: req)
            let response = try decoder.decode(AgentResponse.self, from: data)

            let raw = response.answer
            messages[idx].places = parsePlaces(from: raw)
            messages[idx].text = stripPlacesBlock(from: raw)
        } catch {
            messages[idx].text = "Something went wrong. Please try again."
            self.error = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private func historyMessage(_ message: AgentHistoryMessage) -> ChatMessage? {
        switch message.role {
        case "user":
            return ChatMessage(role: .user, text: displayUserText(from: message.content))
        case "assistant":
            return ChatMessage(
                role: .assistant,
                text: stripPlacesBlock(from: message.content),
                places: parsePlaces(from: message.content)
            )
        default:
            return nil
        }
    }

    private func displayUserText(from storedText: String) -> String {
        guard let range = storedText.range(of: "User message:") else {
            return storedText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return String(storedText[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func agentSessionId(for rawValue: String) -> String {
        if let uuid = UUID(uuidString: rawValue) {
            return uuid.uuidString
        }

        let bytes = Array(rawValue.utf8)
        var high: UInt64 = 0xcbf29ce484222325
        var low: UInt64 = 0x84222325cbf29ce4
        for byte in bytes {
            high ^= UInt64(byte)
            high &*= 0x100000001b3
            low ^= UInt64(byte) &+ 0x9e3779b97f4a7c15
            low &*= 0x100000001b3
        }

        let uuidBytes: uuid_t = (
            UInt8((high >> 56) & 0xff),
            UInt8((high >> 48) & 0xff),
            UInt8((high >> 40) & 0xff),
            UInt8((high >> 32) & 0xff),
            UInt8((high >> 24) & 0xff),
            UInt8((high >> 16) & 0xff),
            UInt8(((high >> 8) & 0x0f) | 0x50),
            UInt8(high & 0xff),
            UInt8(((low >> 56) & 0x3f) | 0x80),
            UInt8((low >> 48) & 0xff),
            UInt8((low >> 40) & 0xff),
            UInt8((low >> 32) & 0xff),
            UInt8((low >> 24) & 0xff),
            UInt8((low >> 16) & 0xff),
            UInt8((low >> 8) & 0xff),
            UInt8(low & 0xff)
        )
        return UUID(uuid: uuidBytes).uuidString
    }

    private func stripPlacesBlock(from text: String) -> String {
        text.replacingOccurrences(
            of: #"\s*<places>[\s\S]*?</places>\s*"#,
            with: "",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parsePlaces(from text: String) -> [SuggestedPlace] {
        guard let blockRange = text.range(of: #"<places>([\s\S]*?)</places>"#,
                                          options: .regularExpression),
              let jsonRange = text.range(of: #"\[[\s\S]*?\]"#,
                                         options: .regularExpression,
                                         range: blockRange),
              let data = String(text[jsonRange]).data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else { return [] }

        return array.compactMap { dict in
            guard let title = dict["title"] as? String,
                  let description = dict["description"] as? String else { return nil }
            return SuggestedPlace(
                title: title,
                description: description,
                icon: dict["icon"] as? String ?? "star.fill",
                activityType: dict["type"] as? String ?? "attraction"
            )
        }
    }
}

// MARK: - Segment factory

extension SuggestedPlace {
    func toSegment(
        dayNumber: Int,
        date: String,
        city: String,
        replacingId: String? = nil
    ) -> ItinerarySegment {
        let segId = replacingId ?? "ai-\(UUID().uuidString.prefix(8))"
        let activity = ActivityItem(
            activityId: UUID().uuidString,
            title: title,
            type: activityItemType,
            startTime: nil,
            durationMinutes: 90,
            price: nil,
            markerId: nil,
            reason: description
        )
        let details = SegmentDetails.dayItinerary(DayItineraryDetails(
            city: city,
            experienceCount: 1,
            weather: nil,
            pace: .medium,
            overloadScore: 0.4,
            activities: [activity]
        ))
        return ItinerarySegment(
            segmentId: segId,
            type: .dayItinerary,
            title: title,
            date: date,
            dayNumber: dayNumber,
            startTime: nil,
            endTime: nil,
            icon: icon,
            status: .recommended,
            linkedMarkerIds: [],
            linkedRouteIds: [],
            price: nil,
            labels: ["AI Suggested"],
            description: description,
            details: details
        )
    }

    private var activityItemType: ActivityItem.ActivityType {
        switch activityType {
        case "restaurant":  return .restaurant
        case "event":       return .event
        case "shopping":    return .shopping
        case "free_time":   return .freeTime
        default:            return .attraction
        }
    }
}
