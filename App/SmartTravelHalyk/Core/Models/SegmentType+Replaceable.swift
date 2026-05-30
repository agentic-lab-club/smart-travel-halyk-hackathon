import Foundation

extension SegmentType {
    /// Places the user can freely delete or swap via the AI chatbot.
    /// Fixed logistics (flights, hotel, transfers) are never replaceable.
    var isReplaceable: Bool {
        switch self {
        case .dayItinerary, .activity, .restaurant, .event, .freeTime:
            return true
        case .arrival, .departure, .transfer, .checkIn, .hotelStay,
             .checkout, .intercityMovement, .carRental, .warning, .cashbackChallenge:
            return false
        }
    }
}
