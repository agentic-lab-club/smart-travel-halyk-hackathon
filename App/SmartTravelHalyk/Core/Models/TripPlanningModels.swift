import Foundation

// MARK: - Planning Workflow Models

/// Returned by createTrip / patchTripFields — gives mobile the tripId and planning state.
struct PlanningTripResponse: Decodable {
    let tripId: String
    let status: String
    let title: String
    let normalizedFields: [String: JSONValue]
    let missingFields: [MissingField]
    let readyForConfirmation: Bool
    let chatEntrypoints: [String]
    let updatedAt: String
}

struct MissingField: Codable, Equatable, Identifiable, Hashable {
    var id: String { key }

    let key: String
    let label: String
    let prompt: String
}

enum JSONValue: Decodable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([JSONValue])
    case object([String: JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value.")
        }
    }

    var stringValue: String? {
        switch self {
        case .string(let value):
            return value
        case .int(let value):
            return String(value)
        case .double(let value):
            return String(value)
        case .bool(let value):
            return value ? "true" : "false"
        case .array, .object, .null:
            return nil
        }
    }
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
    let trip: PlanningTripResponse
    let sessionId: String
    let messages: [PlanningMessage]
    let assistantHints: [String]
}

struct PlanningMessage: Decodable, Identifiable {
    let id: String
    let role: String
    let content: String
    let action: String?
    let structured: [String: JSONValue]?
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

struct PatchTripRequest: Encodable {
    let originCity: String?
    let destinationCountry: String?
    let destinationCity: String?
    let startDate: String?
    let endDate: String?
    let budget: Int?
    let transportType: String?
    let tripPurpose: String?
    let citizenship: String?
    let hotelPreferences: [String]?
    let eventInterest: Bool?
    let insuranceNeeded: Bool?
    let interests: [String]?
}
