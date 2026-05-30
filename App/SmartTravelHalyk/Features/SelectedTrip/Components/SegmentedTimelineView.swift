import SwiftUI

struct SegmentedTimelineView: View {
    let viewModel: SelectedTripViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(viewModel.trip.segments.enumerated()), id: \.element.segmentId) { index, segment in
                TimelineSegmentRow(
                    segment: segment,
                    isSelected: viewModel.selectedSegmentId == segment.segmentId,
                    isLast: index == viewModel.trip.segments.count - 1,
                    onTap: { viewModel.tapSegment(segment.segmentId) }
                )
                .id(segment.segmentId)
            }
        }
    }
}

private struct TimelineSegmentRow: View {
    let segment: ItinerarySegment
    let isSelected: Bool
    let isLast: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            TimelineIndicator(segment: segment, isSelected: isSelected, isLast: isLast)

            SegmentCard(segment: segment, isSelected: isSelected)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 12)
                .onTapGesture(perform: onTap)
        }
    }
}

private struct TimelineIndicator: View {
    let segment: ItinerarySegment
    let isSelected: Bool
    let isLast: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.green : Color(.tertiarySystemGroupedBackground))
                    .frame(width: 36, height: 36)
                    .overlay {
                        Circle().stroke(isSelected ? Color.green : Color(.separator), lineWidth: 1.5)
                    }

                Image(systemName: segment.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : .secondary)
            }
            .animation(.smooth(duration: 0.2), value: isSelected)

            if !isLast {
                Rectangle()
                    .fill(Color(.separator))
                    .frame(width: 1.5)
                    .frame(minHeight: 28)
            }
        }
    }
}

struct SegmentCard: View {
    let segment: ItinerarySegment
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SegmentCardHeader(segment: segment)

            if isSelected {
                SegmentCardExpanded(segment: segment)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.green.opacity(0.6) : Color.clear, lineWidth: 1.5)
                }
        )
        .animation(.smooth(duration: 0.25), value: isSelected)
    }
}

private struct SegmentCardHeader: View {
    let segment: ItinerarySegment

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(segment.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Day \(segment.dayNumber)")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)

                    if let price = segment.price {
                        Text(price.displayString)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.primary)
                    }
                }
            }

            if let start = segment.startTime {
                Text(timeLabel(start: start, end: segment.endTime))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !segment.labels.isEmpty {
                LabelsFlow(labels: segment.labels)
            }
        }
    }

    private func timeLabel(start: String, end: String?) -> String {
        guard let end else { return start }
        return "\(start) – \(end)"
    }
}

private struct SegmentCardExpanded: View {
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
            case .arrival(let d):
                ArrivalDetailContent(details: d)
            case .transfer(let d):
                TransferDetailContent(details: d)
            case .hotel(let d):
                HotelCompactContent(details: d)
            case .dayItinerary(let d):
                DayItineraryContent(details: d)
            case .cashbackChallenge(let d):
                CashbackChallengeContent(challenge: d.challenge)
            default:
                EmptyView()
            }
        }
    }
}

// MARK: - Segment detail sub-views

private struct ArrivalDetailContent: View {
    let details: ArrivalDetails

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            DetailRow(icon: "airplane",        label: "\(details.flight.fromAirport) → \(details.flight.toAirport)")
            if let airline = details.flight.airline {
                DetailRow(icon: "tag",         label: "\(airline) · \(details.flight.flightNumber ?? "")")
            }
            DetailRow(icon: "clock",           label: "\(details.flight.departureTime) – \(details.flight.arrivalTime) · \(details.flight.durationMinutes / 60)h \(details.flight.durationMinutes % 60)m")
            if details.flight.stops == 0 {
                DetailRow(icon: "checkmark.circle", label: "Direct flight")
            } else {
                DetailRow(icon: "arrow.triangle.branch", label: "\(details.flight.stops) stop(s)")
            }
        }
        .padding(.top, 4)
    }
}

