import Foundation

extension MockTravelData {
    static let travelChallenges: [TravelChallenge] = [
        TravelChallenge(
            challengeId: "challenge-hotel-boost",
            title: "Boost hotel cashback",
            description: "Make 3 travel-related Halyk card payments before checkout.",
            reward: ChallengeReward(
                type: .cashbackBoost,
                valuePercent: 1.5,
                amount: nil
            ),
            progress: ChallengeProgress(current: 1, target: 3, unit: .payments),
            deadline: "2026-06-16",
            difficulty: .easy,
            reason: "User already planned several small transport and food payments."
        )
    ]
}
