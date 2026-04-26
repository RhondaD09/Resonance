//
//  MeditationView.swift
//  A calming meditation visual: layered lotus with a glowing, breathing orb,
//  slow rotation, shimmering petals, and a flowing aurora background.


import SwiftUI
import Combine

// Root View

struct MeditationView: View {
    @State private var phase: BreathPhase = .inhale
    @State private var progress: Double = 0
    @State private var countdown: Int = 4
    @State private var breathScale: CGFloat = 0.85
    @State private var phaseTrigger: Int = 0
    @State private var tickTrigger: Int = 0
    @State private var timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate

            GeometryReader { geo in
                let s = min(geo.size.width, geo.size.height)

                ZStack {
                    AnimatedMeshGradient()
                        .ignoresSafeArea()

                    LotusFlower(t: t, breathScale: breathScale)
                        .frame(width: s * 0.85, height: s * 0.85)

                    GlowingOrb(t: t, breathScale: breathScale, phase: phase, countdown: countdown)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .ignoresSafeArea()
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: phaseTrigger)
        .sensoryFeedback(.impact(weight: .light), trigger: tickTrigger)
        .onReceive(timer) { _ in tick() }
    }

    private func tick() {
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
        }

        switch phase {
        case .inhale:
            breathScale = 0.85 + 0.30 * CGFloat(progress)
        case .hold:
            breathScale = 1.15
        case .exhale:
            breathScale = 1.15 - 0.30 * CGFloat(progress)
        }
    }
}

//Aurora Background

struct AuroraBackground: View {
    let t: TimeInterval
    let size: CGSize

    var body: some View {
        ZStack {
            // Deep night base gradient
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.04, blue: 0.14),
                    Color(red: 0.08, green: 0.03, blue: 0.20),
                    Color(red: 0.02, green: 0.06, blue: 0.16)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Soft drifting aurora blobs blended additively
            ForEach(0..<5, id: \.self) { i in
                auroraBlob(index: i)
            }
        }
    }

    @ViewBuilder
    private func auroraBlob(index: Int) -> some View {
        let phase = Double(index) * 1.3
        let speed = 0.045 + Double(index) * 0.012
        let x = 0.5 + 0.42 * sin(t * speed + phase)
        let y = 0.5 + 0.35 * cos(t * speed * 0.8 + phase * 1.3)
        let blobSize = max(size.width, size.height) * 0.95

        Circle()
            .fill(auroraColor(index))
            .frame(width: blobSize, height: blobSize)
            .position(x: size.width * x, y: size.height * y)
            .blur(radius: 90)
            .blendMode(.plusLighter)
            .opacity(0.55)
    }

    private func auroraColor(_ i: Int) -> Color {
        let palette: [Color] = [
            Color(red: 0.25, green: 0.55, blue: 0.95),
            Color(red: 0.55, green: 0.30, blue: 0.95),
            Color(red: 0.25, green: 0.80, blue: 0.75),
            Color(red: 0.85, green: 0.40, blue: 0.70),
            Color(red: 0.40, green: 0.50, blue: 1.00)
        ]
        return palette[i % palette.count]
    }
}

// Lotus Flower

struct LotusFlower: View {
    let t: TimeInterval
    var breathScale: CGFloat = 1.0

    private let petalTop    = Color.white
    private let petalMid    = Color(white: 0.75)
    private let petalBase   = Color(white: 0.45)
    private let petalShadow = Color(white: 0.20)

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            // Slow rotation: 60 seconds per revolution
            let rotation = t * 6.0

