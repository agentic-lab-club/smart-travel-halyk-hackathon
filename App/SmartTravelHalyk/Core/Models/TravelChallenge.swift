import Foundation

struct TravelChallenge: Codable, Equatable, Identifiable {
    var id: String { challengeId }

    let challengeId: String
    let title: String
    let description: String
    let reward: ChallengeReward
    let progress: ChallengeProgress
    let deadline: String?
    let difficulty: ChallengeDifficulty
    let reason: String
}
