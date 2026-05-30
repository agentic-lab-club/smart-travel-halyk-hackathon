import SwiftUI

extension TripMode {
    var title: String {
        switch self {
        case .economy:
            return "economy"
        case .balanced:
            return "balanced"
        case .comfort:
            return "comfort"
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
        "\(Int(amount).formatted(.number.grouping(.automatic))) \(currency.rawValue)"
    }
}
