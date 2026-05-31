import SwiftUI

// MARK: - Add-on model

struct TripAddOn: Identifiable {
    enum Category {
        case insurance, transfer, connectivity, comfort, baggage
    }

    let id: String
    let category: Category
    let icon: String
    let title: String
    let subtitle: String
    let price: Money
    let badge: String?
    let isExclusive: Bool

    var categoryColor: Color {
        switch category {
        case .insurance:   return .blue
        case .transfer:    return .orange
        case .connectivity: return .purple
        case .comfort:     return .teal
        case .baggage:     return .indigo
        }
    }
}

// MARK: - Purchase view model

@MainActor
@Observable
final class TripPurchaseViewModel {
    let trip: TripDetailsResponse
    let addOns: [TripAddOn]
    var selectedAddOnIds: Set<String> = []
    var isPurchasing = false
    var purchaseComplete = false

    var baseCost: Money { trip.summary.estimatedTotalCost }

    var selectedAddOns: [TripAddOn] { addOns.filter { selectedAddOnIds.contains($0.id) } }

    var addOnTotal: Double { selectedAddOns.reduce(0) { $0 + $1.price.amount } }

    var grandTotal: Money {
        Money(amount: baseCost.amount + addOnTotal, currency: baseCost.currency)
    }

    var cashbackEarned: Money {
        let pct = trip.cashback?.boostedPercent ?? trip.cashback?.basePercent ?? 3.0
        return Money(amount: grandTotal.amount * pct / 100.0, currency: baseCost.currency)
    }

    var cashbackPercent: Double {
        trip.cashback?.boostedPercent ?? trip.cashback?.basePercent ?? 3.0
    }

    init(trip: TripDetailsResponse) {
        self.trip = trip
        self.addOns = TripPurchaseViewModel.makeAddOns(currency: trip.currency)
    }

    func toggleAddOn(_ id: String) {
        withAnimation(.smooth(duration: 0.25)) {
            if selectedAddOnIds.contains(id) {
                selectedAddOnIds.remove(id)
            } else {
                // Deselect exclusive peers in same category
                if let addOn = addOns.first(where: { $0.id == id }), addOn.isExclusive {
                    let peers = addOns.filter { $0.category == addOn.category && $0.isExclusive }
                    peers.forEach { selectedAddOnIds.remove($0.id) }
                }
                selectedAddOnIds.insert(id)
            }
        }
    }

    private(set) var bookedTrip: BookedTrip?

    func purchase(bookingService: BookingService) async {
        isPurchasing = true
        try? await Task.sleep(for: .seconds(1.4))
        let booked = bookingService.book(
            trip: trip,
            addOnIds: Array(selectedAddOnIds),
            allAddOns: addOns,
            total: grandTotal,
            cashback: cashbackEarned
        )
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            bookedTrip = booked
            isPurchasing = false
            purchaseComplete = true
        }
    }

    private static func makeAddOns(currency: CurrencyCode) -> [TripAddOn] {
        let c = currency
        return [
            TripAddOn(
                id: "ins_basic",
                category: .insurance,
                icon: "shield.fill",
                title: "Halyk Insurance Basic",
                subtitle: "Medical cover up to $30 000 · trip cancellation · lost baggage",
                price: Money(amount: 3_500, currency: c),
                badge: nil,
                isExclusive: true
            ),
            TripAddOn(
                id: "ins_premium",
                category: .insurance,
                icon: "shield.checkered",
                title: "Halyk Insurance Premium",
                subtitle: "Medical cover up to $100 000 · sports · extreme activities · 24/7 SOS",
                price: Money(amount: 8_500, currency: c),
                badge: "Popular",
                isExclusive: true
            ),
            TripAddOn(
                id: "taxi_arrival",
                category: .transfer,
                icon: "car.fill",
                title: "Airport Pickup",
                subtitle: "Taxi from airport to your hotel on arrival day",
                price: Money(amount: 2_200, currency: c),
                badge: nil,
                isExclusive: false
            ),
            TripAddOn(
                id: "taxi_departure",
                category: .transfer,
                icon: "car.rear.fill",
                title: "Airport Drop-off",
                subtitle: "Taxi from hotel to airport on departure day",
                price: Money(amount: 2_200, currency: c),
                badge: nil,
                isExclusive: false
            ),
            TripAddOn(
                id: "esim",
                category: .connectivity,
                icon: "antenna.radiowaves.left.and.right",
                title: "Travel eSIM",
                subtitle: "5 GB data plan · works in 150+ countries · instant activation",
                price: Money(amount: 1_800, currency: c),
                badge: "New",
                isExclusive: false
            ),
            TripAddOn(
                id: "lounge",
                category: .comfort,
                icon: "cup.and.saucer.fill",
                title: "Airport Lounge Access",
                subtitle: "Priority Pass lounge at departure terminal · free Wi-Fi · meals",
                price: Money(amount: 4_500, currency: c),
                badge: nil,
                isExclusive: false
            ),
            TripAddOn(
                id: "baggage",
                category: .baggage,
                icon: "suitcase.fill",
                title: "Extra Baggage 23 kg",
                subtitle: "Prepaid extra hold bag on outbound and return flights",
                price: Money(amount: 5_200, currency: c),
                badge: "Save 20%",
                isExclusive: false
            ),
        ]
    }
}

