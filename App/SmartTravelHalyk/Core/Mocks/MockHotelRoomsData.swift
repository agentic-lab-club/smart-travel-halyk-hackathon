import Foundation

extension MockTravelData {
    static let hotelRooms: [HotelRoom] = [
        HotelRoom(
            roomId: "room-economy-double",
            name: "Economy Double Room",
            description: "Compact room for travelers who plan to spend most time outside.",
            imageUrl: "https://images.unsplash.com/photo-1631049307264-da0ec9d70304",
            capacity: 2,
            bedType: .double,
            areaSqm: 17,
            refundable: false,
            breakfastIncluded: true,
            pricePerNight: Money(amount: 56_000, currency: .kzt),
            totalPrice: Money(amount: 224_000, currency: .kzt),
            labels: ["Cheapest", "Breakfast"],
            tradeoffLabel: "Save money, smaller room."
        ),
        HotelRoom(
            roomId: "room-comfort-queen",
            name: "Comfort Queen Room",
            description: "Balanced pick with more space, breakfast and free cancellation.",
            imageUrl: "https://images.unsplash.com/photo-1611892440504-42a792e24d32",
            capacity: 2,
            bedType: .queen,
            areaSqm: 24,
            refundable: true,
            breakfastIncluded: true,
            pricePerNight: Money(amount: 68_000, currency: .kzt),
            totalPrice: Money(amount: 272_000, currency: .kzt),
            labels: ["Selected", "Refundable", "Breakfast"],
            tradeoffLabel: "Best balance."
        ),
        HotelRoom(
            roomId: "room-bosphorus-view",
            name: "Bosphorus View Room",
            description: "Larger upper-floor room with partial Bosphorus view.",
            imageUrl: "https://images.unsplash.com/photo-1590490360182-c33d57733427",
            capacity: 2,
            bedType: .king,
            areaSqm: 29,
            refundable: true,
            breakfastIncluded: true,
            pricePerNight: Money(amount: 89_500, currency: .kzt),
            totalPrice: Money(amount: 358_000, currency: .kzt),
            labels: ["Upgrade", "View", "Refundable"],
            tradeoffLabel: "More comfort and view for a higher total."
        )
    ]
}
