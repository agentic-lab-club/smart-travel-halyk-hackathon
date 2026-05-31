import SwiftUI

struct HotelCompactContent: View {
    let details: HotelDetails
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let d = details.district { DetailRow(icon: "mappin", label: d) }
            if let r = details.selectedRoomName { DetailRow(icon: "bed.double.fill", label: r) }
            DetailRow(icon: "moon.fill", label: "\(details.nights) nights · \(details.pricePerNight.displayString)/night")
            if let d = details.downgradeLabel { DetailRow(icon: "arrow.down.circle", label: d) }
            if let u = details.upgradeLabel { DetailRow(icon: "arrow.up.circle", label: u) }
        }.padding(.top, 4)
    }
}
