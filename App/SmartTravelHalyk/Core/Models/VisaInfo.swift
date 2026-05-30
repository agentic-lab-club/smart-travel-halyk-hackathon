import Foundation

struct VisaInfo: Codable, Equatable {
    let citizenship: String
    let destinationCountry: String
    let status: VisaStatus
    let required: Bool
    let estimatedCost: Money?
    let processingTimeDays: Int?
    let notes: String?
    let confidence: Confidence
}
