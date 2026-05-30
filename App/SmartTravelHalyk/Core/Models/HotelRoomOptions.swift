import Foundation

struct HotelRoomOptions: Codable, Equatable {
    let selectedRoomId: String
    let downgradeRoomId: String?
    let upgradeRoomId: String?
    let selectedReason: String
    let downgradeLabel: String?
    let upgradeLabel: String?
}
