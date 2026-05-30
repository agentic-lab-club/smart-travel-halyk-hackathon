import Foundation

struct ChallengeReward: Codable, Equatable {
    enum RewardType: String, Codable, CaseIterable {
        case cashbackBoost = "cashback_boost"
        case fixedCashback = "fixed_cashback"
        case discount
        case levelPoints = "level_points"
    }

    let type: RewardType
    let valuePercent: Double?
    let amount: Money?
}
