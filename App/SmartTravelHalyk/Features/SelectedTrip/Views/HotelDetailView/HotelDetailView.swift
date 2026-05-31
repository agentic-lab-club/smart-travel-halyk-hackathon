import SwiftUI

struct HotelDetailView: View {
    let hotel: HotelDetails
    let full: HotelDetailsFull
    @Binding var selectedRoomId: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HotelDetailHeroSection(full: full)

                VStack(alignment: .leading, spacing: 16) {
                    HotelDetailHeaderSection(hotel: hotel, full: full)
                    HotelDetailRoomSection(full: full, selectedRoomId: $selectedRoomId)
                    HotelDetailReviewsSection(full: full)
                    HotelDetailLocationSection(hotel: hotel, full: full)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(full.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HotelDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HotelDetailView(
                hotel: MockTravelData.tripDetails.segments
                    .compactMap { seg -> HotelDetails? in
                        if case .hotel(let h) = seg.details { return h }
                        return nil
                    }.first!,
                full: MockTravelData.hotelDetailsFull,
                selectedRoomId: .constant(MockTravelData.hotelDetailsFull.selectedRoomId)
            )
        }
    }
}
