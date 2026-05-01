//
//  MandalaView.swift
//  Resonance
//
//  Created by Rhonda Davis on 4/27/26.
//



import SwiftUI
import Combine

//Models

private struct Ring {
    let count: Int        // number of circles in this ring
    let radius: CGFloat   // radius of each circle
    let offset: CGFloat   // distance of each circle's center from origin
    let color: Color
    let alpha: Double
    let speed: Double     // rotation speed (signed: + clockwise, − counter)
    let phase: Double     // starting angular offset
}

private struct Node {
    let baseAngle: Double
    let distance: CGFloat
    let size: CGFloat
    let speed: Double
}

private struct Particle {
    var ringDistance: CGFloat
    var angle: Double
    var speed: Double
    var size: CGFloat
    var twinkle: Double
}

//View

struct MandalaView: View {

    // Rings of overlapping circles, arranged like the original mandala.
    private let rings: [Ring] = [
        Ring(count: 4, radius: 170, offset: 110, color: Color(red: 0.31, green: 0.64, blue: 0.97), alpha: 0.85, speed:  0.04, phase: .pi / 2),
        Ring(count: 4, radius: 120, offset: 113, color: Color(red: 0.44, green: 0.73, blue: 1.00), alpha: 0.70, speed: -0.06, phase: .pi / 4),
        Ring(count: 4, radius:  90, offset:  60, color: Color(red: 0.49, green: 0.76, blue: 1.00), alpha: 0.78, speed:  0.10, phase: .pi / 2),
        Ring(count: 4, radius:  60, offset:  50, color: Color(red: 0.62, green: 0.82, blue: 1.00), alpha: 0.85, speed: -0.14, phase: .pi / 4),
    ]

    // Glowing nodes that orbit the center.
    private let nodes: [Node] = {
        var result: [Node] = []
        // Outer cardinal tips
        for i in 0..<4 {
            result.append(Node(baseAngle: Double(i) * .pi / 2, distance: 260, size: 11, speed:  0.08))
        }
        // Mid cardinal
        for i in 0..<4 {
            result.append(Node(baseAngle: Double(i) * .pi / 2, distance: 140, size: 9, speed: -0.12))
        }
        // Diagonal mid
        for i in 0..<4 {
            result.append(Node(baseAngle: Double(i) * .pi / 2 + .pi / 4, distance: 142, size: 8, speed: 0.16))
        }
        // Inner small
        for i in 0..<6 {
            result.append(Node(baseAngle: Double(i) * .pi / 3, distance: 60, size: 6, speed: -0.22))
        }
        // Tiny accents
        for i in 0..<8 {
            result.append(Node(baseAngle: Double(i) * .pi / 4, distance: 40, size: 5, speed: 0.30))
        }
        return result
    }()

    // ── Change this to set how many 4-7-8 cycles to run ──
    private let totalCycles = 4

    @State private var particles: [Particle] = {
        let distances: [CGFloat] = [60, 110, 140, 180]
        return (0..<28).map { i in
            Particle(
                ringDistance: distances[i % 4],
                angle: Double.random(in: 0..<(2 * .pi)),
                speed: Double.random(in: 0.2...0.6) * (Bool.random() ? 1 : -1),
                size: CGFloat.random(in: 1...3),
                twinkle: Double.random(in: 0..<(2 * .pi))
            )
        }
    }()

    @State private var phase: BreathPhase = .inhale
    @State private var progress: Double = 0
    @State private var countdown: Int = 4
    @State private var breathScale: CGFloat = 0.65
    @State private var cycleCount: Int = 0
    @State private var isRunning: Bool = true
    @State private var phaseTrigger: Int = 0
    @State private var tickTrigger: Int = 0
    @State private var cycleTrigger: Int = 0
    @State private var timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                Color.black.ignoresSafeArea()

                StarsBackground(breathScale: breathScale)
                    .ignoresSafeArea()

                Canvas { context, size in
                    draw(context: context, size: size, t: t)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .sensoryFeedback(.impact(weight: .medium), trigger: phaseTrigger)
        .sensoryFeedback(.impact(weight: .light), trigger: tickTrigger)
        .sensoryFeedback(.impact(weight: .heavy), trigger: cycleTrigger)
        .onReceive(timer) { _ in tick() }
    }

    private func tick() {
        guard isRunning else { return }

        let dt = 1.0 / 60.0
        progress += dt / phase.duration

        let remaining = phase.duration * (1.0 - progress)
        let newCountdown = max(1, Int(remaining.rounded(.up)))
        if newCountdown != countdown {
            countdown = newCountdown
            tickTrigger += 1
        }

        if progress >= 1.0 {
            progress = 0
            let next = (phase.rawValue + 1) % BreathPhase.allCases.count
            if let newPhase = BreathPhase(rawValue: next) {
                phase = newPhase
                countdown = Int(phase.duration)
                phaseTrigger += 1
            }

            if phase == .inhale {
                cycleCount += 1
                cycleTrigger += 1
                if cycleCount >= totalCycles {
                    isRunning = false
                    return
                }
            }
        }

        let eased = (1.0 - cos(CGFloat(progress) * .pi)) / 2.0
        switch phase {
        case .inhale:
            breathScale = 0.65 + 0.65 * eased
        case .hold:
            breathScale = 1.30
        case .exhale:
            breathScale = 1.30 - 0.65 * eased
        }
    }

    //Drawing

