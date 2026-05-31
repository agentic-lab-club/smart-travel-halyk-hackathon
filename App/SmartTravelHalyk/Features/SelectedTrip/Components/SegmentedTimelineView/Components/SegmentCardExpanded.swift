import SwiftUI

struct SegmentCardExpanded: View {
    let segment: ItinerarySegment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let description = segment.description {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }

            switch segment.details {
            case .arrival(let d): ArrivalDetailContent(details: d)
            case .departure(let d): DepartureDetailContent(details: d)
            case .transfer(let d): TransferDetailContent(details: d)
            case .hotel(let d): HotelCompactContent(details: d)
            case .dayItinerary(let d): DayItineraryContent(details: d)
            case .cashbackChallenge(let d): CashbackChallengeContent(challenge: d.challenge)
            default: EmptyView()
            }
        }
    }
}
