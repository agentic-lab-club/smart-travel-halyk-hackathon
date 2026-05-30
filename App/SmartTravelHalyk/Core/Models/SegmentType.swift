import Foundation

enum SegmentType: String, Codable, CaseIterable {
    case arrival
    case transfer
    case checkIn = "check_in"
    case hotelStay = "hotel_stay"
    case dayItinerary = "day_itinerary"
    case activity
    case restaurant
    case event
    case intercityMovement = "intercity_movement"
    case carRental = "car_rental"
    case freeTime = "free_time"
    case checkout
    case departure
    case warning
    case cashbackChallenge = "cashback_challenge"
}
