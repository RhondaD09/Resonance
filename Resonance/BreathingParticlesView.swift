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
    let travelDuration: Double
    let glowIntensity: Double
    let horizontalDrift: CGFloat
    let opacity: Double
    let phase: Double
    let flowsUp: Bool
}

struct BreathParticleView: View {

    let particle: BreathParticle
    let screenHeight: CGFloat
    let currentTime: TimeInterval

    let goldColor = Color(red: 1.0, green: 0.65, blue: 0.0)

    private var cycleProgress: Double {
        let raw = (currentTime / particle.travelDuration) + particle.phase
        let wrapped = raw.truncatingRemainder(dividingBy: 1.0)
        return wrapped >= 0 ? wrapped : wrapped + 1.0
    }

    private var yPosition: CGFloat {
        let travelDistance = screenHeight + (particle.size * 2.0)
        let p = CGFloat(cycleProgress)
        if particle.flowsUp {
            return screenHeight + particle.size - (p * travelDistance)
        } else {
            return -particle.size + (p * travelDistance)
        }
    }

    private var xOffset: CGFloat {
        let phaseOffset = particle.phase * (Double.pi * 2.0)
        return CGFloat(sin((currentTime * 0.8) + phaseOffset)) * particle.horizontalDrift
    }

    private var particleScale: CGFloat {
        let p = CGFloat(cycleProgress)
        return particle.flowsUp
            ? (0.92 + (0.16 * (1.0 - p)))
            : (0.92 + (0.16 * p))
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
        .opacity(particle.opacity)
        .position(
            x: particle.xPosition + xOffset,
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
    let totalCycles = 4

    let goldColor = Color(red: 1.0, green: 0.65, blue: 0.0)

    // Breath timing
    let inhaleDuration: Double = 4.0
    let exhaleDuration: Double = 4.0
    
// particle scatter on screen
    func makeParticles(in size: CGSize) -> [BreathParticle] {
        let width = max(size.width, 60)
        var list: [BreathParticle] = []
        let count = 40

        for index in 0..<count {
            
            let x = CGFloat.random(in: 20...(width - 20))
            list.append(
                BreathParticle(
                    xPosition: x,
                    size: CGFloat.random(in: 5...48),
                    travelDuration: Double.random(in: 6.8...9.2),
                    glowIntensity: Double.random(in: 0.5...1.0),
                    horizontalDrift: index.isMultiple(of: 2)
                        ? CGFloat.random(in: 6...20)
                        : CGFloat.random(in: -20...(-6)),
                    opacity: Double.random(in: 0.55...0.95),
                    phase: Double.random(in: 0...1),
                    flowsUp: index.isMultiple(of: 2)
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
                        TimelineView(.animation) { timeline in
                            ForEach(particles) { particle in
                                BreathParticleView(
                                    particle: particle,
                                    screenHeight: screenSize.height,
                                    currentTime: timeline.date.timeIntervalSinceReferenceDate
                                )
                            }
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
                            startBreathingCycle()
                        }
                    }
                }
                .transition(.opacity)
            }
        }
        .ignoresSafeArea()
        .toolbar(.hidden, for: .navigationBar)
    }

    func startBreathingCycle() {

        isInhaling = true

        breathText = "Breathe In"
        withAnimation(.easeInOut(duration: 1.0)) {
            textOpacity = 0.9
        }

        withAnimation(.easeInOut(duration: inhaleDuration)) {
            backgroundGlow = 1.0
            glowScale      = 1.3
        }

        // Switch directions immediately after inhale (no hold/pause).
        let exhaleStart = inhaleDuration

        DispatchQueue.main.asyncAfter(deadline: .now() + exhaleStart) {

            isInhaling = false
            withAnimation(.easeInOut(duration: 0.6)) { textOpacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                breathText = "Breathe Out"
                withAnimation(.easeInOut(duration: 0.6)) { textOpacity = 0.9 }
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
                startBreathingCycle()
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
