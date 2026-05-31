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

    init(
        userId: String,
        name: String,
        citizenship: String,
        homeCity: String,
        homeAirport: String,
        currency: CurrencyCode,
        preferredLanguage: PreferredLanguage,
        travelProfile: TravelProfile
    ) {
        self.userId = userId
        self.name = name
        self.citizenship = citizenship
        self.homeCity = homeCity
        self.homeAirport = homeAirport
        self.currency = currency
        self.preferredLanguage = preferredLanguage
        self.travelProfile = travelProfile
    }

    init(from decoder: Decoder) throws {
        enum CodingKeys: String, CodingKey {
            case userId
            case name
            case citizenship
            case homeCity
            case homeAirport
            case currency
            case preferredLanguage
            case travelProfile
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let userId = try container.decode(String.self, forKey: .userId)

        self.init(
            userId: userId,
            name: try container.decodeIfPresent(String.self, forKey: .name) ?? "Halyk Traveler",
            citizenship: try container.decode(String.self, forKey: .citizenship),
            homeCity: try container.decode(String.self, forKey: .homeCity),
            homeAirport: try container.decode(String.self, forKey: .homeAirport),
            currency: try container.decode(CurrencyCode.self, forKey: .currency),
            preferredLanguage: try container.decode(PreferredLanguage.self, forKey: .preferredLanguage),
            travelProfile: try container.decode(TravelProfile.self, forKey: .travelProfile)
        )
    }
}