// MARK: - Purchase view

struct TripPurchaseView: View {
    @State private var viewModel: TripPurchaseViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(BookingService.self) private var bookingService

    init(trip: TripDetailsResponse) {
        _viewModel = State(initialValue: TripPurchaseViewModel(trip: trip))
    }

    var body: some View {
        ZStack {
            purchaseContent
                .opacity(viewModel.purchaseComplete ? 0 : 1)
                .animation(.easeOut(duration: 0.3), value: viewModel.purchaseComplete)

            if viewModel.purchaseComplete, let booked = viewModel.bookedTrip {
                PurchaseSuccessView(
                    viewModel: viewModel,
                    bookedTrip: booked,
                    onDone: { dismiss() }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.92)))
            }
        }
    }

    private var purchaseContent: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    tripSummaryHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 24)

                    addOnsSection
                        .padding(.bottom, 32)

                    orderSummarySection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 120)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Complete Booking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                bookButton
            }
        }
    }

    // MARK: Trip summary header

    private var tripSummaryHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "airplane.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.trip.title)
                        .font(.headline)
                    Text(viewModel.trip.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    HStack(spacing: 6) {
                        Label("\(viewModel.trip.durationDays) days", systemImage: "calendar")
                        Label("\(viewModel.trip.peopleCount) traveler\(viewModel.trip.peopleCount > 1 ? "s" : "")", systemImage: "person.2.fill")
                    }
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                }
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Base trip price")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.baseCost.displayString)
                        .font(.title3.bold())
                }
                Spacer()
                if viewModel.cashbackPercent > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Cashback")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(Int(viewModel.cashbackPercent))%")
                            .font(.title3.bold())
                            .foregroundStyle(.green)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Add-ons section

    private var addOnsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Enhance Your Trip")
                    .font(.title3.bold())
                Text("Optional add-ons — pick what you need")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 14)

            // Insurance group
            AddOnGroupHeader(icon: "shield.fill", title: "Travel Protection", color: .blue)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

            ForEach(viewModel.addOns.filter { $0.category == .insurance }) { addOn in
                AddOnCard(
                    addOn: addOn,
                    isSelected: viewModel.selectedAddOnIds.contains(addOn.id),
                    onToggle: { viewModel.toggleAddOn(addOn.id) }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }

            // Transfer group
            AddOnGroupHeader(icon: "car.fill", title: "Airport Transfers", color: .orange)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 8)

            ForEach(viewModel.addOns.filter { $0.category == .transfer }) { addOn in
                AddOnCard(
                    addOn: addOn,
                    isSelected: viewModel.selectedAddOnIds.contains(addOn.id),
                    onToggle: { viewModel.toggleAddOn(addOn.id) }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }

            // Extras group
            AddOnGroupHeader(icon: "star.fill", title: "Extras", color: .purple)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 8)

            ForEach(viewModel.addOns.filter { [.connectivity, .comfort, .baggage].contains($0.category) }) { addOn in
                AddOnCard(
                    addOn: addOn,
                    isSelected: viewModel.selectedAddOnIds.contains(addOn.id),
                    onToggle: { viewModel.toggleAddOn(addOn.id) }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
        }
    }

    // MARK: Order summary

    private var orderSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Order Summary")
                .font(.headline)

            VStack(spacing: 8) {
                OrderRow(label: "Base trip", value: viewModel.baseCost.displayString)

                ForEach(viewModel.selectedAddOns) { addOn in
                    OrderRow(label: addOn.title, value: addOn.price.displayString)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if !viewModel.selectedAddOns.isEmpty {
                    Divider().padding(.vertical, 2)
                }

                Divider().padding(.vertical, 2)

                HStack {
                    Text("Total")
                        .font(.headline)
                    Spacer()
                    Text(viewModel.grandTotal.displayString)
                        .font(.headline)
                        .contentTransition(.numericText())
                        .animation(.smooth(duration: 0.3), value: viewModel.grandTotal.amount)
                }

                HStack {
                    Label("Cashback earned", systemImage: "sparkles")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                    Spacer()
                    Text("+ \(viewModel.cashbackEarned.displayString)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)
                        .contentTransition(.numericText())
                        .animation(.smooth(duration: 0.3), value: viewModel.cashbackEarned.amount)
                }
                .padding(12)
                .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: Book button

    private var bookButton: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                Task { await viewModel.purchase(bookingService: bookingService) }
            } label: {
                HStack(spacing: 10) {
                    if viewModel.isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "basket.fill")
                    }
                    Text(viewModel.isPurchasing ? "Booking…" : "Book — \(viewModel.grandTotal.displayString)")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(.green, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isPurchasing)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemGroupedBackground))
        }
    }
}

