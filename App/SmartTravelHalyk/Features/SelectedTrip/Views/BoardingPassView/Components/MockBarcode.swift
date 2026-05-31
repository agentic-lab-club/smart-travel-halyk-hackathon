import SwiftUI

struct MockBarcode: View {
    let seed: Int

    var body: some View {
        Canvas { ctx, size in
            var rng = SeededRNG(seed: seed)
            var x: CGFloat = 0
            while x < size.width {
                let w = CGFloat(rng.next(min: 1, max: 5))
                let isBlack = rng.next(min: 0, max: 1) == 0
                let rect = CGRect(x: x, y: 0, width: w, height: size.height)
                ctx.fill(Path(rect), with: .color(isBlack ? .primary : .clear))
                x += w
            }
        }
        .background(Color(.tertiarySystemGroupedBackground))
    }
}
