//
//  FlowerMandalaView.swift
//  Resonance
//
//  Created by Rhonda Davis on 4/27/26.
//


//  Use:
//      FlowerMandalaView()
//          .frame(width: 360, height: 360)
//

import SwiftUI
import Combine

//Models

private struct Sparkle {
    let position: CGPoint   // position relative to center
    let baseRadius: CGFloat
    let period: Double      // twinkle period (seconds)
    let phase: Double       // animation offset (seconds)
}

//Petal shape (vesica piscis / lens)

/// A pointed almond / lens petal that points along the +x axis from the origin.
/// Width 180, half-height 50 in design units (matches the SVG `<path id="petal">`).
private struct FlowerMandala: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: .zero)
        p.addQuadCurve(to: CGPoint(x: 180, y: 0), control: CGPoint(x: 90, y: -50))
        p.addQuadCurve(to: .zero, control: CGPoint(x: 90, y: 50))
        p.closeSubpath()
        return p
    }
}

// View
//Cycles
struct FlowerMandalaView: View {
    private let totalCycles = 4
    private let restingScale: CGFloat = 0.80
    private let inhaledScale: CGFloat = 1.12

    // Core color palette — pink ramp.
    private let petalOuter   = Color(red: 0.91, green: 0.61, blue: 0.77) // #E89BC4
    private let petalInner   = Color(red: 0.84, green: 0.45, blue: 0.65) // #D673A7
    private let bgInner      = Color(red: 0.10, green: 0.04, blue: 0.09) // #1a0a18

    // Inner sparkles — orbit the core, spin one way.
    private let innerSparkles: [Sparkle] = [
        Sparkle(position: CGPoint(x:  40, y: -15), baseRadius: 3.0,  period: 1.8, phase: 0.0),
        Sparkle(position: CGPoint(x: -30, y:  35), baseRadius: 4.0,  period: 2.2, phase: 0.3),
        Sparkle(position: CGPoint(x:  50, y:  40), baseRadius: 2.5,  period: 1.5, phase: 0.6),
        Sparkle(position: CGPoint(x: -50, y: -25), baseRadius: 3.0,  period: 2.4, phase: 0.9),
        Sparkle(position: CGPoint(x:  20, y:  55), baseRadius: 2.0,  period: 1.7, phase: 1.2),
        Sparkle(position: CGPoint(x: -15, y: -50), baseRadius: 3.5,  period: 2.0, phase: 1.5),
        Sparkle(position: CGPoint(x:  65, y:  10), baseRadius: 2.0,  period: 1.9, phase: 0.4),
        Sparkle(position: CGPoint(x: -65, y:   5), baseRadius: 3.0,  period: 2.3, phase: 0.7),
        Sparkle(position: CGPoint(x:  10, y: -65), baseRadius: 2.5,  period: 1.6, phase: 1.0),
        Sparkle(position: CGPoint(x:  -5, y:  70), baseRadius: 3.0,  period: 2.1, phase: 1.3),
        Sparkle(position: CGPoint(x:  35, y: -45), baseRadius: 2.0,  period: 1.4, phase: 0.2),
        Sparkle(position: CGPoint(x: -40, y: -45), baseRadius: 2.5,  period: 1.8, phase: 0.8),
        Sparkle(position: CGPoint(x: -55, y:  50), baseRadius: 2.0,  period: 2.2, phase: 1.4),
        Sparkle(position: CGPoint(x:  55, y: -30), baseRadius: 3.0,  period: 1.7, phase: 1.1),
    ]

    // Outer drifting sparkles — wider orbit, opposite spin.
    private let outerSparkles: [Sparkle] = [
        Sparkle(position: CGPoint(x:  100, y:  -20), baseRadius: 2.0,  period: 2.5, phase: 0.0),
        Sparkle(position: CGPoint(x:  -90, y:   60), baseRadius: 2.5,  period: 2.0, phase: 0.5),
        Sparkle(position: CGPoint(x:   80, y:   80), baseRadius: 2.0,  period: 1.8, phase: 1.0),
        Sparkle(position: CGPoint(x: -100, y:  -30), baseRadius: 2.0,  period: 2.3, phase: 1.5),
        Sparkle(position: CGPoint(x:   30, y: -100), baseRadius: 2.5,  period: 1.6, phase: 0.7),
        Sparkle(position: CGPoint(x:  -30, y:  100), baseRadius: 2.0,  period: 2.1, phase: 1.2),
        Sparkle(position: CGPoint(x:  105, y:   35), baseRadius: 1.8,  period: 1.9, phase: 0.9),
        Sparkle(position: CGPoint(x: -110, y:   10), baseRadius: 2.0,  period: 2.4, phase: 0.3),
    ]

