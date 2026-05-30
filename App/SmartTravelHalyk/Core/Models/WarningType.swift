import Foundation

enum WarningType: String, Codable, CaseIterable {
    case routeOverloaded = "route_overloaded"
    case airportFarFromHotel = "airport_far_from_hotel"
    case expensiveTransfer = "expensive_transfer"
    case visaUncertain = "visa_uncertain"
    case weatherRisk = "weather_risk"
    case hotelFarFromActivities = "hotel_far_from_activities"
    case lowConfidencePrice = "low_confidence_price"
    case notEnoughTimeBetweenSegments = "not_enough_time_between_segments"
}
