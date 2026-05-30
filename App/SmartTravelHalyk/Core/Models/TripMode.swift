import Foundation

enum TripMode: String, Codable, CaseIterable, Identifiable {
    case economy
    case balanced
    case comfort

    var id: String { rawValue }
}
