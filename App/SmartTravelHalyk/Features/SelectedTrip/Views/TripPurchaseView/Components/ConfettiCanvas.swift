import SwiftUI

struct ConfettiParticle {
    var x: CGFloat
    var y: CGFloat
    var color: Color
    var size: CGFloat
    var angle: Double
    var speed: CGFloat
    var spin: Double
    var shape: Int
}

struct ConfettiCanvas: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var tick: Int = 0
    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    private let colors: [Color] = [
        .green, .yellow, .orange, .pink, .blue, .purple, .teal, .mint
    ]

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                for p in particles {
                    let rect = CGRect(x: p.x - p.size / 2, y: p.y - p.size / 2, width: p.size, height: p.size * 0.55)
                    ctx.opacity = max(0, 1.0 - (p.y / (size.height * 1.1)))
                    ctx.transform = .identity
                        .translatedBy(x: p.x, y: p.y)
                        .rotated(by: p.spin)
                        .translatedBy(x: -p.x, y: -p.y)
                    var path: Path
                    if p.shape == 0 {
                        path = Path(ellipseIn: rect)
                    } else if p.shape == 1 {
                        path = Path(rect)
                    } else {
                        path = Path(roundedRect: rect, cornerRadius: 2)
                    }
                    ctx.fill(path, with: .color(p.color))
                }
            }
            .onAppear {
                particles = (0..<80).map { _ in
                    ConfettiParticle(
                        x: CGFloat.random(in: 0...geo.size.width),
                        y: CGFloat.random(in: -200 ... -10),
                        color: colors.randomElement()!,
                        size: CGFloat.random(in: 6...14),
                        angle: Double.random(in: 0...360),
                        speed: CGFloat.random(in: 2.5...6),
                        spin: Double.random(in: -0.08...0.08),
                        shape: Int.random(in: 0...2)
                    )
                }
            }
            .onReceive(timer) { _ in
                for i in particles.indices {
                    particles[i].y += particles[i].speed
                    particles[i].x += sin(particles[i].angle) * 0.8
                    particles[i].spin += Double.random(in: -0.02...0.02)
                    particles[i].angle += 0.04
                    if particles[i].y > geo.size.height + 20 {
                        particles[i].y = CGFloat.random(in: -80 ... -10)
                        particles[i].x = CGFloat.random(in: 0...geo.size.width)
                        particles[i].speed = CGFloat.random(in: 2.5...6)
                    }
                }
            }
        }
    }
}