    @Environment(\.dismiss) private var dismiss

    @State private var phase: BreathPhase = .inhale
    @State private var phaseProgress: Double = 0
    @State private var cycleCount: Int = 0
    @State private var isRunning = true
    @State private var showCheckIn = false
    @State private var timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    private var breathScale: CGFloat {
        guard isRunning else { return restingScale }
        
        let easedProgress = smoothstep(phaseProgress)
        switch phase {
        case .inhale:
            return restingScale + (inhaledScale - restingScale) * easedProgress
        case .hold:
            return inhaledScale
        case .exhale:
            return inhaledScale - (inhaledScale - restingScale) * easedProgress
        }
    }
      
        var body: some View {
        ZStack {
            if showCheckIn {
                BreathCompletionCheckIn(
                    onFeelingGrounded: {},
                    onNeedMorePeace: {},
                    onReturnHome: { dismiss() }
                )
                .transition(.opacity)
            } else {
                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate

                    ZStack {
                        Color.black.ignoresSafeArea()

                        StarsBackground(breathScale: breathScale)
                            .ignoresSafeArea()

                        Canvas { context, size in
                            draw(context: context, size: size, t: t, breathScale: breathScale)
                        }

                        VStack {
                            Spacer()
                            Text(phase.label)
                                .font(.title.weight(.semibold))
                                .foregroundStyle(petalOuter)
                                .shadow(color: petalOuter.opacity(0.6), radius: 8)
                                .contentTransition(.numericText())
                                .animation(.easeInOut(duration: 0.4), value: phase)
                                .padding(.bottom, 80)
                        }
                    }
                }
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .onReceive(timer) { _ in
            tickBreath()
        }
        .sensoryFeedback(.increase, trigger: phase == .inhale && isRunning)
        .sensoryFeedback(.impact(weight: .light, intensity: 0.4), trigger: phase == .hold && isRunning)
        .sensoryFeedback(.decrease, trigger: phase == .exhale && isRunning)
    }

    //Drawing

    private func draw(context ctx: GraphicsContext, size: CGSize, t: TimeInterval, breathScale: CGFloat) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)

        // Authored at 680x680 — scale uniformly to fit.
        let designSize: CGFloat = 450
        let scale = min(size.width, size.height) / designSize

        // Centered, scaled coordinate space
        var c = ctx
        c.translateBy(x: center.x, y: center.y)
        c.scaleBy(x: scale, y: scale)

        // 2) Outer ring of 8 petals — slow rotation + breathing
        drawPetalRing(
            in: c, t: t,
            count: 8,
            angleOffset: 0,
            scale: 1.0,
            color: petalOuter,
            lineWidth: 2.4,
            opacity: 1.0,
            spinSpeed: (2 * .pi) / 50,
            breathScale: breathScale
        )

        // 3) Inner ring of 8 smaller petals — opposite rotation, offset 22.5°
        drawPetalRing(
            in: c, t: t,
            count: 8,
            angleOffset: 22.5,
            scale: 0.7,
            color: petalInner,
            lineWidth: 1.8,
            opacity: 0.75,
            spinSpeed: -(2 * .pi) / 70,
            breathScale: breathScale * 0.98
        )

        // 4) Glowing core — three layered radial gradients pulsing
        drawCore(in: c, t: t, breathScale: breathScale)

        // 5) Inner sparkles — orbit clockwise
        let innerSpin = t * (2 * .pi) / 25
        drawSparkles(innerSparkles, in: c, t: t, spin: innerSpin)

