import Foundation

// MARK: - Planning Workflow Models

/// Returned by createTrip / patchTripFields — gives mobile the tripId and planning state.
struct PlanningTripResponse: Decodable {
    let tripId: String
    let status: String
    let missingFields: [String]
    let readyForConfirmation: Bool
}

/// Planning status values mirroring backend constants.
enum TripPlanningStatus: String, Decodable {
    case draft
    case collectingInput = "collecting_input"
    case readyForConfirmation = "ready_for_confirmation"
    case confirmed
    case generated
    case edited
    case failed

    var isReadyToConfirm: Bool { self == .readyForConfirmation }
    var isGenerated: Bool { self == .generated || self == .edited }
}

/// Returned by sendPlanningMessage.
struct PlanningChatResponse: Decodable {
    let sessionId: String
    let messages: [PlanningMessage]
    let missingFields: [String]
    let assistantHints: [String]
}

struct PlanningMessage: Decodable, Identifiable {
    let id: String
    let role: String
    let content: String
    let createdAt: String?

    var isUser: Bool { role == "user" }
    var isAssistant: Bool { role == "assistant" }
}

// MARK: - Planning DTO inputs (Encodable only)

struct CreateTripRequest: Encodable {
    let title: String
}

struct ChatMessageRequest: Encodable {
    let content: String
    let action: String
}
