//
//  BreathingParticlesView.swift
//  Resonance
//
//  Created by Alexus WIlliams on 5/1/26.
//

import SwiftUI

struct BreathParticle: Identifiable {
    let id = UUID()
    let xPosition: CGFloat
    let size: CGFloat
    let glowIntensity: Double
    let horizontalDrift: CGFloat
    let opacity: Double
    let phase: Double
    let phaseStart: CGFloat
    let phaseSpan: CGFloat
}

struct BreathParticleView: View {

    let particle: BreathParticle
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    let phaseProgress: CGFloat
    let isInhaling: Bool

    let goldColor = Color(red: 1.0, green: 0.65, blue: 0.0)

    private var localProgress: CGFloat {
        let span = max(particle.phaseSpan, 0.15)
        let raw = (phaseProgress - particle.phaseStart) / span
        return max(0, min(raw, 1))
    }

    private var isActiveInPhase: Bool {
        let span = max(particle.phaseSpan, 0.15)
        return phaseProgress >= particle.phaseStart && phaseProgress <= (particle.phaseStart + span)
    }

    private var yPosition: CGFloat {
        let p = localProgress
        let spread = screenHeight * 0.34
        let laneOffset = (CGFloat(particle.phase) - 0.5) * spread
        let exitMargin = (spread * 0.6) + particle.size

        if isInhaling {
            let startY = -exitMargin + laneOffset
            let endY = screenHeight + exitMargin + laneOffset
            return startY + (p * (endY - startY))
        } else {
            let startY = screenHeight + exitMargin + laneOffset
            let endY = -exitMargin + laneOffset
            return startY + (p * (endY - startY))
        }
    }

    private var xOffset: CGFloat {
        let p = localProgress
        let directionalDrift = ((p * 2.0) - 1.0) * particle.horizontalDrift * 1.35
        let wave = sin((Double(p) * Double.pi * 3.2) + (particle.phase * Double.pi * 2.0))
        return directionalDrift + (CGFloat(wave) * particle.horizontalDrift * 0.65)
    }

    private var xPosition: CGFloat {
        let margin = particle.size
        let minX = margin
        let maxX = max(screenWidth - margin, minX + 1)
        return min(max(particle.xPosition + xOffset, minX), maxX)
    }

    private var particleScale: CGFloat {
        let p = localProgress
        return isInhaling ? (0.90 + (0.18 * p)) : (1.08 - (0.18 * p))
    }

    var body: some View {

        ZStack {
            // outer glow
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            goldColor.opacity(0.3 * particle.glowIntensity),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: particle.size * 1.5
                    )
                )
                .frame(width: particle.size * 3, height: particle.size * 3)

            // mid glow
            Circle()
                .fill(goldColor.opacity(0.5 * particle.glowIntensity))
                .frame(width: particle.size * 1.6, height: particle.size * 1.6)

            // solid dot
            Circle()
                .fill(goldColor)
                .frame(width: particle.size, height: particle.size)
                .overlay(
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(
                            width: particle.size * 0.38,
                            height: particle.size * 0.38
                        )
                        .offset(
                            x: -particle.size * 0.14,
                            y: -particle.size * 0.14
                        )
                )
        }
        .scaleEffect(particleScale)
        .opacity(isActiveInPhase ? particle.opacity : 0.0)
        .position(
            x: xPosition,
            y: yPosition
        )
    }
}

