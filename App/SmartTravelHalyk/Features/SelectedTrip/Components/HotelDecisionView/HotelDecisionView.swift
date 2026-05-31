import SwiftUI

struct HotelDecisionView: View {
    let hotel: HotelDetails
    let fullHotel: HotelDetailsFull?
    @Binding var selectedRoomId: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HotelSummaryCard(hotel: hotel, fullHotel: fullHotel, selectedRoomId: $selectedRoomId)
        }
    }
}


