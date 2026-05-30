import Foundation

enum FlightDisplay {
    static func time(_ value: String) -> String {
        guard let separator = value.firstIndex(of: "T") else { return value }
        let afterT = value[value.index(after: separator)...]
        return String(afterT.prefix(5))
    }

    static func shortDate(_ value: String) -> String {
        let datePart = String(value.prefix(10))
        let pieces = datePart.split(separator: "-")
        guard pieces.count == 3 else { return datePart }
        return "\(monthName(String(pieces[1]))) \(Int(pieces[2]) ?? 0)"
    }

    static func duration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if hours == 0 { return "\(remainingMinutes)m" }
        if remainingMinutes == 0 { return "\(hours)h" }
        return "\(hours)h \(remainingMinutes)m"
    }

    static func monthName(_ month: String) -> String {
        switch month {
        case "01": return "Jan"
        case "02": return "Feb"
        case "03": return "Mar"
        case "04": return "Apr"
        case "05": return "May"
        case "06": return "Jun"
        case "07": return "Jul"
        case "08": return "Aug"
        case "09": return "Sep"
        case "10": return "Oct"
        case "11": return "Nov"
        case "12": return "Dec"
        default: return month
        }
    }
}

extension FlightInfo.CabinClass {
    var title: String {
        switch self {
        case .economy: return "Economy"
        case .business: return "Business"
        case .first: return "First"
        }
    }
}
