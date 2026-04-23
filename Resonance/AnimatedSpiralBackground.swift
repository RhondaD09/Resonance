//
//  AnimatedSpiralBackground.swift
//  Resonance
//
//  Created by Rhonda Davis on 4/10/26.
//

import SwiftUI

struct AnimatedSpiralBackground: View {
    @State private var breathing: Bool = false
    var breathScale: CGFloat = 1.0

    // NewPurple palette — from dark to bright
    private static let purpleDark   = Color(red: 25/255, green: 10/255, blue: 55/255)
    private static let purpleMid    = Color(red: 55/255, green: 25/255, blue: 110/255)
    private static let purpleBright = Color(red: 100/255, green: 60/255, blue: 190/255)
    private static let purpleGlow   = Color(red: 155/255, green: 120/255, blue: 255/255)

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let cx = size.width / 2
                let cy = size.height / 2
                let maxR = max(size.width, size.height) * 0.48 * breathScale

                // Deep space background
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .color(Color(red: 5/255, green: 3/255, blue: 15/255))
                )

                // Distant stars
                drawStars(context: context, size: size, time: time)

                // Soft purple nebula glow behind spiral
                let nebulaR = maxR * 0.9
                let nebulaGrad = Gradient(colors: [
                    Self.purpleMid.opacity(0.18),
                    Self.purpleDark.opacity(0.08),
                    Color.clear
                ])
                context.fill(
                    Path(ellipseIn: CGRect(x: cx - nebulaR, y: cy - nebulaR,
                                           width: nebulaR * 2, height: nebulaR * 2)),
                    with: .radialGradient(nebulaGrad, center: CGPoint(x: cx, y: cy),
                                          startRadius: 0, endRadius: nebulaR)
                )

                // Draw 10 spiral arms — each curves clearly from center to edge
                drawGalaxySpiralArms(context: context, cx: cx, cy: cy, maxR: maxR, time: time)

                // Scattered particles along the arms
                drawSpiralParticles(context: context, cx: cx, cy: cy, maxR: maxR, time: time)

                // Center glow
                drawCenterGlow(context: context, cx: cx, cy: cy, maxR: maxR, time: time)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Galaxy Spiral Arms (10 clean arms, ~2 turns each)

    private func drawGalaxySpiralArms(context: GraphicsContext, cx: CGFloat, cy: CGFloat, maxR: CGFloat, time: Double) {
        let armCount = 10
        let winds = 2.0 // each arm makes 2 full turns — clearly spiral, not rings
        let steps = 300
        let rotOffset = time * 0.05 // slow rotation

        for arm in 0..<armCount {
            let armAngle = Double(arm) * .pi * 2.0 / Double(armCount)

            // Each arm has slightly different brightness
            let armBrightness = 0.5 + 0.5 * sin(Double(arm) * 1.3 + 0.5)

            var path = Path()
            var started = false

            for step in 0...steps {
                let t = Double(step) / Double(steps)
                let angle = t * .pi * 2.0 * winds + armAngle + rotOffset

                // Logarithmic spiral: r grows exponentially for a natural galaxy look
                let logR = (exp(t * 2.5) - 1.0) / (exp(2.5) - 1.0) * Double(maxR)

                let x = Double(cx) + cos(angle) * logR
                let y = Double(cy) + sin(angle) * logR

                if !started {
                    path.move(to: CGPoint(x: x, y: y))
                    started = true
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }

            // Outer glow pass — soft and wide
            var glowCtx = context
            glowCtx.addFilter(.blur(radius: 8))
            glowCtx.stroke(
                path,
                with: .color(Self.purpleBright.opacity(0.2 * armBrightness)),
                style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
            )

            // Main arm stroke — thin and defined
            let lineOpacity = 0.45 * armBrightness
            context.stroke(
                path,
                with: .color(Self.purpleBright.opacity(lineOpacity)),
                style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round)
            )

            // Bright highlight stroke — thinnest, brightest near center
            let highlightGrad = Gradient(colors: [
                Self.purpleGlow.opacity(0.6 * armBrightness),
                Self.purpleGlow.opacity(0.3 * armBrightness),
                Self.purpleBright.opacity(0.1 * armBrightness),
                Color.clear
            ])
            context.stroke(
                path,
                with: .linearGradient(highlightGrad,
                                       startPoint: CGPoint(x: cx, y: cy),
                                       endPoint: CGPoint(x: cx + maxR * 0.7, y: cy)),
                style: StrokeStyle(lineWidth: 0.8, lineCap: .round, lineJoin: .round)
            )
        }
    }

    // MARK: - Stars

    private func drawStars(context: GraphicsContext, size: CGSize, time: Double) {
        let starCount = 100
        for i in 0..<starCount {
            let seed = Double(i)
            let x = CGFloat(frac(sin(seed * 127.1 + 311.7) * 43758.5453)) * size.width
            let y = CGFloat(frac(sin(seed * 269.5 + 183.3) * 43758.5453)) * size.height

            let brightness = frac(sin(seed * 419.2 + 73.1) * 43758.5453)
            let twinkle = 0.3 + 0.7 * (0.5 + 0.5 * sin(time * (0.3 + brightness * 2.0) + seed * 2.1))
            let starSize = CGFloat(0.5 + brightness * 1.5)
            let alpha = twinkle * (0.2 + brightness * 0.5)

            context.fill(
                Path(ellipseIn: CGRect(x: x - starSize / 2, y: y - starSize / 2,
                                       width: starSize, height: starSize)),
                with: .color(Color.white.opacity(alpha))
            )
        }
    }

    // MARK: - Spiral Particles

    private func drawSpiralParticles(context: GraphicsContext, cx: CGFloat, cy: CGFloat, maxR: CGFloat, time: Double) {
        let count = 50
        for i in 0..<count {
            let seed = Double(i)
            let baseFrac = frac(sin(seed * 337.1 + 51.7) * 43758.5453)

            let t = frac(baseFrac + time * 0.02)
            let armIdx = floor(baseFrac * 10)
            let armAngle = armIdx * .pi * 2.0 / 10.0
            let angle = t * .pi * 2.0 * 2.0 + armAngle + time * 0.05
            let logR = (exp(t * 2.5) - 1.0) / (exp(2.5) - 1.0) * Double(maxR)

            let scatter = sin(seed * 193.7 + time * 0.3) * 6.0
            let px = cx + CGFloat(cos(angle) * logR + cos(angle + .pi / 2) * scatter)
            let py = cy + CGFloat(sin(angle) * logR + sin(angle + .pi / 2) * scatter)

            let fade = (1.0 - t) * min(t * 5.0, 1.0)
            let twinkle = 0.5 + 0.5 * sin(time * (1.0 + baseFrac * 2.0) + seed * 3.7)
            let alpha = fade * twinkle * 0.5

            let dotR: CGFloat = CGFloat(1.0 + baseFrac * 2.0)
            let haloR = dotR * 3.0
            let haloGrad = Gradient(colors: [
                Self.purpleGlow.opacity(alpha * 0.4),
                Color.clear
            ])
            context.fill(
                Path(ellipseIn: CGRect(x: px - haloR, y: py - haloR, width: haloR * 2, height: haloR * 2)),
                with: .radialGradient(haloGrad, center: CGPoint(x: px, y: py),
                                      startRadius: 0, endRadius: haloR)
            )
            context.fill(
                Path(ellipseIn: CGRect(x: px - dotR, y: py - dotR, width: dotR * 2, height: dotR * 2)),
                with: .color(Self.purpleGlow.opacity(alpha * 0.7))
            )
        }
    }

    // MARK: - Center Glow

    private func drawCenterGlow(context: GraphicsContext, cx: CGFloat, cy: CGFloat, maxR: CGFloat, time: Double) {
        let pulse = 0.85 + 0.15 * sin(time * 0.8)

        // Soft purple core glow
        let glowR: CGFloat = 30 * CGFloat(pulse)
        let glowGrad = Gradient(colors: [
            Self.purpleGlow.opacity(0.35 * pulse),
            Self.purpleBright.opacity(0.12 * pulse),
            Color.clear
        ])
        context.fill(
            Path(ellipseIn: CGRect(x: cx - glowR, y: cy - glowR,
                                   width: glowR * 2, height: glowR * 2)),
            with: .radialGradient(glowGrad, center: CGPoint(x: cx, y: cy),
                                  startRadius: 0, endRadius: glowR)
        )

        // Bright white center dot
        let coreR: CGFloat = 4
        let whiteGrad = Gradient(colors: [
            Color.white.opacity(0.6 * pulse),
            Self.purpleGlow.opacity(0.25 * pulse),
            Color.clear
        ])
        context.fill(
            Path(ellipseIn: CGRect(x: cx - coreR * 3, y: cy - coreR * 3,
                                   width: coreR * 6, height: coreR * 6)),
            with: .radialGradient(whiteGrad, center: CGPoint(x: cx, y: cy),
                                  startRadius: 0, endRadius: coreR * 3)
        )
    }

    // MARK: - Utility

    private func frac(_ x: Double) -> Double {
        x - floor(x)
    }
}

#Preview {
    AnimatedSpiralBackground()
}
