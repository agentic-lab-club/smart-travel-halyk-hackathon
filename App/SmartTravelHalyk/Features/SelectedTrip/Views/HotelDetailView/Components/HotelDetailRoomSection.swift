import SwiftUI

struct HotelDetailRoomSection: View {
    let full: HotelDetailsFull
    @Binding var selectedRoomId: String

    private var orderedRooms: [HotelRoom] {
        [full.roomOptions.downgradeRoomId, full.roomOptions.selectedRoomId, full.roomOptions.upgradeRoomId]
            .compactMap { id in full.rooms.first { $0.roomId == id } }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HotelSectionHeading("Room options")

            ForEach(orderedRooms) { room in
                HotelRoomRow(
                    room: room,
                    isSelected: room.roomId == selectedRoomId,
                    isRecommended: room.roomId == full.roomOptions.selectedRoomId
                )
                .onTapGesture { withAnimation(.smooth(duration: 0.2)) { selectedRoomId = room.roomId } }
            }

            Text("✦ \(full.roomOptions.selectedReason)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
