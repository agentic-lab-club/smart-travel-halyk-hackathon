import Foundation

struct ChallengeProgress: Codable, Equatable {
    enum Unit: String, Codable, CaseIterable {
        case kzt = "KZT"
        case points
        case payments
    }

    let current: Double
    let target: Double
    let unit: Unit
}