            ZStack {
                // Layer 1 — outermost ring (largest, most petals)
                petalRing(count: 16, length: s * 0.48, width: s * 0.16,
                          rotation: rotation, angleOffset: 0,
                          shimmerSpeed: 0.9, shimmerPhase: 0.0,
                          tipBrightness: 1.00)

                // Layer 2 — staggered between outer petals
                petalRing(count: 16, length: s * 0.42, width: s * 0.15,
                          rotation: rotation, angleOffset: 11.25,
                          shimmerSpeed: 1.1, shimmerPhase: 0.4,
                          tipBrightness: 1.00)

                // Layer 3
                petalRing(count: 14, length: s * 0.34, width: s * 0.14,
                          rotation: rotation, angleOffset: 6,
                          shimmerSpeed: 1.25, shimmerPhase: 0.9,
                          tipBrightness: 0.98)

                // Layer 4
                petalRing(count: 12, length: s * 0.27, width: s * 0.13,
                          rotation: -rotation * 0.4, angleOffset: 0,
                          shimmerSpeed: 1.4, shimmerPhase: 1.3,
                          tipBrightness: 0.96)

                // Layer 5 — innermost ring of small petals around the orb
                petalRing(count: 10, length: s * 0.20, width: s * 0.11,
                          rotation: -rotation * 0.4, angleOffset: 18,
                          shimmerSpeed: 1.6, shimmerPhase: 1.8,
                          tipBrightness: 0.94)
            }
            .scaleEffect(breathScale)
            .frame(width: s, height: s)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }

    @ViewBuilder
    private func petalRing(
        count: Int,
        length: CGFloat,
        width: CGFloat,
        rotation: Double,
        angleOffset: Double,
        shimmerSpeed: Double,
        shimmerPhase: Double,
        tipBrightness: Double
    ) -> some View {
        ForEach(0..<count, id: \.self) { i in
            let angle = Double(i) * 360.0 / Double(count) + rotation + angleOffset
            let shimmer = 0.78 + 0.22 * (0.5 + 0.5 * sin(t * shimmerSpeed + Double(i) * 0.7 + shimmerPhase))

            PetalShape()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: petalTop.opacity(0.45 * tipBrightness), location: 0.00),
                            .init(color: petalTop.opacity(0.38),                 location: 0.25),
                            .init(color: petalMid.opacity(0.30),                 location: 0.55),
                            .init(color: petalBase.opacity(0.22),                location: 0.85),
                            .init(color: petalShadow.opacity(0.15),              location: 1.00)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    PetalShape()
                        .stroke(Color.white.opacity(0.20), lineWidth: 0.5)
                )
                .frame(width: width, height: length)
                .offset(y: -length / 2)          // base sits at center
                .rotationEffect(.degrees(angle)) // pivots around (0,0)
                .opacity(shimmer)
                .shadow(color: petalShadow.opacity(0.15), radius: 3, x: 0, y: 1)
        }
    }
}

// Petal Shape

struct PetalShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Rounded tip: start slightly below the top with a soft arc
        path.move(to: CGPoint(x: w * 0.42, y: h * 0.03))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.58, y: h * 0.03),
            control: CGPoint(x: w * 0.50, y: -h * 0.04)
        )

        // Right side: rounded tip → wide middle → base
        path.addCurve(
            to: CGPoint(x: w * 0.56, y: h),
            control1: CGPoint(x: w * 0.95, y: h * 0.30),
            control2: CGPoint(x: w * 0.88, y: h * 0.88)
        )
        // Base curve
        path.addQuadCurve(
            to: CGPoint(x: w * 0.44, y: h),
            control: CGPoint(x: w * 0.50, y: h * 1.04)
        )
        // Left side: base → wide middle → rounded tip
        path.addCurve(
            to: CGPoint(x: w * 0.42, y: h * 0.03),
            control1: CGPoint(x: w * 0.12, y: h * 0.88),
            control2: CGPoint(x: w * 0.05, y: h * 0.30)
        )

        path.closeSubpath()
        return path
    }
}

// Glowing Orb

struct GlowingOrb: View {
    let t: TimeInterval
    var breathScale: CGFloat = 1.0
    var phase: BreathPhase = .inhale
    var countdown: Int = 4

    var body: some View {
        let intensity = CGFloat((breathScale - 0.85) / 0.30).clamped(to: 0...1)
        let orbIntensity = 0.70 + 0.30 * intensity
        let orbScale = 0.82 + 0.32 * intensity

        let newPurple = Color("NewPurple")

        ZStack {
            // Visual orb layers
            ZStack {
                // Wide soft halo
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                newPurple.opacity(0.55 * orbIntensity),
                                newPurple.opacity(0.00)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .blur(radius: 35)

                // Mid glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                newPurple.opacity(0.85 * orbIntensity),
                                newPurple.opacity(0.00)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 90
                        )
                    )
                    .frame(width: 180, height: 180)
                    .blur(radius: 12)

                // Core orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.9),
                                newPurple.opacity(0.85),
                                newPurple.opacity(0.95)
                            ],
                            center: UnitPoint(x: 0.4, y: 0.4),
                            startRadius: 2,
                            endRadius: 50
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: newPurple.opacity(0.85 * orbIntensity), radius: 30)
            }
            .scaleEffect(orbScale)

            // Countdown display (not scaled with the orb)
            VStack(spacing: 2) {
                Text(phase.label)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .tracking(1.2)
                Text("\(countdown)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
        }
    }
}



#Preview {
    MeditationView()
}