// MARK: - Add-on group header

private struct AddOnGroupHeader: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        Label(title, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(color)
    }
}

// MARK: - Add-on card

private struct AddOnCard: View {
    let addOn: TripAddOn
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? addOn.categoryColor : Color(.tertiarySystemGroupedBackground))
                        .frame(width: 42, height: 42)
                    Image(systemName: addOn.icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : addOn.categoryColor)
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(addOn.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        if let badge = addOn.badge {
                            Text(badge)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(addOn.categoryColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(addOn.categoryColor.opacity(0.12), in: Capsule())
                        }
                    }
                    Text(addOn.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(addOn.price.displayString)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(isSelected ? addOn.categoryColor : .primary)
                        .padding(.top, 2)
                }

                Spacer(minLength: 4)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? addOn.categoryColor : Color(.tertiarySystemFill))
                    .symbolEffect(.bounce, value: isSelected)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                isSelected ? addOn.categoryColor.opacity(0.5) : Color.clear,
                                lineWidth: 1.5
                            )
                    )
            )
            .animation(.smooth(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Order row

private struct OrderRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
        }
    }
}

// MARK: - Purchase success view

struct PurchaseSuccessView: View {
    let viewModel: TripPurchaseViewModel
    let bookedTrip: BookedTrip
    let onDone: () -> Void

    @State private var checkmarkScale: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var rewardOffset: CGFloat = 60
    @State private var rewardOpacity: Double = 0
    @State private var particlesActive = false
    @State private var detailsOpacity: Double = 0
    @State private var showDocuments = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            if particlesActive {
                ConfettiCanvas()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 48)

                    // Checkmark hero
                    ZStack {
                        Circle()
                            .fill(RadialGradient(
                                colors: [Color.green.opacity(0.25), Color.green.opacity(0.05)],
                                center: .center, startRadius: 20, endRadius: 90
                            ))
                            .frame(width: 180, height: 180)
                        Circle()
                            .fill(Color.green)
                            .frame(width: 100, height: 100)
                            .shadow(color: .green.opacity(0.4), radius: 20, y: 8)
                        Image(systemName: "checkmark")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .scaleEffect(checkmarkScale)
                    .padding(.bottom, 28)

                    // Title
                    VStack(spacing: 8) {
                        Text("You're all set!")
                            .font(.largeTitle.bold())
                        Text("Your trip to \(viewModel.trip.title) is booked")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .opacity(textOpacity)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)

                    // Booking details card
                    VStack(spacing: 12) {
                        HStack {
                            Text("Booking Reference")
                                .font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            Text(bookedTrip.id)
                                .font(.caption.weight(.bold).monospaced())
                        }
                        Divider()
                        ForEach(viewModel.selectedAddOns) { addOn in
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption).foregroundStyle(.green)
                                Text(addOn.title)
                                    .font(.caption).foregroundStyle(.secondary)
                                Spacer()
                            }
                        }
                        if !viewModel.selectedAddOns.isEmpty { Divider() }
                        HStack {
                            Text("Total paid").font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(viewModel.grandTotal.displayString).font(.subheadline.weight(.bold))
                        }
                    }
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)
                    .opacity(detailsOpacity)
                    .padding(.bottom, 12)

                    // Documents button
                    Button {
                        showDocuments = true
                    } label: {
                        Label("View Boarding Passes & Hotel Booking", systemImage: "doc.text.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.blue, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .opacity(detailsOpacity)
                    .padding(.bottom, 16)

                    // Cashback reward card
                    HStack(spacing: 14) {
                        ZStack {
                            Circle().fill(Color.green.opacity(0.15)).frame(width: 52, height: 52)
                            Image(systemName: "sparkles")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(.green)
                                .symbolEffect(.variableColor.iterative, isActive: rewardOpacity > 0)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Halyk Points Earned")
                                .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                            Text("+ \(viewModel.cashbackEarned.displayString)")
                                .font(.title3.bold()).foregroundStyle(.green)
                            Text("\(Int(viewModel.cashbackPercent))% cashback on this booking")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemGroupedBackground))
                            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.green.opacity(0.3), lineWidth: 1.5))
                    )
                    .padding(.horizontal, 20)
                    .offset(y: rewardOffset)
                    .opacity(rewardOpacity)
                    .padding(.bottom, 32)

                    Button("Done") { onDone() }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .controlSize(.large)
                        .opacity(textOpacity)
                        .padding(.bottom, 48)
                }
            }
        }
        .onAppear { runEntranceSequence() }
        .sheet(isPresented: $showDocuments) {
            TripDocumentsView(bookedTrip: bookedTrip)
        }
    }

    private func runEntranceSequence() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.62).delay(0.1)) { checkmarkScale = 1 }
        withAnimation(.easeOut(duration: 0.4).delay(0.45)) { textOpacity = 1 }
        withAnimation(.easeOut(duration: 0.4).delay(0.5))  { detailsOpacity = 1 }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.72).delay(0.65)) {
            rewardOffset = 0; rewardOpacity = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { particlesActive = true }
    }
}

