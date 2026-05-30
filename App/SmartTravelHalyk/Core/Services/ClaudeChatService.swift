import Foundation
import Observation

// MARK: - API key
// Replace with your actual Anthropic API key before demoing.
private let kAnthropicAPIKey = "YOUR_ANTHROPIC_API_KEY"

// MARK: - Domain types

struct SuggestedPlace: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String       // SF Symbol name
    let activityType: String
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

    private let apiKey: String

    init(apiKey: String = kAnthropicAPIKey) {
        self.apiKey = apiKey
    }

    // MARK: - Send

    func send(_ userText: String, systemPrompt: String) async {
        error = nil
        let userMsg = ChatMessage(role: .user, text: userText)
        messages.append(userMsg)

        let assistantMsg = ChatMessage(role: .assistant, text: "")
        messages.append(assistantMsg)
        let idx = messages.count - 1

        isLoading = true
        defer { isLoading = false }

        do {
            let requestBody = buildBody(systemPrompt: systemPrompt)
            var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            req.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

            let (bytes, _) = try await URLSession.shared.bytes(for: req)

            var accumulated = ""
            for try await line in bytes.lines {
                guard line.hasPrefix("data: ") else { continue }
                let payload = String(line.dropFirst(6))
                guard payload != "[DONE]",
                      let data = payload.data(using: .utf8),
                      let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      (event["type"] as? String) == "content_block_delta",
                      let delta = event["delta"] as? [String: Any],
                      let chunk = delta["text"] as? String else { continue }

                accumulated += chunk
                // Show raw text while streaming; strip <places> block live
                messages[idx].text = stripPlacesBlock(from: accumulated)
            }

            // After stream ends, parse the places block
            let parsed = parsePlaces(from: accumulated)
            messages[idx].places = parsed
            messages[idx].text = stripPlacesBlock(from: accumulated)

        } catch {
            messages[idx].text = "Something went wrong. Please try again."
            self.error = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private func buildBody(systemPrompt: String) -> [String: Any] {
        // Include all messages except the last (empty assistant placeholder)
        let history = messages.dropLast().map { msg -> [String: String] in
            ["role": msg.role == .user ? "user" : "assistant",
             "content": msg.text]
        }
        return [
            "model": "claude-sonnet-4-6",
            "max_tokens": 1024,
            "system": systemPrompt,
            "stream": true,
            "messages": history
        ]
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
