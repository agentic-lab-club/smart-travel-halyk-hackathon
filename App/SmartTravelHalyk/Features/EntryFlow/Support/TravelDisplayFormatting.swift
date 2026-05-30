import SwiftUI

extension TripMode {
    var title: String {
        switch self {
        case .economy:  return "Economy"
        case .balanced: return "Balanced"
        case .comfort:  return "Comfort"
        }
    }

    var fullTitle: String {
        switch self {
        case .economy:  return "Budget trip"
        case .balanced: return "Balanced"
        case .comfort:  return "Comfort"
        }
    }
}

extension RecommendationType {
    var title: String {
        switch self {
        case .similarToPrevious:
            return "Similar"
        case .oppositeToPrevious:
            return "New style"
        case .seasonal:
            return "Seasonal"
        case .eventBased:
            return "Events"
        case .budgetFriendly:
            return "Budget"
        case .cashbackBoosted:
            return "Cashback"
        case .visaFree:
            return "Visa-free"
        case .weekendTrip:
            return "Weekend"
        }
    }
}

extension RecommendationFeedSegment {
    var title: String {
        switch self {
        case .similar:
            return "Similar"
        case .newStyle:
            return "New Style"
        case .seasonal:
            return "Seasonal"
        }
    }

    var subtitle: String {
        switch self {

        case .similar:
            return "Trips close to what you already liked and paid for before."
        case .newStyle:
            return "Opposite picks when you want something outside your pattern."
        case .seasonal:
            return "Timely routes based on weather, events and best travel windows."

        }
    }

    var systemImage: String {
        switch self {

        case .similar:
            return "heart.fill"
        case .newStyle:
            return "shuffle"
        case .seasonal:
            return "sun.max.fill"
     
        }
    }
}

extension Money {
    var displayString: String {
        "\(Int(amount).formatted(.number.grouping(.automatic))) \(currency.rawValue)"
    }
}

extension EstimatedMoney {
    var displayString: String {
        "\(Int(amount).formatted(.number.grouping(.automatic))) \(currency.rawValue)"
    }
}

extension CashbackEstimate {
    var displayString: String {
        "-\(percent.formatted(.number.precision(.fractionLength(0 ... 1))))%"
    }
}
