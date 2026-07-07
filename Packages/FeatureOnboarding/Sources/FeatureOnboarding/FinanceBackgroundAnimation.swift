import SwiftUI
import DesignSystem

struct CurrencyParticle: Identifiable {
    let id = UUID()
    var symbol: String
    var position: CGPoint
    var scale: CGFloat
    var rotation: Double
    var opacity: Double
    var speedY: CGFloat
    var speedX: CGFloat
}

public struct FinanceBackgroundAnimation: View {
    @State private var particles: [CurrencyParticle] = []
    
    private let symbols = ["$", "€", "₺", "¥", "£", "%"]
    
    public init() {}
    
    public var body: some View {
        TimelineView(.animation(paused: false)) { timeline in
            Canvas { context, size in
                let w = size.width
                let h = size.height
                
                // Draw a sleek finance grid
                let gridSpacing: CGFloat = 40
                var gridPath = Path()
                
                // Vertical grid lines
                for x in stride(from: 0, to: w, by: gridSpacing) {
                    gridPath.move(to: CGPoint(x: x, y: 0))
                    gridPath.addLine(to: CGPoint(x: x, y: h))
                }
                // Horizontal grid lines
                for y in stride(from: 0, to: h, by: gridSpacing) {
                    gridPath.move(to: CGPoint(x: 0, y: y))
                    gridPath.addLine(to: CGPoint(x: w, y: y))
                }
                context.stroke(gridPath, with: .color(ColorTokens.border.opacity(0.15)), lineWidth: 0.5)
                
                // Draw a rising, glowing financial chart line
                let time = timeline.date.timeIntervalSinceReferenceDate
                var chartPath = Path()
                chartPath.move(to: CGPoint(x: 0, y: h * 0.7))
                
                for x in stride(from: 0, to: w + 5, by: 5) {
                    let relativeX = x / w
                    let wave1 = sin(relativeX * .pi * 2 + CGFloat(time * 0.4)) * h * 0.05
                    let wave2 = cos(relativeX * .pi * 4 - CGFloat(time * 0.2)) * h * 0.02
                    let upwardTrend = -relativeX * h * 0.15 // Generates a rising trend
                    let y = h * 0.65 + wave1 + wave2 + upwardTrend
                    chartPath.addLine(to: CGPoint(x: x, y: y))
                }
                
                // Glow effect for the chart line
                context.stroke(chartPath, with: .color(ColorTokens.accent.opacity(0.3)), lineWidth: 4)
                context.stroke(chartPath, with: .color(ColorTokens.chartTeal.opacity(0.6)), lineWidth: 1.5)
                
                // Draw floating particles
                for particle in particles {
                    context.draw(
                        Text(particle.symbol)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(ColorTokens.accent.opacity(particle.opacity)),
                        at: particle.position
                    )
                }
            }
        }
        .background(
            LinearGradient(
                colors: [ColorTokens.background, ColorTokens.surface],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onAppear {
            generateInitialParticles()
        }
        .task {
            // Animate particles using an ongoing loop
            while true {
                try? await Task.sleep(nanoseconds: 16_000_000) // ~60fps
                updateParticles()
            }
        }
    }
    
    private func generateInitialParticles() {
        var newParticles: [CurrencyParticle] = []
        for _ in 0..<15 {
            newParticles.append(createRandomParticle(in: UIScreen.main.bounds.size, initialY: true))
        }
        particles = newParticles
    }
    
    private func createRandomParticle(in size: CGSize, initialY: Bool = false) -> CurrencyParticle {
        let x = CGFloat.random(in: 0...size.width)
        let y = initialY ? CGFloat.random(in: 0...size.height) : size.height + 20
        return CurrencyParticle(
            symbol: symbols.randomElement() ?? "$",
            position: CGPoint(x: x, y: y),
            scale: CGFloat.random(in: 0.6...1.2),
            rotation: Double.random(in: 0...360),
            opacity: Double.random(in: 0.05...0.25),
            speedY: CGFloat.random(in: -1.2...-0.4),
            speedX: CGFloat.random(in: -0.3...0.3)
        )
    }
    
    private func updateParticles() {
        let size = UIScreen.main.bounds.size
        for i in 0..<particles.count {
            particles[i].position.y += particles[i].speedY
            particles[i].position.x += particles[i].speedX
            particles[i].rotation += 0.5
            
            // Re-spawn if particle moves off screen
            if particles[i].position.y < -20 || particles[i].position.x < -20 || particles[i].position.x > size.width + 20 {
                particles[i] = createRandomParticle(in: size, initialY: false)
            }
        }
    }
}
