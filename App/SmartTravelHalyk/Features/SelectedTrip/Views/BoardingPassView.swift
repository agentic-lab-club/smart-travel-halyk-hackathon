import SwiftUI

// MARK: - Boarding pass

struct BoardingPassView: View {
    let pass: BoardingPassInfo

    private var isOutbound: Bool { pass.direction == "Outbound" }
    private var accentColor: Color { isOutbound ? Color.green : Color.blue }

    var body: some View {
        VStack(spacing: 0) {
            header
            body_
            perforationDivider
            footer
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    }

    // MARK: Header strip

    private var header: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text(pass.direction.uppercased())
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(.white.opacity(0.75))
                Text(pass.airline)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            }
            Spacer()
            Image(systemName: isOutbound ? "airplane.departure" : "airplane.arrival")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(accentColor.gradient)
    }

    // MARK: Route block

    private var body_: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                airportBlock(code: pass.fromAirport, city: pass.fromCity, time: pass.departureTime, alignment: .leading)
                Spacer()
                VStack(spacing: 6) {
                    Image(systemName: "airplane")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(accentColor)
                    Text(flightDuration)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(pass.flightNumber)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.primary)
                }
                Spacer()
                airportBlock(code: pass.toAirport, city: pass.toCity, time: pass.arrivalTime, alignment: .trailing)
            }

            // Details row
            HStack(spacing: 0) {
                detailCell(label: "CABIN", value: pass.cabinClass.title.uppercased())
                Divider().frame(height: 32)
                detailCell(label: "SEAT", value: pass.seat)
                Divider().frame(height: 32)
                detailCell(label: "GATE", value: pass.gate)
                Divider().frame(height: 32)
                detailCell(label: "CLASS", value: String(pass.seat.last ?? "A"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(20)
    }

    // MARK: Perforation

    private var perforationDivider: some View {
        HStack(spacing: 0) {
            Circle()
                .fill(Color(.systemGroupedBackground))
                .frame(width: 24, height: 24)
                .offset(x: -12)
            perforationLine
            Circle()
                .fill(Color(.systemGroupedBackground))
                .frame(width: 24, height: 24)
                .offset(x: 12)
        }
    }

    private var perforationLine: some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: CGPoint(x: 0, y: geo.size.height / 2))
                path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 2))
            }
            .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
            .foregroundStyle(Color(.separator))
        }
        .frame(height: 1)
        .padding(.horizontal, 4)
    }

    // MARK: Footer (barcode area)

    private var footer: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("PASSENGER")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(pass.passengerName.uppercased())
                        .font(.subheadline.weight(.bold))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("BOOKING REF")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(pass.bookingRef)
                        .font(.subheadline.weight(.bold).monospaced())
                }
            }

            MockBarcode(seed: pass.id.hashValue)
                .frame(height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(20)
    }

    // MARK: Helpers

    private func airportBlock(code: String, city: String, time: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(code)
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(.primary)
            Text(city)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            Text(formattedTime(time))
                .font(.subheadline.weight(.semibold).monospaced())
            Text(formattedDate(time))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func detailCell(label: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.bold))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private var flightDuration: String {
        let h = pass.durationMinutes / 60
        let m = pass.durationMinutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    private func formattedTime(_ iso: String) -> String {
        guard let d = iso.asDate else { return "--:--" }
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        return f.string(from: d)
    }

    private func formattedDate(_ iso: String) -> String {
        guard let d = iso.asDate else { return "" }
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none
        return f.string(from: d)
    }
}

// MARK: - Hotel confirmation card

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

// MARK: - Star rating

private struct StarRating: View {
    let count: Int
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<min(count, 5), id: \.self) { _ in
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
            }
        }
    }
}

// MARK: - Mock barcode (deterministic visual from seed)

private struct MockBarcode: View {
    let seed: Int

    var body: some View {
        Canvas { ctx, size in
            var rng = SeededRNG(seed: seed)
            var x: CGFloat = 0
            while x < size.width {
                let w = CGFloat(rng.next(min: 1, max: 5))
                let isBlack = rng.next(min: 0, max: 1) == 0
                let rect = CGRect(x: x, y: 0, width: w, height: size.height)
                ctx.fill(Path(rect), with: .color(isBlack ? .primary : .clear))
                x += w
            }
        }
        .background(Color(.tertiarySystemGroupedBackground))
    }
}

// MARK: - Mock QR code (pixel grid from seed)

private struct MockQRCode: View {
    let seed: Int
    private let grid = 15

    var body: some View {
        Canvas { ctx, size in
            var rng = SeededRNG(seed: seed)
            let cellW = size.width / CGFloat(grid)
            let cellH = size.height / CGFloat(grid)
            for row in 0..<grid {
                for col in 0..<grid {
                    // Always fill corners for QR-code look
                    let isCorner = isFinderCell(row: row, col: col)
                    let filled = isCorner || rng.next(min: 0, max: 2) == 0
                    if filled {
                        let rect = CGRect(x: CGFloat(col) * cellW, y: CGFloat(row) * cellH, width: cellW - 0.5, height: cellH - 0.5)
                        ctx.fill(Path(rect), with: .color(.primary))
                    }
                }
            }
        }
        .background(Color(.tertiarySystemGroupedBackground))
    }

    private func isFinderCell(row: Int, col: Int) -> Bool {
        let size = grid
        func inFinder(_ r: Int, _ c: Int, _ or: Int, _ oc: Int) -> Bool {
            r >= or && r < or + 7 && c >= oc && c < oc + 7
        }
        return inFinder(row, col, 0, 0) ||
            inFinder(row, col, 0, size - 7) ||
            inFinder(row, col, size - 7, 0)
    }
}

// MARK: - Seeded RNG

private struct SeededRNG {
    private var state: UInt64

    init(seed: Int) {
        state = UInt64(bitPattern: Int64(seed))
        if state == 0 { state = 12345 }
    }

    mutating func next(min: Int, max: Int) -> Int {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return min + Int(state % UInt64(max - min + 1))
    }
}

// MARK: - Previews

#Preview("Boarding Pass") {
    ScrollView {
        BoardingPassView(pass: BoardingPassInfo(
            id: "prev-1",
            direction: "Outbound",
            passengerName: "Artem Bagin",
            bookingRef: "HTK-482910",
            airline: "Air Astana",
            flightNumber: "KC721",
            fromAirport: "ALA", fromCity: "Almaty",
            toAirport: "DXB", toCity: "Dubai",
            departureTime: "2026-06-15T08:30:00",
            arrivalTime: "2026-06-15T11:10:00",
            gate: "B12", seat: "14A",
            cabinClass: .business,
            durationMinutes: 280
        ))
        .padding(20)
    }
    .background(Color(.systemGroupedBackground))
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
