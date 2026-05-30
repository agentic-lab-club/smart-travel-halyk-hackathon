import Foundation

enum BudgetCategory: String, Codable, CaseIterable {
    case flights
    case hotels
    case localTransport = "local_transport"
    case intercityTransport = "intercity_transport"
    case food
    case activities
    case events
    case visa
    case insurance
    case souvenirs
    case buffer
    case cashbackDiscount = "cashback_discount"
}
