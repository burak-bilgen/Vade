import SwiftUI

struct LedgerNode: Identifiable, Sendable {
    let id = UUID()
    var position: CGPoint
    var speed: CGPoint
    var opacity: CGFloat
    var size: CGFloat
}

struct LedgerCanvasView: View {
    let nodes: [LedgerNode]
    
    var body: some View {
        TimelineView(.animation(paused: false)) { timeline in
            Canvas { context, size in
                let w = size.width
                let h = size.height
                
                // 1. Draw Subtle Stock-Market Style Background Grid
                let gridSpacingX: CGFloat = 60
                let gridSpacingY: CGFloat = 50
                var gridPath = Path()
                for x in stride(from: CGFloat(0), to: w, by: gridSpacingX) {
                    gridPath.move(to: CGPoint(x: x, y: CGFloat(0)))
                    gridPath.addLine(to: CGPoint(x: x, y: h))
                }
                for y in stride(from: CGFloat(0), to: h, by: gridSpacingY) {
                    gridPath.move(to: CGPoint(x: CGFloat(0), y: y))
                    gridPath.addLine(to: CGPoint(x: w, y: y))
                }
                context.stroke(gridPath, with: .color(ColorTokens.border.opacity(0.22)), lineWidth: 0.5)
                
                // 2. Draw Smooth Financial Index Chart Waves (Dual Waves)
                let time = timeline.date.timeIntervalSinceReferenceDate
                
                // Wave 1: Teal Chart Wave
                var path1 = Path()
                path1.move(to: CGPoint(x: CGFloat(-10), y: h * CGFloat(0.75)))
                for x in stride(from: CGFloat(0), to: w + CGFloat(10), by: CGFloat(8)) {
                    let relativeX = Double(x / w)
                    let arg1 = relativeX * .pi * 2.2 + time * 0.2
                    let arg2 = relativeX * .pi * 4.0 - time * 0.1
                    let wave = CGFloat(sin(arg1)) * h * CGFloat(0.04)
                    let microWave = CGFloat(cos(arg2)) * h * CGFloat(0.01)
                    let upwardTrend = -CGFloat(relativeX) * h * CGFloat(0.12)
                    let y = h * CGFloat(0.68) + wave + microWave + upwardTrend
                    path1.addLine(to: CGPoint(x: x, y: y))
                }
                context.stroke(path1, with: .color(ColorTokens.chartTeal.opacity(0.45)), lineWidth: 3.5)
                context.stroke(path1, with: .color(Color.white.opacity(0.85)), lineWidth: 0.8)
                
                // Wave 2: Purple Dotted Chart Wave
                var path2 = Path()
                path2.move(to: CGPoint(x: CGFloat(-10), y: h * CGFloat(0.8)))
                for x in stride(from: CGFloat(0), to: w + CGFloat(10), by: CGFloat(8)) {
                    let relativeX = Double(x / w)
                    let arg3 = relativeX * .pi * 1.5 + time * 0.15
                    let wave = CGFloat(cos(arg3)) * h * CGFloat(0.03)
                    let upwardTrend = -CGFloat(relativeX) * h * CGFloat(0.15)
                    let y = h * CGFloat(0.62) + wave + upwardTrend
                    path2.addLine(to: CGPoint(x: x, y: y))
                }
                context.stroke(
                    path2,
                    with: .color(ColorTokens.chartPurple.opacity(0.35)),
                    style: StrokeStyle(lineWidth: 2.0, dash: [CGFloat(4), CGFloat(8)])
                )
                
                // 3. Draw Connection Lines between Nearby Nodes (Transaction network)
                let nodeCount = nodes.count
                for i in 0..<nodeCount {
                    let p1 = nodes[i].position
                    for j in (i + 1)..<nodeCount {
                        let p2 = nodes[j].position
                        let dx = p1.x - p2.x
                        let dy = p1.y - p2.y
                        let distance = sqrt(dx*dx + dy*dy)
                        
                        // If nodes are close, draw a thin connecting line
                        if distance < CGFloat(110) {
                            let lineOpacity = (1.0 - Double(distance / CGFloat(110))) * 0.18
                            context.stroke(
                                Path { p in
                                    p.move(to: p1)
                                    p.addLine(to: p2)
                                },
                                with: .color(ColorTokens.accent.opacity(lineOpacity)),
                                lineWidth: 0.75
                            )
                        }
                    }
                }
                
                // 4. Draw Glowing Network Nodes
                for node in nodes {
                    let rect = CGRect(
                        x: node.position.x - node.size / 2.0,
                        y: node.position.y - node.size / 2.0,
                        width: node.size,
                        height: node.size
                    )
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(ColorTokens.accent.opacity(Double(node.opacity)))
                    )
                    
                    // Add outer glow ring
                    let glowRect = rect.insetBy(dx: -node.size * 0.6, dy: -node.size * 0.6)
                    context.stroke(
                        Path(ellipseIn: glowRect),
                        with: .color(ColorTokens.accent.opacity(Double(node.opacity * 0.35))),
                        lineWidth: 0.5
                    )
                }
            }
        }
    }
}

@MainActor
public struct FinanceBackgroundAnimation: View {
    @State private var nodes: [LedgerNode] = []
    
    public init() {}
    
    public var body: some View {
        LedgerCanvasView(nodes: nodes)
            .background(
                LinearGradient(
                    colors: [ColorTokens.background, ColorTokens.surface],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .onAppear {
                generateInitialNodes()
            }
            .task { @MainActor in
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 16_000_000) // ~60fps
                    updateNodes()
                }
            }
    }
    
    private func generateInitialNodes() {
        var newNodes: [LedgerNode] = []
        let size = UIScreen.main.bounds.size
        for _ in 0..<22 {
            newNodes.append(createRandomNode(in: size, initialPos: true))
        }
        nodes = newNodes
    }
    
    private func createRandomNode(in size: CGSize, initialPos: Bool = false) -> LedgerNode {
        let x = CGFloat.random(in: 0...size.width)
        let y = initialPos ? CGFloat.random(in: 0...size.height) : size.height + 10
        
        return LedgerNode(
            position: CGPoint(x: x, y: y),
            speed: CGPoint(
                x: CGFloat.random(in: -0.3 ... 0.3),
                y: CGFloat.random(in: -0.8 ... -0.3)
            ),
            opacity: CGFloat.random(in: 0.2 ... 0.65),
            size: CGFloat.random(in: 3 ... 6)
        )
    }
    
    private func updateNodes() {
        let size = UIScreen.main.bounds.size
        var updated = nodes
        for i in 0..<updated.count {
            updated[i].position.y += updated[i].speed.y
            updated[i].position.x += updated[i].speed.x
            
            // Re-generate if out of screen bounds
            if updated[i].position.y < CGFloat(-15) || updated[i].position.x < CGFloat(-15) || updated[i].position.x > size.width + CGFloat(15) {
                updated[i] = createRandomNode(in: size, initialPos: false)
            }
        }
        self.nodes = updated
    }
}
