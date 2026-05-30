import Foundation

extension MockTravelData {
    static let visaInfo = VisaInfo(
        citizenship: "KZ",
        destinationCountry: "TR",
        status: .visaFree,
        required: false,
        estimatedCost: nil,
        processingTimeDays: nil,
        notes: "Kazakhstan citizens can enter Turkey visa-free for short tourism trips.",
        confidence: .high
    )
}
