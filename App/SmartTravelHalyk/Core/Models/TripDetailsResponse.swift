import Foundation

struct TripDetailsResponse: Codable, Equatable, Identifiable {
    var id: String { tripId }

    let tripId: String
    let title: String
    let subtitle: String
    let startDate: String
    let endDate: String
    let durationDays: Int
    let peopleCount: Int
    let currency: CurrencyCode
    let selectedMode: TripMode
    let availableModes: [TripMode]
    let summary: TripSummary
    let routeNavigator: [RouteStop]
    let map: TripMap
    let segments: [ItinerarySegment]
    let budget: BudgetBreakdown
    let modeVariants: [TripMode: ModeVariant]
    let visa: VisaInfo?
    let cashback: CashbackInfo?
    let challenges: [TravelChallenge]
    let warnings: [SmartWarning]

    private enum CodingKeys: String, CodingKey {
        case tripId
        case title
        case subtitle
        case startDate
        case endDate
        case durationDays
        case peopleCount
        case currency
        case selectedMode
        case availableModes
        case summary
        case routeNavigator
        case map
        case segments
        case budget
        case modeVariants
        case visa
        case cashback
        case challenges
        case warnings
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tripId = try container.decode(String.self, forKey: .tripId)
        title = try container.decode(String.self, forKey: .title)
        subtitle = try container.decode(String.self, forKey: .subtitle)
        startDate = try container.decode(String.self, forKey: .startDate)
        endDate = try container.decode(String.self, forKey: .endDate)
        durationDays = try container.decode(Int.self, forKey: .durationDays)
        peopleCount = try container.decode(Int.self, forKey: .peopleCount)
        currency = try container.decode(CurrencyCode.self, forKey: .currency)
        selectedMode = try container.decode(TripMode.self, forKey: .selectedMode)
        availableModes = try container.decode([TripMode].self, forKey: .availableModes)
        summary = try container.decode(TripSummary.self, forKey: .summary)
        routeNavigator = try container.decode([RouteStop].self, forKey: .routeNavigator)
        map = try container.decode(TripMap.self, forKey: .map)
        segments = try container.decode([ItinerarySegment].self, forKey: .segments)
        budget = try container.decode(BudgetBreakdown.self, forKey: .budget)
        let variantsByKey = try container.decodeIfPresent([String: ModeVariant].self, forKey: .modeVariants) ?? [:]
        var parsedVariants: [TripMode: ModeVariant] = [:]
        for (key, value) in variantsByKey {
            if let mode = TripMode(rawValue: key) {
                parsedVariants[mode] = value
            }
        }
        modeVariants = parsedVariants
        visa = try container.decodeIfPresent(VisaInfo.self, forKey: .visa)
        cashback = try container.decodeIfPresent(CashbackInfo.self, forKey: .cashback)
        challenges = try container.decode([TravelChallenge].self, forKey: .challenges)
        warnings = try container.decode([SmartWarning].self, forKey: .warnings)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(tripId, forKey: .tripId)
        try container.encode(title, forKey: .title)
        try container.encode(subtitle, forKey: .subtitle)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(durationDays, forKey: .durationDays)
        try container.encode(peopleCount, forKey: .peopleCount)
        try container.encode(currency, forKey: .currency)
        try container.encode(selectedMode, forKey: .selectedMode)
        try container.encode(availableModes, forKey: .availableModes)
        try container.encode(summary, forKey: .summary)
        try container.encode(routeNavigator, forKey: .routeNavigator)
        try container.encode(map, forKey: .map)
        try container.encode(segments, forKey: .segments)
        try container.encode(budget, forKey: .budget)
        let variantsByKey = Dictionary(uniqueKeysWithValues: modeVariants.map { ($0.key.rawValue, $0.value) })
        try container.encode(variantsByKey, forKey: .modeVariants)
        try container.encodeIfPresent(visa, forKey: .visa)
        try container.encodeIfPresent(cashback, forKey: .cashback)
        try container.encode(challenges, forKey: .challenges)
        try container.encode(warnings, forKey: .warnings)
    }

    init(
        tripId: String,
        title: String,
        subtitle: String,
        startDate: String,
        endDate: String,
        durationDays: Int,
        peopleCount: Int,
        currency: CurrencyCode,
        selectedMode: TripMode,
        availableModes: [TripMode],
        summary: TripSummary,
        routeNavigator: [RouteStop],
        map: TripMap,
        segments: [ItinerarySegment],
        budget: BudgetBreakdown,
        modeVariants: [TripMode: ModeVariant],
        visa: VisaInfo?,
        cashback: CashbackInfo?,
        challenges: [TravelChallenge],
        warnings: [SmartWarning]
    ) {
        self.tripId = tripId
        self.title = title
        self.subtitle = subtitle
        self.startDate = startDate
        self.endDate = endDate
        self.durationDays = durationDays
        self.peopleCount = peopleCount
        self.currency = currency
        self.selectedMode = selectedMode
        self.availableModes = availableModes
        self.summary = summary
        self.routeNavigator = routeNavigator
        self.map = map
        self.segments = segments
        self.budget = budget
        self.modeVariants = modeVariants
        self.visa = visa
        self.cashback = cashback
        self.challenges = challenges
        self.warnings = warnings
    }
}
