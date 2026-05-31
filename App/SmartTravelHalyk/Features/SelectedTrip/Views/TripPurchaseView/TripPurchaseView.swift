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
            TripAddOn(id: "ins_basic", category: .insurance, icon: "shield.fill", title: "Halyk Insurance Basic", subtitle: "Medical cover up to $30 000 · trip cancellation · lost baggage", price: Money(amount: 3_500, currency: c), badge: nil, isExclusive: true),
            TripAddOn(id: "ins_premium", category: .insurance, icon: "shield.checkered", title: "Halyk Insurance Premium", subtitle: "Medical cover up to $100 000 · sports · extreme activities · 24/7 SOS", price: Money(amount: 8_500, currency: c), badge: "Popular", isExclusive: true),
            TripAddOn(id: "taxi_arrival", category: .transfer, icon: "car.fill", title: "Airport Pickup", subtitle: "Taxi from airport to your hotel on arrival day", price: Money(amount: 2_200, currency: c), badge: nil, isExclusive: false),
            TripAddOn(id: "taxi_departure", category: .transfer, icon: "car.rear.fill", title: "Airport Drop-off", subtitle: "Taxi from hotel to airport on departure day", price: Money(amount: 2_200, currency: c), badge: nil, isExclusive: false),
            TripAddOn(id: "esim", category: .connectivity, icon: "antenna.radiowaves.left.and.right", title: "Travel eSIM", subtitle: "5 GB data plan · works in 150+ countries · instant activation", price: Money(amount: 1_800, currency: c), badge: "New", isExclusive: false),
            TripAddOn(id: "lounge", category: .comfort, icon: "cup.and.saucer.fill", title: "Airport Lounge Access", subtitle: "Priority Pass lounge at departure terminal · free Wi-Fi · meals", price: Money(amount: 4_500, currency: c), badge: nil, isExclusive: false),
            TripAddOn(id: "baggage", category: .baggage, icon: "suitcase.fill", title: "Extra Baggage 23 kg", subtitle: "Prepaid extra hold bag on outbound and return flights", price: Money(amount: 5_200, currency: c), badge: "Save 20%", isExclusive: false),
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

            AddOnGroupHeader(icon: "shield.fill", title: "Travel Protection", color: .blue)
                .padding(.horizontal, 20).padding(.bottom, 8)

            ForEach(viewModel.addOns.filter { $0.category == .insurance }) { addOn in
                AddOnCard(addOn: addOn, isSelected: viewModel.selectedAddOnIds.contains(addOn.id), onToggle: { viewModel.toggleAddOn(addOn.id) })
                    .padding(.horizontal, 20).padding(.bottom, 8)
            }

            AddOnGroupHeader(icon: "car.fill", title: "Airport Transfers", color: .orange)
                .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 8)

            ForEach(viewModel.addOns.filter { $0.category == .transfer }) { addOn in
                AddOnCard(addOn: addOn, isSelected: viewModel.selectedAddOnIds.contains(addOn.id), onToggle: { viewModel.toggleAddOn(addOn.id) })
                    .padding(.horizontal, 20).padding(.bottom, 8)
            }

            AddOnGroupHeader(icon: "star.fill", title: "Extras", color: .purple)
                .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 8)

            ForEach(viewModel.addOns.filter { [.connectivity, .comfort, .baggage].contains($0.category) }) { addOn in
                AddOnCard(addOn: addOn, isSelected: viewModel.selectedAddOnIds.contains(addOn.id), onToggle: { viewModel.toggleAddOn(addOn.id) })
                    .padding(.horizontal, 20).padding(.bottom, 8)
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
                    Text("Total").font(.headline)
                    Spacer()
                    Text(viewModel.grandTotal.displayString)
                        .font(.headline)
                        .contentTransition(.numericText())
                        .animation(.smooth(duration: 0.3), value: viewModel.grandTotal.amount)
                }

                HStack {
                    Label("Cashback earned", systemImage: "sparkles")
                        .font(.subheadline).foregroundStyle(.green)
                    Spacer()
                    Text("+ \(viewModel.cashbackEarned.displayString)")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(.green)
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
                        ProgressView().tint(.white)
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

#Preview("Purchase") {
    let service = BookingService()
    return TripPurchaseView(trip: MockTravelData.tripDetails)
        .environment(service)
}
