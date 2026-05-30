import Foundation

extension MockTravelData {
    static let smartWarnings: [SmartWarning] = [
        SmartWarning(
            type: .weatherRisk,
            severity: .low,
            segmentId: "segment-day-2",
            message: "Light rain risk on day 2. Spice Bazaar works as indoor backup."
        ),
        SmartWarning(
            type: .notEnoughTimeBetweenSegments,
            severity: .medium,
            segmentId: "segment-transfer",
            message: "If flight is delayed by 45+ minutes, move hotel check-in before lunch."
        )
    ]
}