// MARK: - Confetti canvas

private struct ConfettiParticle {
    var x: CGFloat
    var y: CGFloat
    var color: Color
    var size: CGFloat
    var angle: Double
    var speed: CGFloat
    var spin: Double
    var shape: Int
}

private struct ConfettiCanvas: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var tick: Int = 0
    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    private let colors: [Color] = [
        .green, .yellow, .orange, .pink, .blue, .purple, .teal, .mint
    ]

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                for p in particles {
                    let rect = CGRect(x: p.x - p.size / 2, y: p.y - p.size / 2, width: p.size, height: p.size * 0.55)
                    ctx.opacity = max(0, 1.0 - (p.y / (size.height * 1.1)))
                    ctx.transform = .identity
                        .translatedBy(x: p.x, y: p.y)
                        .rotated(by: p.spin)
                        .translatedBy(x: -p.x, y: -p.y)
                    var path: Path
                    if p.shape == 0 {
                        path = Path(ellipseIn: rect)
                    } else if p.shape == 1 {
                        path = Path(rect)
                    } else {
                        path = Path(roundedRect: rect, cornerRadius: 2)
                    }
                    ctx.fill(path, with: .color(p.color))
                }
            }
            .onAppear {
                particles = (0..<80).map { _ in
                    ConfettiParticle(
                        x: CGFloat.random(in: 0...geo.size.width),
                        y: CGFloat.random(in: -200 ... -10),
                        color: colors.randomElement()!,
                        size: CGFloat.random(in: 6...14),
                        angle: Double.random(in: 0...360),
                        speed: CGFloat.random(in: 2.5...6),
                        spin: Double.random(in: -0.08...0.08),
                        shape: Int.random(in: 0...2)
                    )
                }
            }
            .onReceive(timer) { _ in
                for i in particles.indices {
                    particles[i].y += particles[i].speed
                    particles[i].x += sin(particles[i].angle) * 0.8
                    particles[i].spin += Double.random(in: -0.02...0.02)
                    particles[i].angle += 0.04
                    if particles[i].y > geo.size.height + 20 {
                        particles[i].y = CGFloat.random(in: -80 ... -10)
                        particles[i].x = CGFloat.random(in: 0...geo.size.width)
                        particles[i].speed = CGFloat.random(in: 2.5...6)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Purchase") {
    let service = BookingService()
    return TripPurchaseView(trip: MockTravelData.tripDetails)
        .environment(service)
}

#Preview("Success") {
    let vm = TripPurchaseViewModel(trip: MockTravelData.tripDetails)
    let service = BookingService()
    let booked = service.book(
        trip: MockTravelData.tripDetails,
        addOnIds: ["ins_premium"],
        allAddOns: [],
        total: Money(amount: 450_000, currency: .kzt),
        cashback: Money(amount: 13_500, currency: .kzt)
    )
    return PurchaseSuccessView(viewModel: vm, bookedTrip: booked, onDone: {})
}