    private func draw(context ctx: GraphicsContext, size: CGSize, t: TimeInterval) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let bs = breathScale

        let designSize: CGFloat = 680
        let scale = min(size.width, size.height) / designSize

        // 1) Background vignette
        let bgRect = CGRect(origin: .zero, size: size)
        ctx.fill(
            Path(bgRect),
            with: .radialGradient(
                Gradient(colors: [
                    Color(red: 0.04, green: 0.14, blue: 0.27).opacity(0.82),
                    Color.black.opacity(0.35)
                ]),
                center: center,
                startRadius: 0,
                endRadius: designSize * 0.55 * scale
            )
        )

        var c = ctx
        c.translateBy(x: center.x, y: center.y)
        c.scaleBy(x: scale, y: scale)

        let globalRot = sin(t * 0.15) * 0.05
        c.rotate(by: .radians(globalRot))

        // 2) Draw each ring — breathScale drives the expansion
        for ring in rings {
            drawRing(ring, in: c, t: t, breathScale: bs)
        }

        // 3) Center circles follow the breath
        var center1 = c
        let cb = bs
        center1.scaleBy(x: cb, y: cb)
        center1.stroke(
            Path(ellipseIn: CGRect(x: -38, y: -38, width: 76, height: 76)),
            with: .color(Color(red: 0.71, green: 0.86, blue: 1.0).opacity(0.9)),
            lineWidth: 1.3
        )
        center1.stroke(
            Path(ellipseIn: CGRect(x: -20, y: -20, width: 40, height: 40)),
            with: .color(Color(red: 0.84, green: 0.92, blue: 1.0).opacity(0.95)),
            lineWidth: 1.1
        )

        // 4) Countdown text
        let phaseText = Text(phase.label)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundColor(.white.opacity(0.9))
        let countText = Text("\(countdown)")
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .foregroundColor(.white)
        c.draw(phaseText, at: CGPoint(x: 0, y: -18))
        c.draw(countText, at: CGPoint(x: 0, y: 14))

        // 5) Drifting particles — distances breathe with the mandala
        for i in particles.indices {
            particles[i].angle += particles[i].speed * 0.01
            particles[i].twinkle += 0.05
            let dist = particles[i].ringDistance * bs
            let x = cos(particles[i].angle) * dist
            let y = sin(particles[i].angle) * dist
            let intensity = 0.4 + sin(particles[i].twinkle) * 0.3
            drawGlowDot(at: CGPoint(x: x, y: y), size: particles[i].size, intensity: intensity, in: c)
        }

        // 6) Orbiting nodes — distances breathe with the mandala
        for (i, n) in nodes.enumerated() {
            let angle = n.baseAngle + sin(t * n.speed + Double(i)) * 0.08
            let dist = (n.distance + CGFloat(sin(t * 0.8 + Double(i)) * 4)) * bs
            let x = cos(angle) * dist
            let y = sin(angle) * dist
            let intensity = 0.7 + sin(t * 1.5 + Double(i) * 0.7) * 0.3
            drawGlowDot(at: CGPoint(x: x, y: y), size: n.size, intensity: intensity, in: c)
        }

        // 7) Core glow
        drawGlowDot(at: .zero, size: 14, intensity: 0.95, in: c)
    }

    private func drawRing(_ ring: Ring, in ctx: GraphicsContext, t: TimeInterval, breathScale bs: CGFloat) {
        let rotation = t * ring.speed

        var c = ctx
        c.rotate(by: .radians(rotation))
        c.scaleBy(x: bs, y: bs)
        c.opacity = ring.alpha

        for i in 0..<ring.count {
            let a = Double(i) / Double(ring.count) * 2 * .pi + ring.phase
            let ox = cos(a) * Double(ring.offset)
            let oy = sin(a) * Double(ring.offset)
            let rect = CGRect(
                x: ox - Double(ring.radius),
                y: oy - Double(ring.radius),
                width: Double(ring.radius) * 2,
                height: Double(ring.radius) * 2
            )
            c.stroke(
                Path(ellipseIn: rect),
                with: .color(ring.color),
                lineWidth: 1.4
            )
        }
    }

    private func drawGlowDot(at point: CGPoint, size: CGFloat, intensity: Double, in ctx: GraphicsContext) {
        let glowRadius = size * 3
        let glowRect = CGRect(
            x: point.x - glowRadius,
            y: point.y - glowRadius,
            width: glowRadius * 2,
            height: glowRadius * 2
        )
        ctx.fill(
            Path(ellipseIn: glowRect),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: Color(red: 0.86, green: 0.94, blue: 1.0).opacity(intensity),         location: 0.0),
                    .init(color: Color(red: 0.43, green: 0.71, blue: 1.0).opacity(intensity * 0.7),  location: 0.4),
                    .init(color: Color(red: 0.16, green: 0.39, blue: 0.78).opacity(0),                location: 1.0),
                ]),
                center: point,
                startRadius: 0,
                endRadius: glowRadius
            )
        )

        let coreRadius = size * 0.55
        ctx.fill(
            Path(ellipseIn: CGRect(
                x: point.x - coreRadius,
                y: point.y - coreRadius,
                width: coreRadius * 2,
                height: coreRadius * 2
            )),
            with: .color(Color(red: 0.90, green: 0.96, blue: 1.0).opacity(intensity))
        )
    }
}



#Preview {
    MandalaView()
        .ignoresSafeArea()
}
