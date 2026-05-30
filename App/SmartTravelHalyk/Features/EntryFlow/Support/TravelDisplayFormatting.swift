import SwiftUI

extension TripMode {
    var title: String {
        switch self {
        case .economy:
            return "Economy"
        case .balanced:
            return "Balanced"
        case .comfort:
            return "Comfort"
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
        case .forYou:
            return "For You"
        case .similar:
            return "Similar"
        case .newStyle:
            return "New Style"
        case .seasonal:
            return "Seasonal"
        case .cashback:
            return "Cashback"
        }
    }

    var subtitle: String {
        switch self {
        case .forYou:
            return "Best overall matches from your profile, budget and card perks."
        case .similar:
            return "Trips close to what you already liked and paid for before."
        case .newStyle:
            return "Opposite picks when you want something outside your pattern."
        case .seasonal:
            return "Timely routes based on weather, events and best travel windows."
        case .cashback:
            return "Destinations where Halyk card value is strongest."
        }
    }

    var systemImage: String {
        switch self {
        case .forYou:
            return "sparkles"
        case .similar:
            return "heart.fill"
        case .newStyle:
            return "shuffle"
        case .seasonal:
            return "sun.max.fill"
        case .cashback:
            return "creditcard.fill"
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
        "-\(percent.formatted(.number.precision(.fractionLength(0...1))))%"
    }
}
