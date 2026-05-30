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
 
                SectionHeader(
                    title: "Next screen",
                    subtitle: "This card is ready to open the segmented timeline and smart map flow."
                )

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(MockTravelData.tripDetails.segments.prefix(4)) { segment in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: segment.icon)
                                .font(.headline)
                                .foregroundStyle(.green)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(segment.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(segment.labels.joined(separator: " - "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 8))
                    }
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
