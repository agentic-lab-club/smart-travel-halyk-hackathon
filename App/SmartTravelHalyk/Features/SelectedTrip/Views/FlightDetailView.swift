import SwiftUI

struct FlightDetailView: View {
    let flight: FlightInfo
    let segmentTitle: String
    let directionTitle: String
    let directionIcon: String
    let adultCount: Int
    let childCount: Int
    let onClose: () -> Void

    @State private var selectedClass: FlightInfo.CabinClass
    @State private var activePassenger = 0
    @State private var selections: [Int: String] = [:]

    private var peopleCount: Int { adultCount + childCount }

    private var travelers: [Traveler] {
        (0..<adultCount).map { Traveler(index: $0, kind: .adult, number: $0 + 1) } +
        (0..<childCount).map { Traveler(index: adultCount + $0, kind: .child, number: $0 + 1) }
    }

    private var classOptions: [PlaneClassOption] { MockTravelData.planeClassOptions }
    private var allSeats: [PlaneSeat] { MockTravelData.planeSeatMap }

    private var currentOption: PlaneClassOption {
        classOptions.first { $0.id == selectedClass } ?? classOptions[0]
    }

    private var totalPrice: Money {
        currentOption.totalPrice(adults: adultCount, children: childCount)
    }

    private var summaryLabel: String {
        let ids = travelers.compactMap { selections[$0.index] }
        let parts = [
            adultCount > 0 ? "\(adultCount) adult\(adultCount > 1 ? "s" : "")" : nil,
            childCount > 0 ? "\(childCount) child\(childCount > 1 ? "ren" : "")" : nil
        ].compactMap { $0 }.joined(separator: ", ")
        if ids.isEmpty { return "\(currentOption.displayName) · \(parts)" }
        return ids.joined(separator: ", ") + " · \(currentOption.displayName)"
    }

