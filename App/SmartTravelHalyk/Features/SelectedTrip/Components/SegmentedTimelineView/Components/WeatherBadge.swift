import SwiftUI

struct WeatherBadge: View {
    let weather: WeatherInfo
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption.weight(.medium)).foregroundStyle(color)
            Text("\(weather.temperatureC)°C").font(.caption.weight(.semibold))
            if let rain = weather.rainChancePercent, rain > 20 {
                Text("· Rain \(rain)%").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(color.opacity(0.12), in: Capsule())
    }

    private var icon: String {
        switch weather.condition {
        case .sunny: return "sun.max.fill"; case .cloudy: return "cloud.fill"
        case .rain: return "cloud.rain.fill"; case .snow: return "snowflake"
        case .windy: return "wind"; case .unknown: return "questionmark.circle"
        }
    }

    private var color: Color {
        switch weather.condition {
        case .sunny: return .orange; case .cloudy: return .gray
        case .rain: return .blue; case .snow: return .cyan
        case .windy: return .teal; case .unknown: return .gray
        }
    }
}
