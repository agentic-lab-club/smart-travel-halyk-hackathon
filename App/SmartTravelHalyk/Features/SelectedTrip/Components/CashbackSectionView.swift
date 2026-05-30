import SwiftUI

struct CashbackSectionView: View {
    let cashback: CashbackInfo
    let challenges: [TravelChallenge]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CashbackSummaryCard(cashback: cashback)

            if !challenges.isEmpty {
                Text("Active challenges")
                    .font(.subheadline.weight(.semibold))

                ForEach(challenges) { challenge in
                    ChallengeTile(challenge: challenge)
                }
            }
        }
    }
}

private struct CashbackSummaryCard: View {
    let cashback: CashbackInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Estimated cashback")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(cashback.estimatedTotal.displayString)
                        .font(.title2.bold())
                        .foregroundStyle(.green)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if let boosted = cashback.boostedPercent {
                        Text("up to \(boosted.formatted(.number.precision(.fractionLength(0...1))))%")
                            .font(.title3.bold())
                            .foregroundStyle(.green)
                        Text("boosted rate")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(cashback.basePercent.formatted(.number.precision(.fractionLength(0...1))))%")
                            .font(.title3.bold())
                            .foregroundStyle(.green)
                    }
                }
            }

            Divider()

            ForEach(cashback.items) { item in
                CashbackItemRow(item: item)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.green.opacity(0.25), lineWidth: 1)
        }
    }
}

private struct CashbackItemRow: View {
    let item: CashbackItem

    var body: some View {
        HStack {
            Image(systemName: iconForCategory(item.category))
                .font(.caption.weight(.medium))
                .foregroundStyle(.green)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(item.category.title)
                    .font(.caption.weight(.medium))
                Text(item.condition)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text("\(Int(item.amount).formatted(.number.grouping(.automatic))) \(item.currency.rawValue)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.green)
        }
    }

    private func iconForCategory(_ cat: CashbackItem.Category) -> String {
        switch cat {
        case .hotel:     return "bed.double.fill"
        case .flight:    return "airplane"
        case .transport: return "car.fill"
        case .activity:  return "star.fill"
        case .insurance: return "shield.fill"
        case .other:     return "creditcard.fill"
        }
    }
}

private struct ChallengeTile: View {
    let challenge: TravelChallenge

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        DifficultyBadge(difficulty: challenge.difficulty)
                        Text(challenge.title)
                            .font(.subheadline.weight(.semibold))
                    }
                    Text(challenge.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                RewardBadge(reward: challenge.reward)
            }

            ProgressView(value: challenge.progress.current, total: challenge.progress.target)
                .tint(.green)

            HStack {
                Text("\(Int(challenge.progress.current)) / \(Int(challenge.progress.target)) \(challenge.progress.unit.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if let deadline = challenge.deadline {
                    Label(deadline, systemImage: "calendar")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Text(challenge.reason)
                .font(.caption)
                .foregroundStyle(.secondary)
                .italic()
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct DifficultyBadge: View {
    let difficulty: ChallengeDifficulty

    var body: some View {
        Text(difficulty.rawValue.capitalized)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: Capsule())
    }

    private var color: Color {
        switch difficulty {
        case .easy:   return .green
        case .medium: return .orange
        case .hard:   return .red
        }
    }
}

private struct RewardBadge: View {
    let reward: ChallengeReward

    var body: some View {
        Text(rewardText)
            .font(.subheadline.bold())
            .foregroundStyle(.green)
    }

    private var rewardText: String {
        if let pct = reward.valuePercent {
            return "+\(pct.formatted(.number.precision(.fractionLength(0...1))))%"
        }
        if let amount = reward.amount {
            return "+\(Int(amount.amount).formatted(.number.grouping(.automatic))) \(amount.currency.rawValue)"
        }
        return "Reward"
    }
}

extension CashbackItem.Category {
    var title: String {
        switch self {
        case .hotel:     return "Hotel"
        case .flight:    return "Flight"
        case .transport: return "Transport"
        case .activity:  return "Activities"
        case .insurance: return "Insurance"
        case .other:     return "Other"
        }
    }
}
