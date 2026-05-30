import Foundation

enum MarkerType: String, Codable, CaseIterable {
    case airport
    case hotel
    case attraction
    case event
    case restaurant
    case station
    case carRental = "car_rental"
    case transferPoint = "transfer_point"
    case cityStop = "city_stop"
    case custom
}