    init(
        flight: FlightInfo,
        segmentTitle: String,
        directionTitle: String,
        directionIcon: String,
        adultCount: Int,
        childCount: Int,
        onClose: @escaping () -> Void
    ) {
        self.flight = flight
        self.segmentTitle = segmentTitle
        self.directionTitle = directionTitle
        self.directionIcon = directionIcon
        self.adultCount = adultCount
        self.childCount = childCount
        self.onClose = onClose
        _selectedClass = State(initialValue: flight.cabinClass)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            FDColor.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    hero
                    VStack(alignment: .leading, spacing: 24) {
                        classSection
                        if peopleCount > 1 { passengerSection }
                        seatMapSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 128)
                }
            }
            .ignoresSafeArea(edges: .top)

            bottomBar
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Hero

    private var hero: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.10, blue: 0.22), FDColor.bg],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 270)

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Button("Close", action: onClose)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.white)
                    Spacer()
                    Label(directionTitle, systemImage: directionIcon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.55))
                }
                .padding(.horizontal, 20)
                .padding(.top, 64)

                Spacer()

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(FlightDisplay.time(flight.departureTime))
                            .font(.system(size: 40, weight: .bold))
                            .monospacedDigit()
                        Text(flight.fromAirport)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.65))
                        Text(FlightDisplay.shortDate(flight.departureTime))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                    }

                    Spacer()

                    VStack(spacing: 6) {
                        HStack(spacing: 0) {
                            Circle().fill(Color.white.opacity(0.35)).frame(width: 5, height: 5)
                            Rectangle().fill(Color.white.opacity(0.2)).frame(height: 1)
                            Image(systemName: "airplane")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.75))
                                .padding(.horizontal, 4)
                            Rectangle().fill(Color.white.opacity(0.2)).frame(height: 1)
                            Circle().fill(Color.white.opacity(0.35)).frame(width: 5, height: 5)
                        }
                        Text(FlightDisplay.duration(flight.durationMinutes))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    .padding(.top, 12)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 3) {
                        Text(FlightDisplay.time(flight.arrivalTime))
                            .font(.system(size: 40, weight: .bold))
                            .monospacedDigit()
                        Text(flight.toAirport)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.65))
                        Text(FlightDisplay.shortDate(flight.arrivalTime))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 20)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        if let airline = flight.airline { FDChip(airline) }
                        if let number = flight.flightNumber { FDChip(number) }
                        FDChip(flight.stops == 0 ? "Direct" : "\(flight.stops) stop(s)")
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
            .frame(height: 270)
        }
    }

    // MARK: - Class section

    private var classSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            FDSectionTitle("Select class")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(classOptions) { option in
                        ClassOptionCard(
                            option: option,
                            adultCount: adultCount,
                            childCount: childCount,
                            isSelected: selectedClass == option.id
                        ) {
                            withAnimation(.smooth(duration: 0.25)) {
                                selectedClass = option.id
                                selections = [:]
                            }
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
            .padding(.horizontal, -20)
            .safeAreaPadding(.horizontal, 20)
        }
    }

    // MARK: - Passenger section

    private var passengerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            FDSectionTitle("Passengers")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(travelers) { traveler in
                        PassengerTab(
                            traveler: traveler,
                            isActive: activePassenger == traveler.index,
                            seatId: selections[traveler.index]
                        ) {
                            withAnimation(.smooth(duration: 0.2)) { activePassenger = traveler.index }
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
            .padding(.horizontal, -20)
            .safeAreaPadding(.horizontal, 20)
        }
    }

    // MARK: - Seat map section

    private var seatMapSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            FDSectionTitle("Choose a seat")
            legend
            seatMap
            classFeaturesCard
        }
    }

    private var legend: some View {
        HStack(spacing: 14) {
            FDLegendItem(color: Color.white.opacity(0.15), label: "Available")
            FDLegendItem(color: Color.white.opacity(0.07), label: "Taken")
            FDLegendItem(color: .green, label: "Yours")
            if peopleCount > 1 {
                FDLegendItem(color: Color(red: 0.35, green: 0.55, blue: 1.0), label: "Other")
            }
        }
        .font(.caption2)
        .foregroundStyle(.white.opacity(0.55))
    }

    private var seatMap: some View {
        let isFirst = selectedClass == .first
        let filteredSeats = allSeats.filter { $0.cabinClass == selectedClass }
        let rowNumbers = Array(Set(filteredSeats.map { $0.row })).sorted()

        return VStack(spacing: 0) {
            SeatColumnHeaders(isFirstClass: isFirst)
                .padding(.bottom, 10)

            ForEach(rowNumbers, id: \.self) { row in
                let rowSeats = filteredSeats.filter { $0.row == row }
                let isExit = rowSeats.first?.isExitRow ?? false

                VStack(spacing: 0) {
                    if isExit {
                        ExitRowDivider()
                    }
                    SeatRowView(
                        rowNumber: row,
                        seats: rowSeats,
                        isFirstClass: isFirst,
                        activePassenger: activePassenger,
                        selections: selections,
                        onTap: handleSeatTap
                    )
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 18))
    }

    private var classFeaturesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(currentOption.displayName + " class includes")
                .font(.subheadline.weight(.semibold))

            ForEach(currentOption.features, id: \.self) { feature in
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.green)
                        .frame(width: 16)
                    Text(feature)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [FDColor.bg.opacity(0), FDColor.bg],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 36)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(totalPrice.displayString)
                        .font(.title3.weight(.bold))
                    Text(summaryLabel)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.45))
                        .lineLimit(1)
                }

                Spacer()

                let allSelected = selections.count == peopleCount
                Button {
                    onClose()
                } label: {
                    Text(allSelected ? "Confirm" : "Select \(peopleCount - selections.count) more")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.black.opacity(allSelected ? 0.85 : 0.4))
                        .padding(.horizontal, 22)
                        .padding(.vertical, 14)
                        .background(
                            allSelected
                                ? Color(red: 0.24, green: 0.85, blue: 0.44)
                                : Color(red: 1.0, green: 0.87, blue: 0.28).opacity(0.35),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                }
                .disabled(!allSelected)
                .animation(.smooth(duration: 0.2), value: selections.count)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
            .background(FDColor.bg)
        }
    }

    // MARK: - Seat tap logic

    private func handleSeatTap(_ seat: PlaneSeat) {
        withAnimation(.smooth(duration: 0.18)) {
            if selections[activePassenger] == seat.id {
                selections.removeValue(forKey: activePassenger)
            } else {
                // Remove conflict: seat taken by another passenger
                for (key, value) in selections where value == seat.id {
                    selections.removeValue(forKey: key)
                }
                selections[activePassenger] = seat.id
                // Auto-advance to next unassigned passenger
                let next = (activePassenger + 1..<peopleCount).first { selections[$0] == nil }
                if let next { activePassenger = next }
            }
        }
    }
}

