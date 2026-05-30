import Foundation

struct HotelDetailsFull: Codable, Equatable, Identifiable {
    var id: String { hotelId }

    let hotelId: String
    let name: String
    let city: String
    let district: String?
    let address: String?
    let lat: Double
    let lng: Double
    let stars: Int?
    let mainImageUrl: String?
    let rating: HotelRating
    let sourceRatings: [HotelSourceRating]
    let reviewSummary: HotelReviewSummary
    let reviewsBySource: [HotelReviewsSourceGroup]
    let rooms: [HotelRoom]
    let selectedRoomId: String
    let roomOptions: HotelRoomOptions
    let locationInfo: HotelLocationInfo
    let reason: String
}