private struct TransferDetailContent: View {
    let details: TransferDetails

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            DetailRow(icon: "location.fill", label: "\(details.from) → \(details.to)")
            DetailRow(icon: "ruler",         label: String(format: "%.0f km · %d min", details.distanceKm, details.durationMinutes))
            if let taxi = details.taxiEstimate {
                DetailRow(icon: "car.fill",  label: "Taxi ≈ \(taxi.displayString)")
            }
            if let pt = details.publicTransportEstimate {
                let ptMoney = Money(amount: pt.amount, currency: pt.currency)
                DetailRow(icon: "bus.fill",  label: "Public transport ≈ \(ptMoney.displayString) · \(pt.durationMinutes) min")
            }
            DetailRow(icon: "sparkles",      label: details.reason)
        }
        .padding(.top, 4)
    }
}

private struct HotelCompactContent: View {
    let details: HotelDetails

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let district = details.district {
                DetailRow(icon: "mappin",          label: district)
            }
            if let room = details.selectedRoomName {
                DetailRow(icon: "bed.double.fill", label: room)
            }
            DetailRow(icon: "moon.fill",            label: "\(details.nights) nights · \(details.pricePerNight.displayString)/night")
            if let down = details.downgradeLabel {
                DetailRow(icon: "arrow.down.circle", label: down)
            }
            if let up = details.upgradeLabel {
                DetailRow(icon: "arrow.up.circle",   label: up)
            }
        }
        .padding(.top, 4)
    }
}

private struct DayItineraryContent: View {
    let details: DayItineraryDetails

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let weather = details.weather {
                WeatherBadge(weather: weather)
                    .padding(.top, 4)
            }

            ForEach(details.activities) { activity in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: iconForActivityType(activity.type))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.green)
                        .frame(width: 16)

                    VStack(alignment: .leading, spacing: 1) {
                        HStack {
                            Text(activity.title)
                                .font(.caption.weight(.medium))
                            if let time = activity.startTime {
                                Text(time)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if let price = activity.price {
                            Text(price.displayString)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func iconForActivityType(_ type: ActivityItem.ActivityType) -> String {
        switch type {
        case .attraction: return "binoculars.fill"
        case .event:      return "star.fill"
        case .restaurant: return "fork.knife"
        case .shopping:   return "bag.fill"
        case .freeTime:   return "sun.horizon.fill"
        }
    }
}

private struct CashbackChallengeContent: View {
    let challenge: TravelChallenge

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ProgressView(value: challenge.progress.current, total: challenge.progress.target)
                .tint(.green)
                .padding(.top, 4)

            HStack {
                Text("\(Int(challenge.progress.current))/\(Int(challenge.progress.target)) \(challenge.progress.unit.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if let pct = challenge.reward.valuePercent {
                    Text("+\(pct.formatted(.number.precision(.fractionLength(0...1))))% cashback")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                }
            }

            if let deadline = challenge.deadline {
                DetailRow(icon: "calendar", label: "Deadline: \(deadline)")
            }
        }
    }
}

// MARK: - Shared small views

private struct WeatherBadge: View {
    let weather: WeatherInfo

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: weatherIcon)
                .font(.caption.weight(.medium))
                .foregroundStyle(weatherColor)
            Text("\(weather.temperatureC)°C")
                .font(.caption.weight(.semibold))
            if let rain = weather.rainChancePercent, rain > 20 {
                Text("· Rain \(rain)%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(weatherColor.opacity(0.12), in: Capsule())
    }

    private var weatherIcon: String {
        switch weather.condition {
        case .sunny:   return "sun.max.fill"
        case .cloudy:  return "cloud.fill"
        case .rain:    return "cloud.rain.fill"
        case .snow:    return "snowflake"
        case .windy:   return "wind"
        case .unknown: return "questionmark.circle"
        }
    }

    private var weatherColor: Color {
        switch weather.condition {
        case .sunny:   return .orange
        case .cloudy:  return .gray
        case .rain:    return .blue
        case .snow:    return .cyan
        case .windy:   return .teal
        case .unknown: return .gray
        }
    }
}

private struct LabelsFlow: View {
    let labels: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(labels, id: \.self) { label in
                    Text(label)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
                }
            }
        }
    }
}

private struct DetailRow: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: icon)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.green)
                .frame(width: 14)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
