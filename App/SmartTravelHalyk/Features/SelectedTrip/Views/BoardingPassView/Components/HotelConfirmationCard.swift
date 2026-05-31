import SwiftUI

struct HotelConfirmationCard: View {
    let info: HotelConfirmationInfo

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("HOTEL BOOKING")
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(.white.opacity(0.75))
                    Text(info.hotelName)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                }
                Spacer()
                StarRating(count: info.stars)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.orange.gradient)

            // Body
            VStack(spacing: 16) {
                HStack(spacing: 0) {
                    dateCell(label: "CHECK-IN", value: info.checkIn)
                    Image(systemName: "arrow.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: 32)
                    dateCell(label: "CHECK-OUT", value: info.checkOut)
                }

                HStack(spacing: 0) {
                    detailCell(label: "NIGHTS", value: "\(info.nights)")
                    Divider().frame(height: 32)
                    detailCell(label: "ROOM", value: info.roomType, wide: true)
                }
                .padding(.vertical, 10)
                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(.orange)
                    Text(info.address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)

            // Perforation
            perforationDivider

            // Footer
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("GUEST")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(info.passengerName.uppercased())
                            .font(.subheadline.weight(.bold))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("CONFIRMATION")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(info.confirmationNumber)
                            .font(.subheadline.weight(.bold).monospaced())
                    }
                }
                MockQRCode(seed: info.confirmationNumber.hashValue)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .frame(maxWidth: .infinity)
            }
            .padding(20)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    }

    private var perforationDivider: some View {
        HStack(spacing: 0) {
            Circle().fill(Color(.systemGroupedBackground)).frame(width: 24, height: 24).offset(x: -12)
            GeometryReader { geo in
                Path { p in
                    p.move(to: CGPoint(x: 0, y: geo.size.height / 2))
                    p.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 2))
                }
                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                .foregroundStyle(Color(.separator))
            }
            .frame(height: 1).padding(.horizontal, 4)
            Circle().fill(Color(.systemGroupedBackground)).frame(width: 24, height: 24).offset(x: 12)
        }
    }

    private func dateCell(label: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(formattedDate(value))
                .font(.subheadline.weight(.bold))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private func detailCell(label: String, value: String, wide: Bool = false) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(wide ? .caption.weight(.bold) : .subheadline.weight(.bold))
                .minimumScaleFactor(0.6)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(minWidth: wide ? nil : 60, maxWidth: wide ? .infinity : nil)
        .padding(.horizontal, wide ? 8 : 0)
    }

    private func formattedDate(_ iso: String) -> String {
        guard let d = iso.asDate else { return iso }
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none
        return f.string(from: d)
    }
}

#Preview("Hotel Card") {
    ScrollView {
        HotelConfirmationCard(info: HotelConfirmationInfo(
            confirmationNumber: "HB-73921",
            passengerName: "Artem Bagin",
            hotelName: "Address Downtown Dubai",
            stars: 5,
            checkIn: "2026-06-15",
            checkOut: "2026-06-20",
            nights: 5,
            roomType: "Deluxe Room with Burj Khalifa View",
            address: "Downtown Dubai, Sheikh Mohammed bin Rashid Blvd"
        ))
        .padding(20)
    }
    .background(Color(.systemGroupedBackground))
}
