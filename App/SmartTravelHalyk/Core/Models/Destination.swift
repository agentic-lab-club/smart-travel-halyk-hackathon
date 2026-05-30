import Foundation

struct Destination: Codable, Equatable, Identifiable {
    var id: String { destinationId }

    let destinationId: String
    let title: String
    let countryCode: String
    let cities: [String]
    let tags: [String]
    let bestMonths: [String]
    let visaByCitizenship: [String: VisaStatus]
}
