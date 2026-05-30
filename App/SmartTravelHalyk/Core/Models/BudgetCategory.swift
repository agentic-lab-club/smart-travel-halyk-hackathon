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

extension BudgetCategory {
    var icon: String {
        switch self {
        case .flights:            return "airplane"
        case .hotels:             return "bed.double.fill"
        case .localTransport:     return "bus.fill"
        case .intercityTransport: return "train.side.front.car"
        case .food:               return "fork.knife"
        case .activities:         return "binoculars.fill"
        case .events:             return "ticket.fill"
        case .visa:               return "doc.badge.arrow.up"
        case .insurance:          return "shield.fill"
        case .souvenirs:          return "bag.fill"
        case .buffer:             return "plus.circle.fill"
        case .cashbackDiscount:   return "creditcard.fill"
        }
    }
}
