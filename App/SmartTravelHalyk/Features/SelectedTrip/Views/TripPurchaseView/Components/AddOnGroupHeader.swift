import SwiftUI

struct AddOnGroupHeader: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        Label(title, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(color)
    }
}
