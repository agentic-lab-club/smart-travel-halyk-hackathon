import SwiftUI

struct MockQRCode: View {
    let seed: Int
    private let grid = 15

    var body: some View {
        Canvas { ctx, size in
            var rng = SeededRNG(seed: seed)
            let cellW = size.width / CGFloat(grid)
            let cellH = size.height / CGFloat(grid)
            for row in 0..<grid {
                for col in 0..<grid {
                    let isCorner = isFinderCell(row: row, col: col)
                    let filled = isCorner || rng.next(min: 0, max: 2) == 0
                    if filled {
                        let rect = CGRect(x: CGFloat(col) * cellW, y: CGFloat(row) * cellH, width: cellW - 0.5, height: cellH - 0.5)
                        ctx.fill(Path(rect), with: .color(.primary))
                    }
                }
            }
        }
        .background(Color(.tertiarySystemGroupedBackground))
    }

    private func isFinderCell(row: Int, col: Int) -> Bool {
        let size = grid
        func inFinder(_ r: Int, _ c: Int, _ or: Int, _ oc: Int) -> Bool {
            r >= or && r < or + 7 && c >= oc && c < oc + 7
        }
        return inFinder(row, col, 0, 0) ||
            inFinder(row, col, 0, size - 7) ||
            inFinder(row, col, size - 7, 0)
    }
}
