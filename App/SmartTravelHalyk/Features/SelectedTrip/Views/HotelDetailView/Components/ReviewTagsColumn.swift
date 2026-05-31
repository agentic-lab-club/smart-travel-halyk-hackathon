import SwiftUI

struct ReviewTagsColumn: View {
    let icon: String
    let color: Color
    let tags: [String]
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
