import Foundation

enum HotelReviewSource: String, Codable, CaseIterable {
    case booking = "Booking.com"
    case googleHotels = "Google Hotels"
    case tripadvisor = "Tripadvisor"
    case expedia = "Expedia"
    case agoda = "Agoda"
    case other = "Other"
}
