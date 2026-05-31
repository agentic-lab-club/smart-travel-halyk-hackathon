import SwiftUI

struct TripEntryPreviewView: View {
    let recommendation: TripRecommendation

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(recommendation.destinationTitle)
                        .font(.largeTitle.bold())

                    Text(recommendation.mainReason)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 10) {
                    PriceBlock(title: "Estimated", value: recommendation.estimatedTotalCost.displayString)
                    PriceBlock(title: "Duration", value: "\(recommendation.durationDays) days")
                }
 
                if !recommendation.reasonLabels.isEmpty {
                    SectionHeader(title: "Why this trip", subtitle: "Highlights selected for you")
                    FlowLayout(items: recommendation.reasonLabels)
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Trip preview")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TripEntryPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TripEntryPreviewView(recommendation: MockTravelData.recommendations.recommendations[0])
        }
    }
}
