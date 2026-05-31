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

    private enum CodingKeys: String, CodingKey {
        case tripId
        case status
        case title
        case normalizedFields
        case missingFields
        case readyForConfirmation
        case chatEntrypoints
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tripId = try container.decode(String.self, forKey: .tripId)
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? "draft"
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        normalizedFields = try container.decodeIfPresent([String: JSONValue].self, forKey: .normalizedFields) ?? [:]
        missingFields = try container.decodeIfPresent([MissingField].self, forKey: .missingFields) ?? []
        readyForConfirmation = try container.decodeIfPresent(Bool.self, forKey: .readyForConfirmation) ?? false
        chatEntrypoints = try container.decodeIfPresent([String].self, forKey: .chatEntrypoints) ?? []
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt) ?? ""
    }
}

struct MissingField: Codable, Equatable, Identifiable, Hashable {
    var id: String { key }

    let key: String
    let label: String
    let prompt: String

    private enum CodingKeys: String, CodingKey {
        case key
        case label
        case prompt
    }

    init(key: String, label: String, prompt: String) {
        self.key = key
        self.label = label
        self.prompt = prompt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedKey = try container.decode(String.self, forKey: .key)
        let decodedLabel = try container.decodeIfPresent(String.self, forKey: .label) ?? decodedKey
        let decodedPrompt = try container.decodeIfPresent(String.self, forKey: .prompt) ?? "Enter \(decodedLabel)"
        self.init(key: decodedKey, label: decodedLabel, prompt: decodedPrompt)
    }
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

    private enum CodingKeys: String, CodingKey {
        case trip
        case sessionId
        case messages
        case assistantHints
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        trip = try container.decode(PlanningTripResponse.self, forKey: .trip)
        sessionId = try container.decode(String.self, forKey: .sessionId)
        messages = try container.decodeIfPresent([PlanningMessage].self, forKey: .messages) ?? []
        assistantHints = try container.decodeIfPresent([String].self, forKey: .assistantHints) ?? []
    }
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
