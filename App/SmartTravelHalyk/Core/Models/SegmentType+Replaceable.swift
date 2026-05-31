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

    var defaultIcon: String {
        switch self {
        case .arrival:             return "airplane.arrival"
        case .departure:           return "airplane.departure"
        case .transfer:            return "car.fill"
        case .checkIn:             return "key.fill"
        case .hotelStay:           return "bed.double.fill"
        case .dayItinerary:        return "map.fill"
        case .activity:            return "figure.walk"
        case .restaurant:          return "fork.knife"
        case .event:               return "star.fill"
        case .intercityMovement:   return "tram.fill"
        case .carRental:           return "car.fill"
        case .freeTime:            return "sun.horizon.fill"
        case .checkout:            return "door.right.hand.open"
        case .warning:             return "exclamationmark.triangle.fill"
        case .cashbackChallenge:   return "sparkles"
        }
    }
}
