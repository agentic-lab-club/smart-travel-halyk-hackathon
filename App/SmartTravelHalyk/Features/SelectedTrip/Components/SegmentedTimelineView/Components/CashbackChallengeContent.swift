import SwiftUI

struct CashbackChallengeContent: View {
    let challenge: TravelChallenge
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ProgressView(value: challenge.progress.current, total: challenge.progress.target).tint(.green).padding(.top, 4)
            HStack {
                Text("\(Int(challenge.progress.current))/\(Int(challenge.progress.target)) \(challenge.progress.unit.rawValue)")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                if let pct = challenge.reward.valuePercent {
                    Text("+\(pct.formatted(.number.precision(.fractionLength(0 ... 1))))% cashback")
                        .font(.caption.weight(.semibold)).foregroundStyle(.green)
                }
            }
            if let d = challenge.deadline { DetailRow(icon: "calendar", label: "Deadline: \(d)") }
        }
    }
}
