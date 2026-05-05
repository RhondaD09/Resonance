//
//  CircleMandalaView.swift
//  Resonance
//
//  Created by Rhonda Davis on 5/4/26.
//

import SwiftUI
import Combine
import UIKit

struct CircleMandalaView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var rotateOuter = false
    @State private var rotateMiddle = false
    @State private var rotateInner = false

    @State private var phase: BreathPhase = .inhale
    @State private var phaseProgress: Double = 0
    @State private var cycleCount: Int = 0
    @State private var isRunning = true
    @State private var timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
    @State private var previousPhase: BreathPhase = .inhale
    @State private var navigateToCompletion = false


    
//Cycle ... Inhale and exhale
    private let totalCycles = 4
    private let restingScale: CGFloat = 0.75
    private let inhaledScale: CGFloat = 1.08

    private let orbBlue = Color(red: 0.37, green: 0.66, blue: 1.0)
    private let lightBlue = Color(red: 0.68, green: 0.83, blue: 1.0)
    private let strokeBlue = Color(red: 0.37, green: 0.66, blue: 1.0)

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
            if navigateToCompletion {
                BreathCompletionCheckIn(
                    onFeelingGrounded: {},
                    onNeedMorePeace: {},
                    onReturnHome: { dismiss() }
                )
                .transition(.opacity)
            } else {
                breathingContent
                    .transition(.opacity)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var breathingContent: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let scale = side / 420

            ZStack {
                Color.black.ignoresSafeArea()

                StarsBackground(breathScale: breathScale)
                    .ignoresSafeArea()

                ZStack {
                    // Soft center glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [orbBlue.opacity(0.35), .black.opacity(0)],
                                center: .center,
                                startRadius: 10,
                                endRadius: 320
                            )
                        )
                        .frame(width: 50, height: 50)

// Change the size ...Outer ring of 8 overlapping circles
                    ringOfCircles(count: 8, radius: 95, offset: 95, lineWidth: 1.2, opacity: 0.85)
                        .rotationEffect(.degrees(rotateOuter ? 360 : 0))

                    // Middle ring of 8 overlapping circles
//                    ringOfCircles(count: 8, radius: 95, offset: 150, lineWidth: 1.0, opacity: 0.7)
//                        .rotationEffect(.degrees(rotateMiddle ? -360 : 0))

                    // Inner ring of 8 overlapping circles
                    ringOfCircles(count: 8, radius: 60, offset: 60, lineWidth: 0.9, opacity: 0.55)
                        .rotationEffect(.degrees(rotateInner ? 360 : 0))

                    // Concentric guide circles
                    Circle()
                        .stroke(strokeBlue.opacity(0.4), lineWidth: 0.8)
                        .frame(width: 300, height: 300)

                    Circle()
                        .stroke(strokeBlue.opacity(0.3), lineWidth: 0.7)
                        .frame(width: 300, height: 300)

                    // Orbs on outer ring
                    ringOfOrbs(count: 8, offset: 90, sizes: [16, 12], colors: [lightBlue, orbBlue])
                        .rotationEffect(.degrees(rotateOuter ? 360 : 0))

                    // Orbs on far edge
//                    ringOfOrbs(count: 8, offset: 180, sizes: [8, 6], colors: [lightBlue, orbBlue])
//                        .rotationEffect(.degrees(rotateMiddle ? -360 : 0))

                    // Orbs near center
                    ringOfOrbs(count: 8, offset: 45, sizes: [6, 5], colors: [lightBlue, orbBlue])
                        .rotationEffect(.degrees(rotateInner ? 720 : 0))

                    // Center orb with enhanced glow
                    ZStack {
                        // Wide bloom — faint light that spreads far
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        orbBlue.opacity(0.25),
                                        orbBlue.opacity(0.08),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 200)

                        // Outermost soft glow halo
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        orbBlue.opacity(0.45),
                                        orbBlue.opacity(0.15),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 120, height: 120)

                        // Mid glow ring
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        lightBlue.opacity(0.7),
                                        orbBlue.opacity(0.3),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 35
                                )
                            )
                            .frame(width: 70, height: 70)

                        // Bright core
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.white, .white.opacity(0.9), lightBlue, orbBlue],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 18
                                )
                            )
                            .frame(width: 45, height: 45)
                            .shadow(color: .white.opacity(0.6), radius: 8)
                            .shadow(color: lightBlue, radius: 22)
                            .shadow(color: lightBlue.opacity(0.8), radius: 35)
                            .shadow(color: orbBlue.opacity(0.7), radius: 50)
                            .shadow(color: orbBlue.opacity(0.4), radius: 70)
                    }
                }
                .scaleEffect(breathScale * scale)

                // Guided breathing text
                if isRunning {
                    Text(phase.label)
                        .font(.title2)
                        .fontWeight(.light)
                        .tracking(4)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [lightBlue, orbBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: orbBlue.opacity(0.6), radius: 10)
                        .offset(y: geo.size.height * 0.38)
                        .animation(.easeInOut(duration: 0.6), value: phase)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        .onAppear { startRotations() }
        .onReceive(timer) { _ in tickBreath() }
    }

    // Ring builders

    private func ringOfCircles(count: Int, radius: CGFloat, offset: CGFloat,
                               lineWidth: CGFloat, opacity: Double) -> some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                let angle = Angle.degrees(Double(i) * 360.0 / Double(count))
                Circle()
                    .stroke(strokeBlue.opacity(opacity), lineWidth: lineWidth)
                    .frame(width: radius * 2, height: radius * 2)
                    .offset(
                        x: cos(angle.radians - .pi / 2) * offset,
                        y: sin(angle.radians - .pi / 2) * offset
                    )
            }
        }
    }

    private func ringOfOrbs(count: Int, offset: CGFloat,
                            sizes: [CGFloat], colors: [Color]) -> some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                let angle = Angle.degrees(Double(i) * 360.0 / Double(count))
                let size = sizes[i % sizes.count]
                Circle()
                    .fill(
                        RadialGradient(
                            colors: colors,
                            center: .center,
                            startRadius: 0,
                            endRadius: size
                        )
                    )
                    .frame(width: size, height: size)
                    .shadow(color: lightBlue.opacity(0.6), radius: 6)
                    .offset(
                        x: cos(angle.radians - .pi / 2) * offset,
                        y: sin(angle.radians - .pi / 2) * offset
                    )
            }
        }
    }

    // Animations

    private func startRotations() {
        withAnimation(.linear(duration: 40).repeatForever(autoreverses: false)) { rotateOuter = true }
        withAnimation(.linear(duration: 55).repeatForever(autoreverses: false)) { rotateMiddle = true }
        withAnimation(.linear(duration: 70).repeatForever(autoreverses: false)) { rotateInner = true }
    }

    private func tickBreath() {
        guard isRunning else { return }

        let dt = 1.0 / 60.0
        phaseProgress += dt / phase.duration

        if phaseProgress >= 1.0 {
            phaseProgress = 0
            let nextPhase = (phase.rawValue + 1) % BreathPhase.allCases.count
            phase = BreathPhase(rawValue: nextPhase) ?? .inhale
            triggerHaptic(for: phase)

            if phase == .inhale {
                cycleCount += 1
                if cycleCount >= totalCycles {
                    isRunning = false
                    phase = .exhale
                    phaseProgress = 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            navigateToCompletion = true
                        }
                    }
                }
            }
        }
    }

    private func triggerHaptic(for phase: BreathPhase) {
        switch phase {
        case .inhale:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        case .hold:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        case .exhale:
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred()
        }
    }

    private func smoothstep(_ x: Double) -> CGFloat {
        let t = max(0, min(1, x))
        return CGFloat(t * t * (3 - 2 * t))
    }
}

#Preview {
    CircleMandalaView()
}
