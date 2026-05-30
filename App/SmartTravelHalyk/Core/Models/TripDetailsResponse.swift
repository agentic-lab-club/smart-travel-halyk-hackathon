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
}
