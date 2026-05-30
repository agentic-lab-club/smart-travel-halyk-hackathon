import Foundation

struct ItinerarySegment: Codable, Equatable, Identifiable {
    var id: String { segmentId }

    let segmentId: String
    let type: SegmentType
    let title: String
    let date: String
    let dayNumber: Int
    let startTime: String?
    let endTime: String?
    let icon: String
    let status: SegmentStatus
    let linkedMarkerIds: [String]
    let linkedRouteIds: [String]
    let price: Money?
    let labels: [String]
    let description: String?
    let details: SegmentDetails
}
