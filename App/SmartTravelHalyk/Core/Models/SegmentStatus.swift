import Foundation

enum SegmentStatus: String, Codable, CaseIterable {
    case planned
    case recommended
    case optional
    case selected
    case expired
    case unavailable
    case warning
}
