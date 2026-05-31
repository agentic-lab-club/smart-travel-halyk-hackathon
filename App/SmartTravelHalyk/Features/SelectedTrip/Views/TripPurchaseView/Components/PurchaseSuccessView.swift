import SwiftUI

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
