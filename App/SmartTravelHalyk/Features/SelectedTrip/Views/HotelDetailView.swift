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

// MARK: - Hero

private struct HotelDetailHeroSection: View {
    let full: HotelDetailsFull

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: URL(string: full.mainImageUrl ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Rectangle().fill(Color(.tertiarySystemGroupedBackground))
                        .overlay {
                            Image(systemName: "bed.double.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary.opacity(0.4))
                        }
                }
            }
            .frame(height: 240)
            .clipped()

            LinearGradient(
                colors: [.black.opacity(0.55), .clear],
                startPoint: .bottom,
                endPoint: .center
            )

            VStack(alignment: .leading, spacing: 4) {
                if let stars = full.stars {
                    HStack(spacing: 2) {
                        ForEach(0..<stars, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                        }
                    }
                }
                Text(full.name)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                if let district = full.district {
                    Label(district, systemImage: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .padding(14)
        }
    }
}

// MARK: - Header + rating

private struct HotelDetailHeaderSection: View {
    let hotel: HotelDetails
    let full: HotelDetailsFull

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Overall rating")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(String(format: "%.1f", full.rating.overall))
                            .font(.largeTitle.bold())
                            .foregroundStyle(.green)
                        Text("/ \(Int(full.rating.scale))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if let label = hotel.ratingLabel {
                        Text(label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text("\(full.rating.reviewCount.formatted()) reviews")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    ForEach(full.sourceRatings, id: \.source) { r in
                        HStack(spacing: 6) {
                            Text(r.source.rawValue)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.1f", r.rating))
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.primary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(.secondarySystemGroupedBackground), in: Capsule())
                    }
                }
            }

            Text(full.reviewSummary.shortSummary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: 12) {
                ReviewTagsColumn(
                    icon: "hand.thumbsup.fill",
                    color: .green,
                    tags: full.reviewSummary.bestFor,
                    label: "Best for"
                )
                ReviewTagsColumn(
                    icon: "hand.thumbsdown.fill",
                    color: .secondary,
                    tags: full.reviewSummary.notIdealFor,
                    label: "Not ideal for"
                )
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct ReviewTagsColumn: View {
    let icon: String
    let color: Color
    let tags: [String]
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Room options

private struct HotelDetailRoomSection: View {
    let full: HotelDetailsFull
    @Binding var selectedRoomId: String

    private var orderedRooms: [HotelRoom] {
        [full.roomOptions.downgradeRoomId, full.roomOptions.selectedRoomId, full.roomOptions.upgradeRoomId]
            .compactMap { id in full.rooms.first { $0.roomId == id } }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading("Room options")

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

private struct HotelRoomRow: View {
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

private struct RoomChip: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Color(.systemGroupedBackground), in: Capsule())
    }
}

// MARK: - Reviews

private struct HotelDetailReviewsSection: View {
    let full: HotelDetailsFull
    @State private var expandedSource: HotelReviewSource?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading("Guest reviews")

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
            .padding(12)
            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

            ForEach(full.reviewsBySource, id: \.source) { group in
                ReviewSourceGroup(group: group, isExpanded: expandedSource == group.source) {
                    withAnimation(.smooth(duration: 0.25)) {
                        expandedSource = expandedSource == group.source ? nil : group.source
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct ReviewSourceGroup: View {
    let group: HotelReviewsSourceGroup
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onToggle) {
                HStack {
                    Text(group.source.rawValue)
                        .font(.subheadline.weight(.semibold))
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f", group.averageRating))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.green)
                    Text("/ \(Int(group.scale))")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("(\(group.totalReviews))")
                        .font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                ForEach(group.reviews, id: \.reviewId) { review in
                    IndividualReviewCard(review: review)
                }
            }
        }
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct IndividualReviewCard: View {
    let review: HotelReview

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(review.authorName ?? "Guest")
                    .font(.caption.weight(.semibold))
                Spacer()
                HStack(spacing: 3) {
                    Text(String(format: "%.1f", review.rating))
                        .font(.caption.weight(.bold)).foregroundStyle(.green)
                    Text("/ \(Int(review.scale))").font(.caption2).foregroundStyle(.secondary)
                }
                Text("·").foregroundStyle(.secondary)
                if let date = review.date { Text(date).font(.caption2).foregroundStyle(.secondary) }
            }
            if let title = review.title {
                Text(title).font(.caption.weight(.medium))
            }
            Text(review.text).font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let pros = review.pros, !pros.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill").font(.caption2).foregroundStyle(.green)
                    Text(pros.joined(separator: " · ")).font(.caption2).foregroundStyle(.secondary)
                }
            }
            if let cons = review.cons, !cons.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "minus.circle.fill").font(.caption2).foregroundStyle(.secondary)
                    Text(cons.joined(separator: " · ")).font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Location

private struct HotelDetailLocationSection: View {
    let hotel: HotelDetails
    let full: HotelDetailsFull

    private var loc: HotelLocationInfo { full.locationInfo }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading("Location")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                if let km = loc.distanceToAirportKm {
                    LocationTile(icon: "airplane", label: "Airport", value: String(format: "%.1f km", km))
                }
                if let taxi = loc.taxiFromAirport {
                    LocationTile(icon: "car.fill", label: "Taxi from airport", value: taxi.displayString)
                }
                if let km = loc.distanceToMainClusterKm {
                    LocationTile(icon: "figure.walk", label: "To main cluster", value: String(format: "%.1f km", km))
                }
                if let km = loc.distanceToBeachKm {
                    LocationTile(icon: "water.waves", label: "To beach", value: String(format: "%.1f km", km))
                }
                if let taxi = loc.averageTaxiToActivities {
                    LocationTile(icon: "car.circle.fill", label: "Avg taxi", value: taxi.displayString)
                }
                if let count = loc.walkablePlacesCount {
                    LocationTile(icon: "map.fill", label: "Walkable places", value: "\(count)")
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                SectionSubheading("Scores")
                HStack(spacing: 10) {
                    if let score = loc.locationScore {
                        ScoreBadge(label: "Location", score: score, scale: 10)
                    }
                    if let score = loc.priceScore {
                        ScoreBadge(label: "Price", score: score, scale: 10)
                    }
                    if let score = loc.convenienceScore {
                        ScoreBadge(label: "Convenience", score: score, scale: 10)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct LocationTile: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.green)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption2).foregroundStyle(.secondary)
                Text(value).font(.caption.weight(.bold))
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct ScoreBadge: View {
    let label: String
    let score: Double
    let scale: Double

    var body: some View {
        VStack(spacing: 3) {
            Text(String(format: "%.1f", score))
                .font(.title3.bold())
                .foregroundStyle(scoreColor)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
    }

    private var scoreColor: Color {
        score >= 8.5 ? .green : score >= 7.0 ? .orange : .red
    }
}

// MARK: - Shared helpers

private struct SectionHeading: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text).font(.headline)
    }
}

private struct SectionSubheading: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text).font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
    }
}

// MARK: - Preview

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
