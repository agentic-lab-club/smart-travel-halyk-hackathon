import SwiftUI

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
