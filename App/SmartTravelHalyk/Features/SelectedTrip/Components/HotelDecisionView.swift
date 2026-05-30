import SwiftUI

struct HotelDecisionView: View {
    let hotel: HotelDetails
    let fullHotel: HotelDetailsFull?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HotelHeaderCard(hotel: hotel, fullHotel: fullHotel)

            if let full = fullHotel {
                HotelRoomOptionsView(full: full)
                HotelReviewsView(full: full)
            }

            if let dist = hotel.distanceToMainClusterKm {
                HotelLocationCard(hotel: hotel, distanceKm: dist)
            }
        }
    }
}

private struct HotelHeaderCard: View {
    let hotel: HotelDetails
    let fullHotel: HotelDetailsFull?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(hotel.name)
                        .font(.headline)

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

                if let rating = hotel.rating {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.1f", rating))
                            .font(.title2.bold())
                            .foregroundStyle(.green)
                        if let label = hotel.ratingLabel {
                            Text(label)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if let summary = hotel.reviewShortSummary {
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let full = fullHotel {
                HotelSourceRatingsRow(ratings: full.sourceRatings)
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(hotel.pricePerNight.displayString)
                        .font(.subheadline.weight(.bold))
                    Text("per night · \(hotel.nights) nights")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(Int(hotel.pricePerNight.amount * Double(hotel.nights)).formatted(.number.grouping(.automatic))) \(hotel.pricePerNight.currency.rawValue)")
                    .font(.subheadline.weight(.semibold))
            }

            Text(hotel.reason)
                .font(.caption)
                .foregroundStyle(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct HotelSourceRatingsRow: View {
    let ratings: [HotelSourceRating]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ratings, id: \.source) { r in
                    HStack(spacing: 4) {
                        Text(r.source.rawValue)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.1f", r.rating))
                            .font(.caption.weight(.bold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
                }
            }
        }
    }
}

private struct HotelRoomOptionsView: View {
    let full: HotelDetailsFull
    @State private var selectedRoomId: String

    init(full: HotelDetailsFull) {
        self.full = full
        _selectedRoomId = State(initialValue: full.selectedRoomId)
    }

    private var orderedRooms: [HotelRoom] {
        [full.roomOptions.downgradeRoomId, full.roomOptions.selectedRoomId, full.roomOptions.upgradeRoomId]
            .compactMap { id in full.rooms.first { $0.roomId == id } }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Room options")
                .font(.subheadline.weight(.semibold))

            ForEach(orderedRooms) { room in
                RoomOptionRow(
                    room: room,
                    isSelected: room.roomId == selectedRoomId,
                    isRecommended: room.roomId == full.roomOptions.selectedRoomId
                )
                .onTapGesture { selectedRoomId = room.roomId }
            }

            Text("✦ \(full.roomOptions.selectedReason)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct RoomOptionRow: View {
    let room: HotelRoom
    let isSelected: Bool
    let isRecommended: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                Circle()
                    .stroke(isSelected ? Color.green : Color(.separator), lineWidth: 2)
                    .frame(width: 20, height: 20)
                if isSelected {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(room.name)
                        .font(.subheadline.weight(.medium))
                    if isRecommended {
                        Text("Recommended")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.12), in: Capsule())
                    }
                }

                HStack(spacing: 8) {
                    if let sqm = room.areaSqm {
                        Text("\(sqm) m²").font(.caption).foregroundStyle(.secondary)
                    }
                    if let bed = room.bedType {
                        Text(bed.rawValue.capitalized).font(.caption).foregroundStyle(.secondary)
                    }
                    if room.breakfastIncluded == true {
                        Text("Breakfast").font(.caption).foregroundStyle(.secondary)
                    }
                }

                if let tradeoff = room.tradeoffLabel {
                    Text(tradeoff)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(room.pricePerNight.displayString)
                    .font(.subheadline.weight(.bold))
                Text("/night")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.green.opacity(0.07) : Color(.tertiarySystemGroupedBackground))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.green.opacity(0.4) : Color.clear, lineWidth: 1.5)
                }
        )
        .animation(.smooth(duration: 0.2), value: isSelected)
    }
}

private struct HotelReviewsView: View {
    let full: HotelDetailsFull

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What guests say")
                .font(.subheadline.weight(.semibold))

            VStack(alignment: .leading, spacing: 6) {
                ForEach(full.reviewSummary.positivePoints, id: \.self) { point in
                    HStack(spacing: 6) {
                        Image(systemName: "hand.thumbsup.fill").font(.caption2).foregroundStyle(.green)
                        Text(point).font(.caption)
                    }
                }
                ForEach(full.reviewSummary.negativePoints, id: \.self) { point in
                    HStack(spacing: 6) {
                        Image(systemName: "hand.thumbsdown.fill").font(.caption2).foregroundStyle(.secondary)
                        Text(point).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }

            if let review = full.reviewsBySource.first?.reviews.first {
                ReviewCard(review: review, source: full.reviewsBySource.first?.source.rawValue ?? "")
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct ReviewCard: View {
    let review: HotelReview
    let source: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(review.authorName ?? "Guest").font(.caption.weight(.semibold))
                Spacer()
                Text(String(format: "%.1f", review.rating)).font(.caption.weight(.bold)).foregroundStyle(.green)
                Text("·").foregroundStyle(.secondary)
                Text(source).font(.caption2).foregroundStyle(.secondary)
            }
            if let title = review.title {
                Text(title).font(.caption.weight(.medium))
            }
            Text(review.text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .padding(10)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct HotelLocationCard: View {
    let hotel: HotelDetails
    let distanceKm: Double

    var body: some View {
        HStack(spacing: 16) {
            LocationStat(icon: "figure.walk",      label: "To activities", value: String(format: "%.1f km", distanceKm))
            if let taxi = hotel.averageTaxiToActivities {
                LocationStat(icon: "car.fill",     label: "Avg taxi",      value: taxi.displayString)
            }
            if let loc = hotel.locationScore {
                LocationStat(icon: "mappin.circle.fill", label: "Location", value: String(format: "%.1f", loc))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct LocationStat: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Image(systemName: icon).font(.subheadline.weight(.medium)).foregroundStyle(.green)
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.caption.weight(.bold))
        }
    }
}
