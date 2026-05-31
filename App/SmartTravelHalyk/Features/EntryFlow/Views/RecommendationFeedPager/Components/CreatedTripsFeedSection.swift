import SwiftUI

struct CreatedTripsFeedSection: View {
    let trips: [TripDetailsResponse]
    let apiClient: TravelAPIClient

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.green)
                Text("Created trips")
                    .font(.headline)
                Text("\(trips.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
            }

            ForEach(trips.reversed()) { trip in
                NavigationLink {
                    SelectedTripView(trip: trip, apiClient: apiClient)
                } label: {
                    CreatedTripCard(trip: trip)
                        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 4)
    }
}
