//
//  LivingMandalaAuraView.swift
//  Resonance
//
//  Created by Rhonda Davis on 4/28/26.
//



import SwiftUI
import Combine

//Main View

struct LivingMandalaAuraView: View {
    var totalCycles: Int = 4
    var onComplete: (() -> Void)?

    @State private var phase: BreathPhase = .inhale
    @State private var phaseProgress: Double = 0      // 0...1 within current phase
    @State private var countdown: Int = 4
    @State private var cycleCount: Int = 0
    @State private var isComplete: Bool = false
    @State private var timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    // Shared breathing scale used by petals + center orb
    private var breathScale: CGFloat {
        switch phase {
        case .inhale:
            return 0.88 + 0.24 * CGFloat(phaseProgress) // expand
        case .hold:
            return 1.12 // hold
        case .exhale:
            return 1.12 - 0.24 * CGFloat(phaseProgress) // contract
        }
    }

    var body: some View {
        ZStack {
            if isComplete {
                BreathCompletionCheckIn(
                    onFeelingGrounded: { onComplete?() },
                    onNeedMorePeace: { onComplete?() }
                )
                .transition(.opacity)
            } else {
                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate

                    ZStack {
                        Color(red: 0.05, green: 0.04, blue: 0.14).ignoresSafeArea()

                        AuroraField(t: t)

                        MandalaBloom(t: t, breathScale: breathScale)
                            .frame(width: 360, height: 360)

                        CenterBreathOrb(
                            phase: phase,
                            countdown: countdown,
                            breathScale: breathScale
                        )

                        VStack {
                            Text("Cycle \(cycleCount + 1) of \(totalCycles)")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.6))
                                .padding(.top, 60)
                            Spacer()
                        }
                    }
                }
                .onReceive(timer) { _ in
                    tickBreath()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: isComplete)
    }

    private func tickBreath() {
        guard !isComplete else { return }

        let dt = 1.0 / 60.0
        let duration = phase.duration

        phaseProgress += dt / duration

        let remaining = duration * (1.0 - phaseProgress)
        countdown = max(1, Int(remaining.rounded(.up)))

        if phaseProgress >= 1.0 {
            phaseProgress = 0
            let next = (phase.rawValue + 1) % BreathPhase.allCases.count
            phase = BreathPhase(rawValue: next) ?? .inhale
            countdown = Int(phase.duration)

            if phase == .inhale {
                cycleCount += 1
                if cycleCount >= totalCycles {
                    isComplete = true
                    return
                }
            }
        }
    }
}

//Aurora Background

private struct AuroraField: View {
    let t: TimeInterval

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                auroraBlob(
                    color: Color(red: 0.22, green: 0.65, blue: 0.95),
                    x: w * (0.20 + 0.10 * sin(t * 0.08)),
                    y: h * (0.68 + 0.08 * cos(t * 0.07)),
                    size: max(w, h) * 0.70
                )

                auroraBlob(
                    color: Color(red: 0.75, green: 0.25, blue: 0.90),
                    x: w * (0.80 + 0.10 * cos(t * 0.09)),
                    y: h * (0.30 + 0.07 * sin(t * 0.06)),
                    size: max(w, h) * 0.72
                )

                auroraBlob(
                    color: Color(red: 0.18, green: 0.80, blue: 0.90),
                    x: w * (0.62 + 0.09 * sin(t * 0.07 + 1.4)),
                    y: h * (0.78 + 0.06 * cos(t * 0.08 + 0.9)),
                    size: max(w, h) * 0.68
                )
            }
            .blur(radius: 42)
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func auroraBlob(color: Color, x: CGFloat, y: CGFloat, size: CGFloat) -> some View {
        Circle()
            .fill(color.opacity(0.30))
            .frame(width: size, height: size)
            .position(x: x, y: y)
            .blendMode(.plusLighter)
    }
}

//Mandala Petals

private struct MandalaBloom: View {
    let t: TimeInterval
    let breathScale: CGFloat

    // count, radius, width, height, opacity, spin speed
    private let rings: [(Int, CGFloat, CGFloat, CGFloat, Double, Double)] = [
        (10, 42,  84, 126, 0.36,  0.22),
        (12, 74,  92, 136, 0.32, -0.18),
        (14, 108, 98, 144, 0.28,  0.15),
        (16, 140, 104, 152, 0.24, -0.12)
    ]

    var body: some View {
        ZStack {
            ForEach(0..<rings.count, id: \.self) { r in
                let ring = rings[r]
                let count = ring.0
                let radius = ring.1
                let width = ring.2
                let height = ring.3
                let opacity = ring.4
                let speed = ring.5

                ForEach(0..<count, id: \.self) { i in
                    let theta = Double(i) * 2.0 * .pi / Double(count) + t * speed
                    let x = radius * CGFloat(cos(theta))
                    let y = radius * CGFloat(sin(theta))
                    let angle = Angle.radians(theta + .pi / 2.0) // point outward

                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.42),
                                    Color(red: 0.76, green: 0.68, blue: 0.97).opacity(0.34),
                                    Color(red: 0.28, green: 0.30, blue: 0.66).opacity(0.26)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            Ellipse()
                                .stroke(Color.white.opacity(0.28), lineWidth: 1.4)
                        )
                        .frame(width: width, height: height)
                        .rotationEffect(angle)
                        .position(x: 180 + x, y: 180 + y) // based on 360x360 frame
                        .opacity(opacity)
                }
            }
        }
        .frame(width: 360, height: 360)
        .scaleEffect(breathScale) // <- 4-7-8 breathing drives petals
        .shadow(color: Color(red: 0.35, green: 0.50, blue: 0.95).opacity(0.25), radius: 24)
    }
}

//Center Orb + Countdown

private struct CenterBreathOrb: View {
    let phase: BreathPhase
    let countdown: Int
    let breathScale: CGFloat

    var body: some View {
        let normalized = (breathScale - 0.88) / 0.24 // ~0...1
        let glow = 0.55 + Double(normalized) * 0.35

        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.40 * glow),
                            Color(red: 0.88, green: 0.52, blue: 0.88).opacity(0.26 * glow),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 220, height: 220)
                .blur(radius: 12)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.92),
                            Color(red: 0.80, green: 0.68, blue: 0.98).opacity(0.78),
                            Color(red: 0.44, green: 0.20, blue: 0.62).opacity(0.66)
                        ],
                        center: UnitPoint(x: 0.45, y: 0.42),
                        startRadius: 1,
                        endRadius: 30
                    )
                )
                .frame(width: 70, height: 70)
                .scaleEffect(0.9 + (breathScale - 0.88) * 0.7)

            VStack(spacing: 2) {
                Text(phase.label.uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .tracking(1)

                Text("\(countdown)")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
    }
}



#Preview("Living Mandala 4-7-8") {
    LivingMandalaAuraView()
}
