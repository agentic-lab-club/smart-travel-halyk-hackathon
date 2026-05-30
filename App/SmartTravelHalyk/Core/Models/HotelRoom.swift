import Foundation

struct HotelRoom: Codable, Equatable, Identifiable {
    enum BedType: String, Codable, CaseIterable {
        case single
        case double
        case queen
        case king
        case twin
        case multiple
    }

    var id: String { roomId }

    let roomId: String
    let name: String
    let description: String?
    let imageUrl: String?
    let capacity: Int
    let bedType: BedType?
    let areaSqm: Double?
    let refundable: Bool?
    let breakfastIncluded: Bool?
    let pricePerNight: Money
    let totalPrice: Money
    let labels: [String]
    let tradeoffLabel: String?
}