        // 6) Outer sparkles — orbit counter-clockwise
        let outerSpin = -t * (2 * .pi) / 40
        drawSparkles(outerSparkles, in: c, t: t, spin: outerSpin)
    }

    private func drawPetalRing(
        in ctx: GraphicsContext,
        t: TimeInterval,
        count: Int,
        angleOffset: Double,         // degrees
        scale s: CGFloat,
        color: Color,
        lineWidth: CGFloat,
        opacity: Double,
        spinSpeed: Double,           // radians per second
        breathScale: CGFloat
    ) {
        var c = ctx
        c.rotate(by: .radians(t * spinSpeed))
        c.scaleBy(x: breathScale * s, y: breathScale * s)
        c.opacity = opacity

        let petal = FlowerMandala().path(in: .zero)


        for i in 0..<count {
            var pc = c
            let degrees = Double(i) * (360.0 / Double(count)) + angleOffset
            pc.rotate(by: .degrees(degrees))
            pc.stroke(petal, with: .color(color), lineWidth: lineWidth)
        }
    }

    private func drawCore(in ctx: GraphicsContext, t: TimeInterval, breathScale: CGFloat) {
        let pulses: [(radius: CGFloat, period: Double, baseOpacity: Double)] = [
            (95, 4.0, 0.7),
            (55, 3.0, 0.8),
            (22, 2.4, 0.9),
        ]

        for (i, p) in pulses.enumerated() {
            let pulse = 1 + sin(t * (2 * .pi) / p.period) * 0.15
            let intensity = p.baseOpacity + sin(t * (2 * .pi) / p.period) * 0.15
            let r = p.radius * CGFloat(pulse) * breathScale
            let rect = CGRect(x: -r, y: -r, width: r * 2, height: r * 2)

            if i < 2 {
                // Soft glowing rings via radial gradient
                ctx.fill(
                    Path(ellipseIn: rect),
                    with: .radialGradient(
                        Gradient(stops: [
                            .init(color: Color.white.opacity(intensity),                                       location: 0.00),
                            .init(color: Color(red: 1.0, green: 0.88, blue: 0.94).opacity(intensity * 0.95),   location: 0.25),
                            .init(color: Color(red: 0.91, green: 0.61, blue: 0.77).opacity(intensity * 0.55),  location: 0.60),
                            .init(color: Color(red: 0.56, green: 0.19, blue: 0.40).opacity(0),                 location: 1.00),
                        ]),
                        center: .zero,
                        startRadius: 0,
                        endRadius: r
                    )
                )
            } else {
                // Tightest hot-white center
                ctx.fill(
                    Path(ellipseIn: rect),
                    with: .color(Color.white.opacity(intensity))
                )
            }
        }
    }

    private func drawSparkles(_ sparkles: [Sparkle], in ctx: GraphicsContext, t: TimeInterval, spin: Double) {
        var c = ctx
        c.rotate(by: .radians(spin))

        for s in sparkles {
            let phaseT = t + s.phase
            let twinkle = sin(phaseT * (2 * .pi) / s.period)         // -1...1
            let scale = 0.7 + (twinkle + 1) / 2 * 0.6                // 0.7...1.3
            let intensity = 0.3 + (twinkle + 1) / 2 * 0.7            // 0.3...1.0

            let r = s.baseRadius * CGFloat(scale)
            let glowR = r * 3
            let glowRect = CGRect(
                x: s.position.x - glowR,
                y: s.position.y - glowR,
                width: glowR * 2,
                height: glowR * 2
            )

            c.fill(
                Path(ellipseIn: glowRect),
                with: .radialGradient(
                    Gradient(stops: [
                        .init(color: Color.white.opacity(intensity),                                       location: 0.0),
                        .init(color: Color(red: 0.96, green: 0.75, blue: 0.86).opacity(intensity * 0.7),   location: 0.6),
                        .init(color: Color(red: 0.78, green: 0.31, blue: 0.55).opacity(0),                 location: 1.0),
                    ]),
                    center: s.position,
                    startRadius: 0,
                    endRadius: glowR
                )
            )

            let coreR = r * 0.55
            c.fill(
                Path(ellipseIn: CGRect(
                    x: s.position.x - coreR,
                    y: s.position.y - coreR,
                    width: coreR * 2,
                    height: coreR * 2
                )),
                with: .color(Color.white.opacity(intensity))
            )
        }
    }

    private func tickBreath() {
        guard isRunning else { return }

        let dt = 1.0 / 60.0
        phaseProgress += dt / phase.duration

        if phaseProgress >= 1.0 {
            phaseProgress = 0
            let nextPhase = (phase.rawValue + 1) % BreathPhase.allCases.count
            phase = BreathPhase(rawValue: nextPhase) ?? .inhale

            if phase == .inhale {
                cycleCount += 1
                if cycleCount >= totalCycles {
                    isRunning = false
                    phase = .exhale
                    phaseProgress = 1
                    withAnimation(.easeInOut(duration: 0.6)) {
                        showCheckIn = true
                    }
                }
            }
        }
    }

    private func smoothstep(_ x: Double) -> CGFloat {
        let t = max(0, min(1, x))
        return CGFloat(t * t * (3 - 2 * t))
    }
}




#Preview {
    FlowerMandalaView()
        .ignoresSafeArea()
}
