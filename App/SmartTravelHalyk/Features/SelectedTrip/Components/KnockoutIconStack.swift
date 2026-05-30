import SwiftUI

/// A row of overlapping icon circles where each circle punches a clean gap
/// through the circle behind it using `.blendMode(.destinationOut)`.
///
/// `icons` are ordered front → back (index 0 is the topmost circle).
struct KnockoutIconStack: View {
    let icons: [String]
    var circleSize: CGFloat = 44
    var shift: CGFloat = 30        // horizontal step between circle centres
    var knockoutPadding: CGFloat = 3  // extra radius of the punch-hole gap
    var circleColor: Color = Color(.secondarySystemGroupedBackground)
    var iconColor: Color = .primary

    /// Total width occupied by all circles.
    private var totalWidth: CGFloat {
        circleSize + CGFloat(max(0, icons.count - 1)) * shift
    }

    var body: some View {
        // Use a plain ZStack (center-aligned) and offset each circle so the
        // cluster is centred inside the frame — that way the leading gap
        // equals the trailing gap and no circle gets extra margin.
        ZStack {
            ForEach(icons.indices.reversed(), id: \.self) { idx in
                circleLayer(icon: icons[idx], idx: idx)
            }
        }
        .frame(width: totalWidth, height: circleSize)
    }

    /// Horizontal offset of circle `idx` so the whole cluster is centred.
    /// idx 0 = front/leftmost, idx (count-1) = back/rightmost.
    private func centredOffset(for idx: Int) -> CGFloat {
        // Without centering, idx 0 would sit at x=0 (leading edge).
        // Shift every circle left by half the total width so the cluster
        // sits in the middle of the frame.
        CGFloat(idx) * shift - (totalWidth - circleSize) / 2
    }

    // MARK: - Private

    @ViewBuilder
    private func circleLayer(icon: String, idx: Int) -> some View {
        ZStack {
            // ── The circle itself ──────────────────────────────────
            Circle()
                .fill(circleColor)
                .frame(width: circleSize, height: circleSize)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: circleSize * 0.38, weight: .semibold))
                        .foregroundStyle(iconColor)
                }

            // ── Knockout punch for the circle in front (at idx - 1) ─
            // idx 0 is the frontmost circle — nothing punches it.
            // For every other circle the circle directly in front of it
            // sits exactly `shift` points to the left, so the punch
            // offset relative to this circle's centre is always -shift.
            if idx > 0 {
                Circle()
                    .frame(
                        width:  circleSize + knockoutPadding * 2,
                        height: circleSize + knockoutPadding * 2
                    )
                    .offset(x: -shift)
                    .blendMode(.destinationOut)
            }
        }
        // compositingGroup isolates each layer so destinationOut only
        // erases pixels within that layer, not everything underneath.
        .compositingGroup()
        .offset(x: centredOffset(for: idx))
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 32) {
            KnockoutIconStack(
                icons: ["airplane", "key.fill", "building.columns.fill"],
                circleSize: 44,
                shift: 30
            )

            KnockoutIconStack(
                icons: ["person.fill", "person.fill", "person.fill"],
                circleSize: 36,
                shift: 24
            )
        }
    }
}
