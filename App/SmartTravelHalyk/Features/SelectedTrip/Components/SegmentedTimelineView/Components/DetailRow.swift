import SwiftUI

struct DetailRow: View {
    let icon: String
    let label: String
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: icon).font(.caption2.weight(.medium)).foregroundStyle(.green).frame(width: 14)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }
}
