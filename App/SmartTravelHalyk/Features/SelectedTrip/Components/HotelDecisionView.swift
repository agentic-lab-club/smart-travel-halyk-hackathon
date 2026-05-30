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

// MARK: - Compact summary card

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

                        if let district = hotel.district {
                            Label(district, systemImage: "mappin.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        if let stars = hotel.stars {
                            HStack(spacing: 2) {
                                ForEach(0..<stars, id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        if let rating = hotel.rating {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(String(format: "%.1f", rating))
                                    .font(.title2.bold())
                                    .foregroundStyle(.green)
                                if let label = hotel.ratingLabel {
                                    Text(label)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.trailing)
                                }
                            }
                        }

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
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

                if !selectedRoomId.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                        Text("Room selected")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                        Spacer()
                        if fullHotel != nil {
                            Text("Change room")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Image(systemName: "arrow.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                } else if fullHotel != nil {
                    HStack {
                        Spacer()
                        Text("View rooms, reviews & location")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                    }
                }
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(fullHotel == nil)
    }
}
