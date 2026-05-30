import SwiftUI

struct TripDocumentsView: View {
    let bookedTrip: BookedTrip
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if !bookedTrip.boardingPasses.isEmpty {
                        sectionHeader(icon: "airplane", title: "Boarding Passes", color: .green)

                        ForEach(bookedTrip.boardingPasses) { pass in
                            BoardingPassView(pass: pass)
                        }
                    }

                    if let hotel = bookedTrip.hotelConfirmation {
                        sectionHeader(icon: "bed.double.fill", title: "Hotel Booking", color: .orange)
                        HotelConfirmationCard(info: hotel)
                    }
                }
                .padding(20)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Travel Documents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func sectionHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .font(.headline)
            Spacer()
        }
    }
}

#Preview {
    TripDocumentsView(bookedTrip: BookedTrip(
        id: "HTK-482910",
        trip: MockTravelData.tripDetails,
        addOnIds: ["ins_premium"],
        totalPaid: Money(amount: 450_000, currency: .kzt),
        cashbackEarned: Money(amount: 13_500, currency: .kzt),
        bookedAt: Date(),
        boardingPasses: [
            BoardingPassInfo(
                id: "BP-1", direction: "Outbound",
                passengerName: "Artem Bagin", bookingRef: "HTK-482910",
                airline: "Air Astana", flightNumber: "KC721",
                fromAirport: "ALA", fromCity: "Almaty",
                toAirport: "DXB", toCity: "Dubai",
                departureTime: "2026-08-10T08:30:00",
                arrivalTime: "2026-08-10T11:10:00",
                gate: "B12", seat: "14A",
                cabinClass: .business, durationMinutes: 280
            )
        ],
        hotelConfirmation: HotelConfirmationInfo(
            confirmationNumber: "HB-73921",
            passengerName: "Artem Bagin",
            hotelName: "Address Downtown Dubai",
            stars: 5,
            checkIn: "2026-08-10",
            checkOut: "2026-08-15",
            nights: 5,
            roomType: "Deluxe Room",
            address: "Downtown Dubai, Sheikh Mohammed bin Rashid Blvd"
        )
    ))
}
