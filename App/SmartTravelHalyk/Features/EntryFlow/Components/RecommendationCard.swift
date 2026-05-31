import SwiftUI
import VariableBlur

struct RecommendationCard: View {
    let recommendation: TripRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading) {
                Text(recommendation.destinationTitle)
                    .font(.title)
                    .bold()
                    .foregroundStyle(.white)

                Text(recommendation.destinationName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background {
                VariableBlurView(maxBlurRadius: 10, direction: .blurredTopClearBottom)
            }

            Spacer()

            VStack(alignment: .leading) {
                Text(recommendation.durationDays == 1 ? "1 day" : "\(recommendation.durationDays) days")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(.white)

                Text(recommendation.estimatedTotalCost.displayString)
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background {
                VariableBlurView(maxBlurRadius: 4, direction: .blurredBottomClearTop)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 450)
        .background {
            Image("ExampleTripImage")
                .scaledToFill()
                .clipped()
        }
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct RecommendationCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            RecommendationCard(recommendation: MockTravelData.recommendations.recommendations[0])
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
