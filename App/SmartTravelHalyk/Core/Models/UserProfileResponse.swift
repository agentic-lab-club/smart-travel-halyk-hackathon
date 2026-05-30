import Foundation

struct UserProfileResponse: Codable, Equatable {
    enum PreferredLanguage: String, Codable, CaseIterable {
        case ru
        case kk
        case en
    }

    let userId: String
    let name: String
    let citizenship: String
    let homeCity: String
    let homeAirport: String
    let currency: CurrencyCode
    let preferredLanguage: PreferredLanguage
    let travelProfile: TravelProfile
}
