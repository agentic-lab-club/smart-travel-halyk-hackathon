import Foundation

struct SmartWarning: Codable, Equatable, Identifiable {
    enum Severity: String, Codable, CaseIterable {
        case low
        case medium
        case high
    }

    var id: String { "\(type.rawValue)-\(segmentId ?? "trip")-\(message)" }

    let type: WarningType
    let severity: Severity
    let segmentId: String?
    let message: String
}
