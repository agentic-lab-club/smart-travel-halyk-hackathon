import SwiftUI

struct FlightChecklist: View {
    let plan: FlightPlan

    var body: some View {
        let items = checklistItems

        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Before flight")
                    .font(.subheadline.weight(.semibold))

                ForEach(items, id: \.title) { item in
                    HStack(spacing: 8) {
                        Image(systemName: item.icon)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                            .frame(width: 16)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.title)
                                .font(.caption.weight(.semibold))
                            Text(item.subtitle)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(12)
            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var checklistItems: [(icon: String, title: String, subtitle: String)] {
        var items: [(String, String, String)] = []

        if let checkoutTime = plan.checkoutTime {
            items.append(("door.right.hand.open", "Check out by \(checkoutTime)", "Keep luggage ready before the return route."))
        }

        if let leaveTime = plan.recommendedLeaveHotelTime {
            items.append(("figure.walk", "Leave hotel by \(leaveTime)", "Recommended buffer for airport transfer and security."))
        }

        return items
    }
}
