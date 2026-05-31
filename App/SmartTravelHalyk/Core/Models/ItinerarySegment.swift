import Foundation
import UIKit

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

    private enum CodingKeys: String, CodingKey {
        case segmentId
        case type
        case title
        case date
        case dayNumber
        case startTime
        case endTime
        case icon
        case status
        case linkedMarkerIds
        case linkedRouteIds
        case price
        case labels
        case description
        case details
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        segmentId = try container.decode(String.self, forKey: .segmentId)
        type = try container.decode(SegmentType.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        date = try container.decode(String.self, forKey: .date)
        dayNumber = try container.decode(Int.self, forKey: .dayNumber)
        startTime = try container.decodeIfPresent(String.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(String.self, forKey: .endTime)
        icon = try container.decodeIfPresent(String.self, forKey: .icon) ?? ""
        status = try container.decode(SegmentStatus.self, forKey: .status)
        linkedMarkerIds = try container.decodeIfPresent([String].self, forKey: .linkedMarkerIds) ?? []
        linkedRouteIds = try container.decodeIfPresent([String].self, forKey: .linkedRouteIds) ?? []
        price = try container.decodeIfPresent(Money.self, forKey: .price)
        labels = try container.decodeIfPresent([String].self, forKey: .labels) ?? []
        description = try container.decodeIfPresent(String.self, forKey: .description)
        details = try container.decode(SegmentDetails.self, forKey: .details)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(segmentId, forKey: .segmentId)
        try container.encode(type, forKey: .type)
        try container.encode(title, forKey: .title)
        try container.encode(date, forKey: .date)
        try container.encode(dayNumber, forKey: .dayNumber)
        try container.encodeIfPresent(startTime, forKey: .startTime)
        try container.encodeIfPresent(endTime, forKey: .endTime)
        try container.encode(icon, forKey: .icon)
        try container.encode(status, forKey: .status)
        try container.encode(linkedMarkerIds, forKey: .linkedMarkerIds)
        try container.encode(linkedRouteIds, forKey: .linkedRouteIds)
        try container.encodeIfPresent(price, forKey: .price)
        try container.encode(labels, forKey: .labels)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(details, forKey: .details)
    }

    var effectiveIcon: String {
        let trimmed = icon.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, UIImage(systemName: trimmed) != nil else {
            return type.defaultIcon
        }
        return trimmed
    }

    init(
        segmentId: String,
        type: SegmentType,
        title: String,
        date: String,
        dayNumber: Int,
        startTime: String?,
        endTime: String?,
        icon: String,
        status: SegmentStatus,
        linkedMarkerIds: [String],
        linkedRouteIds: [String],
        price: Money?,
        labels: [String],
        description: String?,
        details: SegmentDetails
    ) {
        self.segmentId = segmentId
        self.type = type
        self.title = title
        self.date = date
        self.dayNumber = dayNumber
        self.startTime = startTime
        self.endTime = endTime
        self.icon = icon
        self.status = status
        self.linkedMarkerIds = linkedMarkerIds
        self.linkedRouteIds = linkedRouteIds
        self.price = price
        self.labels = labels
        self.description = description
        self.details = details
    }
}
