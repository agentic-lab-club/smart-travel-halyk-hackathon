import Foundation

struct WeatherInfo: Codable, Equatable {
    enum Condition: String, Codable, CaseIterable {
        case sunny
        case cloudy
        case rain
        case snow
        case windy
        case unknown
    }

    let temperatureC: Int
    let condition: Condition
    let rainChancePercent: Int?
    let windKph: Int?
}
