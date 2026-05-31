import SwiftUI

struct HotelDetailLocationSection: View {
    let hotel: HotelDetails
    let full: HotelDetailsFull

    private var loc: HotelLocationInfo { full.locationInfo }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HotelSectionHeading("Location")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                if let km = loc.distanceToAirportKm {
                    LocationTile(icon: "airplane", label: "Airport", value: String(format: "%.1f km", km))
                }
                if let taxi = loc.taxiFromAirport {
                    LocationTile(icon: "car.fill", label: "Taxi from airport", value: taxi.displayString)
                }
                if let km = loc.distanceToMainClusterKm {
                    LocationTile(icon: "figure.walk", label: "To main cluster", value: String(format: "%.1f km", km))
                }
                if let km = loc.distanceToBeachKm {
                    LocationTile(icon: "water.waves", label: "To beach", value: String(format: "%.1f km", km))
                }
                if let taxi = loc.averageTaxiToActivities {
                    LocationTile(icon: "car.circle.fill", label: "Avg taxi", value: taxi.displayString)
                }
                if let count = loc.walkablePlacesCount {
                    LocationTile(icon: "map.fill", label: "Walkable places", value: "\(count)")
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HotelSectionSubheading("Scores")
                HStack(spacing: 10) {
                    if let score = loc.locationScore {
                        ScoreBadge(label: "Location", score: score, scale: 10)
                    }
                    if let score = loc.priceScore {
                        ScoreBadge(label: "Price", score: score, scale: 10)
                    }
                    if let score = loc.convenienceScore {
                        ScoreBadge(label: "Convenience", score: score, scale: 10)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
