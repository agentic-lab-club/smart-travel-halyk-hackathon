import SwiftUI

struct MissingFieldsRow: View {
    let fields: [MissingField]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(fields) { field in
                    Text(field.label)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(.orange.opacity(0.15), in: .capsule)
                        .foregroundStyle(.orange)
                }
            }
        }
    }
}
