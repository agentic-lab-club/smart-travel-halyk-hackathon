import SwiftUI

struct StarRating: View {
    let count: Int
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<min(count, 5), id: \.self) { _ in
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
            }
        }
    }
}
