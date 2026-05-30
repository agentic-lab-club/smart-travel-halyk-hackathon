import Foundation

enum SegmentDetails: Codable, Equatable {
    case arrival(ArrivalDetails)
    case departure(DepartureDetails)
    case transfer(TransferDetails)
    case hotel(HotelDetails)
    case dayItinerary(DayItineraryDetails)
    case activity(ActivityDetails)
    case intercityMovement(IntercityMovementDetails)
    case carRental(CarRentalDetails)
    case warning(WarningDetails)
    case cashbackChallenge(CashbackChallengeDetails)
    case custom([String: String])

    enum Kind: String, Codable {
        case arrival
        case departure
        case transfer
        case hotel
        case dayItinerary = "day_itinerary"
        case activity
        case intercityMovement = "intercity_movement"
        case carRental = "car_rental"
        case warning
        case cashbackChallenge = "cashback_challenge"
        case custom
    }

    private enum CodingKeys: String, CodingKey {
        case kind
        case payload
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)

        switch kind {
        case .arrival:
            self = .arrival(try container.decode(ArrivalDetails.self, forKey: .payload))
        case .departure:
            self = .departure(try container.decode(DepartureDetails.self, forKey: .payload))
        case .transfer:
            self = .transfer(try container.decode(TransferDetails.self, forKey: .payload))
        case .hotel:
            self = .hotel(try container.decode(HotelDetails.self, forKey: .payload))
        case .dayItinerary:
            self = .dayItinerary(try container.decode(DayItineraryDetails.self, forKey: .payload))
        case .activity:
            self = .activity(try container.decode(ActivityDetails.self, forKey: .payload))
        case .intercityMovement:
            self = .intercityMovement(try container.decode(IntercityMovementDetails.self, forKey: .payload))
        case .carRental:
            self = .carRental(try container.decode(CarRentalDetails.self, forKey: .payload))
        case .warning:
            self = .warning(try container.decode(WarningDetails.self, forKey: .payload))
        case .cashbackChallenge:
            self = .cashbackChallenge(try container.decode(CashbackChallengeDetails.self, forKey: .payload))
        case .custom:
            self = .custom(try container.decode([String: String].self, forKey: .payload))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .arrival(let payload):
            try container.encode(Kind.arrival, forKey: .kind)
            try container.encode(payload, forKey: .payload)
        case .departure(let payload):
            try container.encode(Kind.departure, forKey: .kind)
            try container.encode(payload, forKey: .payload)
        case .transfer(let payload):
            try container.encode(Kind.transfer, forKey: .kind)
            try container.encode(payload, forKey: .payload)
        case .hotel(let payload):
            try container.encode(Kind.hotel, forKey: .kind)
            try container.encode(payload, forKey: .payload)
        case .dayItinerary(let payload):
            try container.encode(Kind.dayItinerary, forKey: .kind)
            try container.encode(payload, forKey: .payload)
        case .activity(let payload):
            try container.encode(Kind.activity, forKey: .kind)
            try container.encode(payload, forKey: .payload)
        case .intercityMovement(let payload):
            try container.encode(Kind.intercityMovement, forKey: .kind)
            try container.encode(payload, forKey: .payload)
        case .carRental(let payload):
            try container.encode(Kind.carRental, forKey: .kind)
            try container.encode(payload, forKey: .payload)
        case .warning(let payload):
            try container.encode(Kind.warning, forKey: .kind)
            try container.encode(payload, forKey: .payload)
        case .cashbackChallenge(let payload):
            try container.encode(Kind.cashbackChallenge, forKey: .kind)
            try container.encode(payload, forKey: .payload)
        case .custom(let payload):
            try container.encode(Kind.custom, forKey: .kind)
            try container.encode(payload, forKey: .payload)
        }
    }
}
