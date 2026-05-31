import SwiftUI

struct HotelRoomRow: View {
    let room: HotelRoom
    let isSelected: Bool
    let isRecommended: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .stroke(isSelected ? Color.green : Color(.separator), lineWidth: 2)
                    .frame(width: 20, height: 20)
                if isSelected {
                    Circle().fill(Color.green).frame(width: 10, height: 10)
                }
            }
            .padding(.top, 3)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(room.name).font(.subheadline.weight(.medium))
                    if isRecommended {
                        Text("Recommended")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.green.opacity(0.12), in: Capsule())
                    }
                }
                HStack(spacing: 8) {
                    if let sqm = room.areaSqm { RoomChip("\(Int(sqm)) m²") }
                    if let bed = room.bedType { RoomChip(bed.rawValue.capitalized) }
                    if room.breakfastIncluded == true { RoomChip("Breakfast") }
                    if room.refundable == true { RoomChip("Refundable") }
                }
                if !room.labels.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(room.labels, id: \.self) { l in RoomChip(l) }
                        }
                    }
                }
                if let tradeoff = room.tradeoffLabel {
                    Text(tradeoff).font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let desc = room.description {
                    Text(desc).font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 2) {
                Text(room.pricePerNight.displayString)
                    .font(.subheadline.weight(.bold))
                Text("/night").font(.caption2).foregroundStyle(.secondary)
                Text(room.totalPrice.displayString)
                    .font(.caption2).foregroundStyle(.secondary)
                Text("total").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.green.opacity(0.07) : Color(.tertiarySystemGroupedBackground))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.green.opacity(0.4) : Color.clear, lineWidth: 1.5)
                }
        )
        .animation(.smooth(duration: 0.2), value: isSelected)
    }
}
