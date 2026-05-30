import SwiftUI

struct RecommendationCard: View {
    let recommendation: TripRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                DestinationBadge(countryCode: recommendation.countryCode)

                VStack(alignment: .leading, spacing: 6) {
                    Text(recommendation.destinationTitle)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(recommendation.mainReason)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }

            HStack(spacing: 10) {
                PriceBlock(title: "Budget", value: recommendation.estimatedTotalCost.displayString)

                if let cashback = recommendation.cashbackEstimate {
                    PriceBlock(title: "Cashback", value: cashback.displayString)
                }

                PriceBlock(title: "Days", value: "\(recommendation.durationDays)")
            }

            FlowLayout(items: recommendation.reasonLabels)
        }
        .padding(16)
        .background(.background, in: .rect(cornerRadius: 8))
    }
}
