import Foundation

enum VisaStatus: String, Codable, CaseIterable {
    case visaFree = "visa_free"
    case visaOnArrival = "visa_on_arrival"
    case eVisa = "e_visa"
    case visaRequired = "visa_required"
    case unknown
}
