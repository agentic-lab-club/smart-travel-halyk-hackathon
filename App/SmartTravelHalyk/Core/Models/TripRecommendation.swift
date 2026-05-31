import Foundation

struct TripRecommendation: Codable, Equatable, Identifiable {
    var id: String { tripId }

    let tripId: String
    let destinationName: String
    let destinationTitle: String
    let countryCode: String
    let cityCodes: [String]
    let startDate: String?
    let endDate: String?
    let durationDays: Int
    let imageUrl: String?
    let estimatedTotalCost: EstimatedMoney
    let cashbackEstimate: CashbackEstimate?
    let mainReason: String
    let reasonLabels: [String]
    let recommendationType: RecommendationType
    let score: Double

    init(
        tripId: String,
        destinationName: String,
        destinationTitle: String,
        countryCode: String,
        cityCodes: [String],
        startDate: String?,
        endDate: String?,
        durationDays: Int,
        imageUrl: String?,
        estimatedTotalCost: EstimatedMoney,
        cashbackEstimate: CashbackEstimate?,
        mainReason: String,
        reasonLabels: [String],
        recommendationType: RecommendationType,
        score: Double
    ) {
        self.tripId = tripId
        self.destinationName = destinationName
        self.destinationTitle = destinationTitle
        self.countryCode = countryCode
        self.cityCodes = cityCodes
        self.startDate = startDate
        self.endDate = endDate
        self.durationDays = durationDays
        self.imageUrl = imageUrl
        self.estimatedTotalCost = estimatedTotalCost
        self.cashbackEstimate = cashbackEstimate
        self.mainReason = mainReason
        self.reasonLabels = reasonLabels
        self.recommendationType = recommendationType
        self.score = score
    }

    init(from decoder: Decoder) throws {
        enum CodingKeys: String, CodingKey {
            case tripId
            case destinationName
            case destinationTitle
            case countryCode
            case cityCodes
            case startDate
            case endDate
            case durationDays
            case imageUrl
            case estimatedTotalCost
            case cashbackEstimate
            case mainReason
            case reasonLabels
            case recommendationType
            case score
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let destinationTitle = try container.decode(String.self, forKey: .destinationTitle)

        self.init(
            tripId: try container.decode(String.self, forKey: .tripId),
            destinationName: try container.decodeIfPresent(String.self, forKey: .destinationName) ?? destinationTitle,
            destinationTitle: destinationTitle,
            countryCode: try container.decode(String.self, forKey: .countryCode),
            cityCodes: try container.decode([String].self, forKey: .cityCodes),
            startDate: try container.decodeIfPresent(String.self, forKey: .startDate),
            endDate: try container.decodeIfPresent(String.self, forKey: .endDate),
            durationDays: try container.decode(Int.self, forKey: .durationDays),
            imageUrl: try container.decodeIfPresent(String.self, forKey: .imageUrl),
            estimatedTotalCost: try container.decode(EstimatedMoney.self, forKey: .estimatedTotalCost),
            cashbackEstimate: try container.decodeIfPresent(CashbackEstimate.self, forKey: .cashbackEstimate),
            mainReason: try container.decode(String.self, forKey: .mainReason),
            reasonLabels: try container.decode([String].self, forKey: .reasonLabels),
            recommendationType: try container.decode(RecommendationType.self, forKey: .recommendationType),
            score: try container.decode(Double.self, forKey: .score)
        )
    }
}
