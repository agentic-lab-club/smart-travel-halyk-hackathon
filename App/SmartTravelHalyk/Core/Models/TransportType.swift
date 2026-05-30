import Foundation

enum TransportType: String, Codable, CaseIterable {
    case flight
    case taxi
    case publicTransport = "public_transport"
    case car
    case walk
    case train
    case bus
    case shuttle
    case rentalCar = "rental_car"
}
