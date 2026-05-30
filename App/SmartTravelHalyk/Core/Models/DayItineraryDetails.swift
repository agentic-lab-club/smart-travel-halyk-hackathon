import Foundation

struct DayItineraryDetails: Codable, Equatable {
    enum Pace: String, Codable, CaseIterable {
        case slow
        case medium
        case fast
    }

    let city: String
    let experienceCount: Int
    let weather: WeatherInfo?
    let pace: Pace
    let overloadScore: Double
    let activities: [ActivityItem]
}
