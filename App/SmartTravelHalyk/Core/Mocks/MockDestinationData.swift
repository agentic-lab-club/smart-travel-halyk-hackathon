import Foundation

extension MockTravelData {
    static let destinations: [Destination] = [
        Destination(
            destinationId: "dest-istanbul",
            title: "Istanbul",
            countryCode: "TR",
            cities: ["Istanbul"],
            tags: ["food", "history", "sea", "shopping", "visa_free"],
            bestMonths: ["April", "May", "June", "September", "October"],
            visaByCitizenship: ["KZ": .visaFree, "UZ": .visaFree, "US": .eVisa]
        ),
        Destination(
            destinationId: "dest-tbilisi",
            title: "Tbilisi and Kakheti",
            countryCode: "GE",
            cities: ["Tbilisi", "Kakheti"],
            tags: ["food", "wine", "mountains", "budget_friendly"],
            bestMonths: ["May", "June", "September"],
            visaByCitizenship: ["KZ": .visaFree]
        )
    ]
}
