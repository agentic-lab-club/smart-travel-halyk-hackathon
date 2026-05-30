import Foundation

struct TripSummary: Codable, Equatable {
    let estimatedTotalCost: Money
    let estimatedTotalCashback: Money?
    let weatherSummary: String?
    let visaStatus: VisaStatus?
    let mainLabels: [String]
}
