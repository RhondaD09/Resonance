//
//  AnimatedSpiralBackground.swift
//  Resonance
//
//  Created by Rhonda Davis on 4/10/26.
//

import SwiftUI

struct AnimatedSpiralBackground: View {
    var breathScale: CGFloat = 1.0

    // NewPurple palette
    private static let baseDark   = Color(red: 20/255, green: 8/255, blue: 45/255)
    private static let baseMid    = Color(red: 45/255, green: 20/255, blue: 80/255)
    private static let highlight  = Color(red: 120/255, green: 80/255, blue: 200/255)
    private static let bright     = Color(red: 170/255, green: 140/255, blue: 255/255)

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let cx = size.width / 2
                let cy = size.height / 2
                let maxR = min(size.width, size.height) * 0.48 * breathScale

                // Background fill
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .color(Color(red: 5/255, green: 3/255, blue: 15/255))
                )

                // Ambient nebula glow
                let nebulaR = maxR * 1.3
                let nebulaGrad = Gradient(colors: [
                    Self.baseMid.opacity(0.25),
                    Self.baseDark.opacity(0.10),
                    Color.clear
                ])
                context.fill(
                    Path(ellipseIn: CGRect(x: cx - nebulaR, y: cy - nebulaR,
                                           width: nebulaR * 2, height: nebulaR * 2)),
                    with: .radialGradient(nebulaGrad, center: CGPoint(x: cx, y: cy),
                                          startRadius: 0, endRadius: nebulaR)
                )

                // Concentric vortex rings
                drawVortexRings(context: context, cx: cx, cy: cy, maxR: maxR, time: time)

                // Pulsating center orb
                drawCenterOrb(context: context, cx: cx, cy: cy, time: time)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Vortex Rings

    private func drawVortexRings(context: GraphicsContext, cx: CGFloat, cy: CGFloat, maxR: CGFloat, time: Double) {
        let ringCount = 45
        let rotSpeed = time * 0.15
        let pointsPerRing = 90

        for i in 0..<ringCount {
            let t = Double(i) / Double(ringCount)
            let baseRadius = 18 + t * Double(maxR - 18)

            // Brightness shimmer
            let wave1 = sin(t * .pi * 8.0 - time * 1.2)
            let wave2 = sin(t * .pi * 5.0 + time * 0.8) * 0.5
            let brightness = 0.15 + 0.85 * max(0, (wave1 + wave2) / 1.5)

            let edgeFade = min(t * 4.0, 1.0) * min((1.0 - t) * 3.0, 1.0)
            let alpha = brightness * edgeFade
            let lineWidth: CGFloat = CGFloat(1.5 + brightness * 3.0)

            // Spiral twist: radius varies with angle, offset shifts per ring
            let spiralStrength = 8.0 + t * 12.0
            let spiralPhase = t * .pi * 3.0 + rotSpeed

            var path = Path()
            for p in 0...pointsPerRing {
                let angle = Double(p) / Double(pointsPerRing) * .pi * 2.0
                let spiralWarp = sin(angle * 2.0 + spiralPhase) * spiralStrength
                let wobble = sin(angle * 3.0 + rotSpeed * 1.5 + t * 8.0) * 2.0
                let r = CGFloat(baseRadius + spiralWarp + wobble)

                let px = cx + r * CGFloat(cos(angle))
                let py = cy + r * CGFloat(sin(angle))

                if p == 0 {
                    path.move(to: CGPoint(x: px, y: py))
                } else {
                    path.addLine(to: CGPoint(x: px, y: py))
                }
            }
            path.closeSubpath()

            // Glow pass
            var glowCtx = context
            glowCtx.addFilter(.blur(radius: 6))
            glowCtx.stroke(path, with: .color(Self.highlight.opacity(alpha * 0.3)),
                           style: StrokeStyle(lineWidth: lineWidth + 4, lineCap: .round, lineJoin: .round))

            // Main ring stroke
            context.stroke(path, with: .color(Self.highlight.opacity(alpha * 0.6)),
                           style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))

            // Bright highlight on strongest bands
            if brightness > 0.6 {
                let highlightAlpha = (brightness - 0.6) / 0.4 * edgeFade
                context.stroke(path, with: .color(Self.bright.opacity(highlightAlpha * 0.4)),
                               style: StrokeStyle(lineWidth: max(1, lineWidth - 1), lineCap: .round, lineJoin: .round))
            }
        }
    }

    // MARK: - Center Orb

    private func drawCenterOrb(context: GraphicsContext, cx: CGFloat, cy: CGFloat, time: Double) {
        let pulse = 0.8 + 0.2 * sin(time * 1.2)
        let slowPulse = 0.9 + 0.1 * sin(time * 0.6)

        // Wide soft halo
        let haloR: CGFloat = 60 * CGFloat(slowPulse)
        let haloGrad = Gradient(colors: [
            Self.highlight.opacity(0.25 * pulse),
            Self.baseMid.opacity(0.10 * pulse),
            Color.clear
        ])
        context.fill(
            Path(ellipseIn: CGRect(x: cx - haloR, y: cy - haloR,
                                    width: haloR * 2, height: haloR * 2)),
            with: .radialGradient(haloGrad, center: CGPoint(x: cx, y: cy),
                                  startRadius: 0, endRadius: haloR)
        )

        // Mid glow
        let midR: CGFloat = 30 * CGFloat(pulse)
        let midGrad = Gradient(colors: [
            Self.bright.opacity(0.5 * pulse),
            Self.highlight.opacity(0.2 * pulse),
            Color.clear
        ])
        context.fill(
            Path(ellipseIn: CGRect(x: cx - midR, y: cy - midR,
                                    width: midR * 2, height: midR * 2)),
            with: .radialGradient(midGrad, center: CGPoint(x: cx, y: cy),
                                  startRadius: 0, endRadius: midR)
        )

        // Bright core
        let coreR: CGFloat = 12 * CGFloat(pulse)
        let coreGrad = Gradient(colors: [
            Color.white.opacity(0.7 * pulse),
            Self.bright.opacity(0.4 * pulse),
            Color.clear
        ])
        context.fill(
            Path(ellipseIn: CGRect(x: cx - coreR, y: cy - coreR,
                                    width: coreR * 2, height: coreR * 2)),
            with: .radialGradient(coreGrad, center: CGPoint(x: cx, y: cy),
                                  startRadius: 0, endRadius: coreR)
        )

        // White hot center point
        let dotR: CGFloat = 4 * CGFloat(pulse)
        context.fill(
            Path(ellipseIn: CGRect(x: cx - dotR, y: cy - dotR,
                                    width: dotR * 2, height: dotR * 2)),
            with: .color(Color.white.opacity(0.85 * pulse))
        )
    }
}

#Preview {
    AnimatedSpiralBackground()
}