struct BreathingParticlesView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var isInhaling: Bool = true
    @State private var breathText: String = "Breathe In"
    @State private var textOpacity: Double = 0.0
    @State private var backgroundGlow: Double = 0.0
    @State private var glowScale: CGFloat = 0.5
    @State private var cycleCount: Int = 0
    @State private var navigateToCompletion: Bool = false
    @State private var particles: [BreathParticle] = []
    @State private var phaseProgress: CGFloat = 0.0
    let totalCycles = 4

    let goldColor = Color(red: 1.0, green: 0.65, blue: 0.0)

    // Breath timing
    let inhaleDuration: Double = 8.0
    let exhaleDuration: Double = 8.0

    func makeParticles(in size: CGSize) -> [BreathParticle] {
        let width = max(size.width, 60)
        var list: [BreathParticle] = []
        let count = 60
        let usableWidth = max(width - 40, 1)
        let spacing = usableWidth / CGFloat(count)

        for index in 0..<count {
            let baseX = 20 + (CGFloat(index) + 0.5) * spacing
            let jitter = CGFloat.random(in: -(spacing * 0.18)...(spacing * 0.18))
            let x = min(max(baseX + jitter, 20), width - 20)
            // Allow some particles to already be in-flight at phase start.
            let start = CGFloat.random(in: -0.22...0.58)
            let maxSpan = max(0.20, 0.98 - start)
            let span = CGFloat.random(in: 0.20...maxSpan)
            list.append(
                BreathParticle(
                    xPosition: x,
                    size: CGFloat.random(in: 5...34),
                    glowIntensity: Double.random(in: 0.5...1.0),
                    horizontalDrift: CGFloat.random(in: 6...20),
                    opacity: Double.random(in: 0.55...0.95),
                    phase: Double.random(in: 0...1),
                    phaseStart: start,
                    phaseSpan: span
                )
            )
        }
        return list
    }

    var body: some View {
        ZStack {
            if navigateToCompletion {
                BreathCompletionCheckIn(
                    onFeelingGrounded: {},
                    onNeedMorePeace: {},
                    onReturnHome: { dismiss() }
                )
                .transition(.opacity)
            } else {
                GeometryReader { geometry in

                    let screenSize = geometry.size

                    ZStack {

                        //background
                        Color.black.ignoresSafeArea()
                        StarsBackground()
                            .ignoresSafeArea()

                        //warm glow
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color(red: 1.0, green: 0.55, blue: 0.0).opacity(0.22),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 380
                        )
                        .ignoresSafeArea()
                        .opacity(backgroundGlow)
                        .scaleEffect(glowScale)
                        ForEach(particles) { particle in
                            BreathParticleView(
                                particle: particle,
                                screenWidth: screenSize.width,
                                screenHeight: screenSize.height,
                                phaseProgress: phaseProgress,
                                isInhaling: isInhaling
                            )
                        }
                        VStack {
                            Spacer()
                            Text(breathText)
                                .font(.system(size: 20, weight: .ultraLight, design: .rounded))
                                .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.2))
                                .tracking(6)
                                .opacity(textOpacity)
                                .padding(.bottom, 70)
                        }
                    }
                    .onAppear {
                        if particles.isEmpty {
                            particles = makeParticles(in: screenSize)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            startBreathingCycle(in: screenSize)
                        }
                    }
                }
                .transition(.opacity)
            }
        }
        .ignoresSafeArea()
        .toolbar(.hidden, for: .navigationBar)
    }

    func startBreathingCycle(in screenSize: CGSize) {

        isInhaling = true
        phaseProgress = 0.0
        // New spawn map at phase start so each pass enters from different places.
        particles = makeParticles(in: screenSize)
        breathText = "Breathe In"
        withAnimation(.easeInOut(duration: 1.0)) {
            textOpacity = 0.9
        }

        withAnimation(.linear(duration: inhaleDuration)) {
            phaseProgress = 1.0
        }

        withAnimation(.easeInOut(duration: inhaleDuration)) {
            backgroundGlow = 1.0
            glowScale      = 1.3
        }

        // Switch directions immediately after inhale (no hold/pause).
        let exhaleStart = inhaleDuration

        DispatchQueue.main.asyncAfter(deadline: .now() + exhaleStart) {

            isInhaling = false
            phaseProgress = 0.0
            // Refresh particle positions while offscreen between phases.
            particles = makeParticles(in: screenSize)
            withAnimation(.easeInOut(duration: 0.6)) { textOpacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                breathText = "Breathe Out"
                withAnimation(.easeInOut(duration: 0.6)) { textOpacity = 0.9 }
            }

            withAnimation(.linear(duration: exhaleDuration)) {
                phaseProgress = 1.0
            }

            withAnimation(.easeInOut(duration: exhaleDuration)) {
                backgroundGlow = 0.0
                glowScale      = 0.5
            }
        }

        let cycleLength = inhaleDuration + exhaleDuration
        DispatchQueue.main.asyncAfter(deadline: .now() + cycleLength - 0.8) {
            withAnimation(.easeInOut(duration: 0.8)) { textOpacity = 0 }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + cycleLength) {
            cycleCount += 1
            if cycleCount < totalCycles {
                startBreathingCycle(in: screenSize)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        navigateToCompletion = true
                    }
                }
            }
        }
    }
}

#Preview {
    BreathingParticlesView()
}