// MARK: - Traveler model

private struct Traveler: Identifiable {
    enum Kind {
        case adult
        case child

        var label: String { self == .adult ? "Adult" : "Child" }
        var icon: String { self == .adult ? "person.fill" : "figure.child" }
        var accent: Color { self == .adult ? .green : Color(red: 1.0, green: 0.72, blue: 0.22) }
    }

    let index: Int   // position in the combined list (used as selections key)
    let kind: Kind
    let number: Int  // 1-based number within the kind

    var id: Int { index }
    var label: String { "\(kind.label) \(number)" }
}

// MARK: - Colors

private enum FDColor {
    static let bg = Color(red: 0.05, green: 0.05, blue: 0.07)
    static let card = Color(red: 0.10, green: 0.10, blue: 0.13)
}

// MARK: - Small helpers

private struct FDSectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text).font(.title3.weight(.bold))
    }
}

private struct FDChip: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.65))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.1), in: Capsule())
    }
}

private struct FDLegendItem: View {
    let color: Color
    let label: String
    var body: some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 14, height: 14)
            Text(label)
        }
    }
}

// MARK: - Class option card

private struct ClassOptionCard: View {
    let option: PlaneClassOption
    let adultCount: Int
    let childCount: Int
    let isSelected: Bool
    let onSelect: () -> Void

    private var accent: Color {
        switch option.id {
        case .economy: return .green
        case .business: return Color(red: 0.35, green: 0.55, blue: 1.0)
        case .first: return Color(red: 0.72, green: 0.42, blue: 1.0)
        }
    }

    private var totalPrice: Money {
        option.totalPrice(adults: adultCount, children: childCount)
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(option.displayName)
                        .font(.subheadline.weight(.bold))
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(accent)
                    }
                }

                // Total for all travelers
                Text(totalPrice.displayString)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(accent)
                    .contentTransition(.numericText())
                    .animation(.smooth(duration: 0.25), value: totalPrice.amount)

                Text("total · \(adultCount + childCount) traveler\(adultCount + childCount > 1 ? "s" : "")")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.35))

                // Per-person breakdown
                VStack(alignment: .leading, spacing: 3) {
                    PriceRow(label: "Adult", price: option.pricePerAdult, accent: accent)
                    if childCount > 0 {
                        PriceRow(label: "Child", price: option.pricePerChild, accent: Color(red: 1.0, green: 0.72, blue: 0.22))
                    }
                }

                Divider().overlay(Color.white.opacity(0.08))

                VStack(alignment: .leading, spacing: 5) {
                    ForEach(option.features.prefix(3), id: \.self) { f in
                        HStack(spacing: 6) {
                            Circle().fill(accent).frame(width: 4, height: 4)
                            Text(f)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.55))
                        }
                    }
                }
            }
            .padding(14)
            .frame(width: 164)
            .frame(maxHeight: .infinity, alignment: .topLeading)
            .background(
                isSelected ? accent.opacity(0.12) : Color.white.opacity(0.06),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? accent.opacity(0.5) : Color.clear, lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
        .animation(.smooth(duration: 0.2), value: isSelected)
    }
}

private struct PriceRow: View {
    let label: String
    let price: Money
    let accent: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .foregroundStyle(.white.opacity(0.4))
            Spacer()
            Text(price.displayString)
                .foregroundStyle(accent.opacity(0.8))
        }
        .font(.caption2.weight(.medium))
    }
}

// MARK: - Passenger tab

private struct PassengerTab: View {
    let traveler: Traveler
    let isActive: Bool
    let seatId: String?
    let onSelect: () -> Void

    private var accent: Color { traveler.kind.accent }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isActive ? accent : Color.white.opacity(0.10))
                        .frame(width: 30, height: 30)
                    Image(systemName: traveler.kind.icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isActive ? .black : .white.opacity(0.55))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(traveler.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isActive ? .white : .white.opacity(0.45))
                    Text(seatId ?? "No seat")
                        .font(.caption2)
                        .foregroundStyle(seatId != nil ? accent : .white.opacity(0.28))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isActive ? accent.opacity(0.14) : Color.white.opacity(0.06),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? accent.opacity(0.45) : Color.clear, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .animation(.smooth(duration: 0.2), value: isActive)
    }
}

// MARK: - Seat map components

