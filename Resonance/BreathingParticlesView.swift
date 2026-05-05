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

    let speed: Double

    let delay: Double

    let glowIntensity: Double

    let horizontalDrift: CGFloat

    let opacity: Double
}

struct BreathParticleView: View {

    let particle: BreathParticle
    let isInhaling: Bool

    let screenHeight: CGFloat
    let screenWidth: CGFloat
    @State private var yPosition: CGFloat = 0
    @State private var currentOpacity: Double = 0
    @State private var currentScale: CGFloat = 0.3

    let goldColor = Color(red: 1.0, green: 0.65, blue: 0.0)

    var body: some View {

        ZStack {
            // uter glow
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
        .scaleEffect(currentScale)

        .opacity(currentOpacity * particle.opacity)

        .position(
            x: particle.xPosition + (isInhaling ? particle.horizontalDrift : -particle.horizontalDrift),
            y: yPosition
        )
        .onChange(of: isInhaling) { _, inhaling in
            animateParticle(inhaling: inhaling)
        }

        .onAppear {
            yPosition = isInhaling
                ? -particle.size           // start above screen
                : screenHeight + particle.size  // start below screen
            animateParticle(inhaling: isInhaling)
        }
    }

    func animateParticle(inhaling: Bool) {

        if inhaling {
            yPosition      = -particle.size - CGFloat.random(in: 0...screenHeight * 0.4)
            currentOpacity = 0
            currentScale   = 0.4
            DispatchQueue.main.asyncAfter(deadline: .now() + particle.delay) {
                withAnimation(
                    .easeIn(duration: particle.speed * 0.25)
                ) {
                    currentOpacity = 1.0
                }

                withAnimation(
                    .easeInOut(duration: particle.speed)
                ) {
                    yPosition    = screenHeight + particle.size
                    currentScale = 1.2
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + particle.speed * 0.7) {
                    withAnimation(.easeOut(duration: particle.speed * 0.35)) {
                        currentOpacity = 0
                    }
                }
            }

        } else {
            //FLOATING UP
            
            yPosition      = screenHeight + particle.size + CGFloat.random(in: 0...screenHeight * 0.4)
            currentOpacity = 0
            currentScale   = 1.1

            DispatchQueue.main.asyncAfter(deadline: .now() + particle.delay) {
                withAnimation(
                    .easeIn(duration: particle.speed * 0.25)
                ) {
                    currentOpacity = 1.0
                    // Fade in bottom
                }

                withAnimation(
                    .easeInOut(duration: particle.speed)
                ) {
                    yPosition    = -particle.size
                    currentScale = 0.3
                }

                // Fade out top
                DispatchQueue.main.asyncAfter(deadline: .now() + particle.speed * 0.7) {
                    withAnimation(.easeOut(duration: particle.speed * 0.35)) {
                        currentOpacity = 0
                    }
                }
            }
        }
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
    let totalCycles = 4

    let goldColor = Color(red: 1.0, green: 0.65, blue: 0.0)

    // Breath timing
    let inhaleDuration: Double = 4.0
    let exhaleDuration: Double = 4.0
    let holdDuration:   Double = 0.8

    func makeParticles(in size: CGSize) -> [BreathParticle] {
        let width = max(size.width, 60)
        var list: [BreathParticle] = []

        for _ in 0..<40 {
            list.append(
                BreathParticle(
                    xPosition: CGFloat.random(in: 20...(width - 20)),

                    size: CGFloat.random(in: 5...48),

                    speed: Double.random(in: 3.0...5.5),

                    delay: Double.random(in: 0...3.5),

                    glowIntensity: Double.random(in: 0.5...1.0),
                    horizontalDrift: CGFloat.random(in: -18...18),
                    opacity: Double.random(in: 0.6...1.0)
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
                    let particles  = makeParticles(in: screenSize)

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
                                particle:     particle,
                                isInhaling:   isInhaling,
                                screenHeight: screenSize.height,
                                screenWidth:  screenSize.width
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

        let exhaleStart = inhaleDuration + holdDuration

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

        let cycleLength = inhaleDuration + holdDuration + exhaleDuration + holdDuration
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
