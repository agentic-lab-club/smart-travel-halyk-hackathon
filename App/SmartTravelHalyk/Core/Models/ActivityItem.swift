import Foundation

struct ActivityItem: Codable, Equatable, Identifiable {
    enum ActivityType: String, Codable, CaseIterable {
        case attraction
        case event
        case restaurant
        case shopping
        case freeTime = "free_time"
    }

    var id: String { activityId }

    let activityId: String
    let title: String
    let type: ActivityType
    let startTime: String?
    let durationMinutes: Int
    let price: Money?
    let markerId: String?
    let reason: String?
}
