import SwiftUI

struct TransferDetailContent: View {
    let details: TransferDetails
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            DetailRow(icon: "location.fill", label: "\(details.from) → \(details.to)")
            DetailRow(icon: "ruler", label: String(format: "%.0f km · %d min", details.distanceKm, details.durationMinutes))
            if let taxi = details.taxiEstimate {
                DetailRow(icon: "car.fill", label: "Taxi ≈ \(taxi.displayString)")
            }
            if let pt = details.publicTransportEstimate {
                DetailRow(icon: "bus.fill", label: "Public transport ≈ \(Money(amount: pt.amount, currency: pt.currency).displayString) · \(pt.durationMinutes) min")
            }
            DetailRow(icon: "sparkles", label: details.reason)
        }.padding(.top, 4)
    }
}
