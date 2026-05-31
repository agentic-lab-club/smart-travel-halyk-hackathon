import SwiftUI

struct HotelSummaryCard: View {
    let hotel: HotelDetails
    let fullHotel: HotelDetailsFull?
    @Binding var selectedRoomId: String

    var body: some View {
        NavigationLink {
            if let full = fullHotel {
                HotelDetailView(hotel: hotel, full: full, selectedRoomId: $selectedRoomId)
            }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(hotel.name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        HStack {
                            if let rating = hotel.rating {
                                Text(String(format: "%.1f", rating))
                                    .font(.title2.bold())
                                    .foregroundStyle(.green)
                            }

                            if let district = hotel.district {
                                Text(district)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }

                if let summary = hotel.reviewShortSummary {
                    Text(summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(2)
                }

                Divider()

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(hotel.pricePerNight.displayString)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.primary)
                        Text("per night · \(hotel.nights) nights")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        let total = Int(hotel.pricePerNight.amount * Double(hotel.nights))
                        Text("\(total.formatted(.number.grouping(.automatic))) \(hotel.pricePerNight.currency.rawValue)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text("total")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(hotel.reason)
                    .font(.caption)
                    .foregroundStyle(.green)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(fullHotel == nil)
    }
}

#Preview {
    let hotel = MockTravelData.tripDetails.segments
        .compactMap { seg -> HotelDetails? in
            if case .hotel(let h) = seg.details { return h }
            return nil
        }.first!

    NavigationStack {
        HotelSummaryCard(
            hotel: hotel,
            fullHotel: MockTravelData.hotelDetailsFull,
            selectedRoomId: .constant(hotel.selectedRoomId ?? "")
        )
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
