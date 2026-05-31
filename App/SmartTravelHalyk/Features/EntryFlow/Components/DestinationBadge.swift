import SwiftUI

struct DestinationBadge: View {
    let countryCode: String

    var body: some View {
        Text(countryCode)
            .font(.caption.bold())
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(.green, in: .rect(cornerRadius: 8))
    }
}