private struct SeatColumnHeaders: View {
    let isFirstClass: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Color.clear.frame(width: 24)
            Spacer()
            HStack(spacing: 5) {
                headerLabel("A")
                if isFirstClass { Color.clear.frame(width: 32) } else { headerLabel("B") }
                headerLabel("C")
            }
            Color.clear.frame(width: 28)
            HStack(spacing: 5) {
                headerLabel("D")
                if isFirstClass { Color.clear.frame(width: 32) } else { headerLabel("E") }
                headerLabel("F")
            }
            Spacer()
            Color.clear.frame(width: 24)
        }
    }

    private func headerLabel(_ letter: String) -> some View {
        Text(letter)
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white.opacity(0.35))
            .frame(width: 32, alignment: .center)
    }
}

private struct ExitRowDivider: View {
    var body: some View {
        HStack(spacing: 8) {
            Rectangle().fill(Color.yellow.opacity(0.25)).frame(height: 1)
            Label("Exit row", systemImage: "figure.walk")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.yellow.opacity(0.65))
                .fixedSize()
            Rectangle().fill(Color.yellow.opacity(0.25)).frame(height: 1)
        }
        .padding(.vertical, 5)
    }
}

private struct SeatRowView: View {
    let rowNumber: Int
    let seats: [PlaneSeat]
    let isFirstClass: Bool
    let activePassenger: Int
    let selections: [Int: String]
    let onTap: (PlaneSeat) -> Void

    private func seat(_ letter: String) -> PlaneSeat? {
        seats.first { $0.letter == letter }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text("\(rowNumber)")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.28))
                .frame(width: 24, alignment: .leading)

            Spacer()

            HStack(spacing: 5) {
                SeatCell(seat: seat("A"), activePassenger: activePassenger, selections: selections, onTap: onTap)
                if isFirstClass {
                    Color.clear.frame(width: 32, height: 32)
                } else {
                    SeatCell(seat: seat("B"), activePassenger: activePassenger, selections: selections, onTap: onTap)
                }
                SeatCell(seat: seat("C"), activePassenger: activePassenger, selections: selections, onTap: onTap)
            }

            // Aisle
            Color.clear.frame(width: 28)

            HStack(spacing: 5) {
                SeatCell(seat: seat("D"), activePassenger: activePassenger, selections: selections, onTap: onTap)
                if isFirstClass {
                    Color.clear.frame(width: 32, height: 32)
                } else {
                    SeatCell(seat: seat("E"), activePassenger: activePassenger, selections: selections, onTap: onTap)
                }
                SeatCell(seat: seat("F"), activePassenger: activePassenger, selections: selections, onTap: onTap)
            }

            Spacer()

            Color.clear.frame(width: 24)
        }
        .padding(.vertical, 3)
    }
}

private struct SeatCell: View {
    let seat: PlaneSeat?
    let activePassenger: Int
    let selections: [Int: String]
    let onTap: (PlaneSeat) -> Void

    private var selectedBy: Int? {
        guard let seat else { return nil }
        return selections.first { $0.value == seat.id }?.key
    }

    private var bg: Color {
        guard let seat else { return .clear }
        if seat.isOccupied { return Color.white.opacity(0.07) }
        if let p = selectedBy {
            return p == activePassenger ? .green : Color(red: 0.35, green: 0.55, blue: 1.0)
        }
        if seat.isExitRow { return Color.yellow.opacity(0.16) }
        switch seat.cabinClass {
        case .economy: return Color.white.opacity(0.14)
        case .business: return Color(red: 0.35, green: 0.55, blue: 1.0).opacity(0.2)
        case .first: return Color(red: 0.72, green: 0.42, blue: 1.0).opacity(0.2)
        }
    }

    var body: some View {
        Group {
            if let seat {
                Button {
                    if !seat.isOccupied { onTap(seat) }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6).fill(bg)
                        if let p = selectedBy {
                            Text("\(p + 1)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .disabled(seat.isOccupied)
                .animation(.smooth(duration: 0.18), value: selectedBy)
                .animation(.smooth(duration: 0.18), value: activePassenger)
            } else {
                Color.clear.frame(width: 32, height: 32)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    FlightDetailView(
        flight: MockTravelData.inboundFlight,
        segmentTitle: "Flight to Istanbul",
        directionTitle: "Outbound",
        directionIcon: "airplane.arrival",
        adultCount: MockTravelData.tripDetails.peopleCount,
        childCount: 1,
        onClose: {}
    )
}
