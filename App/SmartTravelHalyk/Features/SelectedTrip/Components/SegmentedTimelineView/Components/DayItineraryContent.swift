import SwiftUI

struct DayItineraryContent: View {
    let details: DayItineraryDetails
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let weather = details.weather { WeatherBadge(weather: weather).padding(.top, 4) }
            ForEach(details.activities) { activity in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: iconFor(activity.type))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.green)
                        .frame(width: 16)
                    VStack(alignment: .leading, spacing: 1) {
                        HStack {
                            Text(activity.title).font(.caption.weight(.medium))
                            if let t = activity.startTime { Text(t).font(.caption2).foregroundStyle(.secondary) }
                        }
                        if let p = activity.price { Text(p.displayString).font(.caption2).foregroundStyle(.secondary) }
                    }
                }
            }
        }
    }

    private func iconFor(_ type: ActivityItem.ActivityType) -> String {
        switch type {
        case .attraction: return "binoculars.fill"
        case .event: return "star.fill"
        case .restaurant: return "fork.knife"
        case .shopping: return "bag.fill"
        case .freeTime: return "sun.horizon.fill"
        }
    }
}
