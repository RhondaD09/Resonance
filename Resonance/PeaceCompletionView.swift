//
//  PeaceCompletionView.swift
//  Resonance
//
//  Created by Rhonda Davis on 4/28/26.
//

import SwiftUI

struct PeaceCompletionView: View {
    var onReturnHome: () -> Void

    @State private var appeared = false
    @State private var sunPulse = false
    @State private var ripplePhase: CGFloat = 0

    private let skyTop = Color(red: 0.95, green: 0.55, blue: 0.25)
    private let skyMid = Color(red: 0.85, green: 0.35, blue: 0.45)
    private let skyBottom = Color(red: 0.35, green: 0.18, blue: 0.55)
    private let waterTop = Color(red: 0.18, green: 0.12, blue: 0.38)
    private let waterBottom = Color(red: 0.06, green: 0.04, blue: 0.14)

    var body: some View {
        ZStack {
            // Sky gradient
            LinearGradient(
                colors: [skyTop, skyMid, skyBottom],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            // Water gradient (bottom half)
            GeometryReader { geo in
                VStack(spacing: 0) {
                    Spacer()
                    LinearGradient(
                        colors: [waterTop, waterBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: geo.size.height * 0.45)
                }
            }
            .ignoresSafeArea()

            // Sun
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate

                GeometryReader { geo in
                    let sunY = geo.size.height * 0.42
                    let centerX = geo.size.width * 0.5

                    ZStack {
                        // Sun outer glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        skyTop.opacity(0.4),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 30,
                                    endRadius: 160
                                )
                            )
                            .frame(width: 320, height: 320)
                            .scaleEffect(sunPulse ? 1.08 : 0.94)
                            .position(x: centerX, y: sunY)

                        // Sun core
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white.opacity(0.95),
                                        Color(red: 1.0, green: 0.85, blue: 0.5).opacity(0.9),
                                        skyTop.opacity(0.6)
                                    ],
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 50
                                )
                            )
                            .frame(width: 80, height: 80)
                            .position(x: centerX, y: sunY)

                        // Sun reflection on water
                        Ellipse()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.75, blue: 0.35).opacity(0.35),
                                        Color(red: 1.0, green: 0.65, blue: 0.3).opacity(0.15),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 60, height: geo.size.height * 0.38)
                            .position(x: centerX, y: geo.size.height * 0.72)
                            .blur(radius: 12)

                        // Center ripples
                        ForEach(0..<8, id: \.self) { i in
                            let phase = CGFloat(i) * 0.15
                            let wave = sin(t * 1.2 + Double(i) * 1.5) * 5
                            let yPos = geo.size.height * (0.54 + CGFloat(i) * 0.035)

                            Capsule()
                                .fill(Color.white.opacity(0.09 - Double(i) * 0.008))
                                .frame(
                                    width: 100 + CGFloat(i) * 28 + CGFloat(sin(t * 0.8 + phase)) * 18,
                                    height: 1.5
                                )
                                .position(x: centerX + CGFloat(wave), y: yPos)
                        }

                        // Wide ambient ripples across the water
                        ForEach(0..<6, id: \.self) { i in
                            let seed = Double(i) * 1.7 + 3.0
                            let wave = sin(t * 0.6 + seed) * 12
                            let yPos = geo.size.height * (0.60 + CGFloat(i) * 0.05)
                            let xShift = CGFloat(cos(t * 0.3 + seed)) * 40

                            Capsule()
                                .fill(Color.white.opacity(0.04 + sin(t * 0.5 + seed) * 0.02))
                                .frame(
                                    width: 180 + CGFloat(i) * 20 + CGFloat(sin(t * 0.7 + seed)) * 25,
                                    height: 1.2
                                )
                                .position(x: centerX + xShift + CGFloat(wave), y: yPos)
                        }

                        // Shimmer sparkles on water
                        ForEach(0..<14, id: \.self) { i in
                            let seed = Double(i) * 1.8
                            let sparkleX = centerX + CGFloat(sin(t * 0.4 + seed)) * 120 - 60
                            let sparkleY = geo.size.height * (0.53 + CGFloat(i) * 0.028)
                            let opacity = (sin(t * 2.0 + seed) + 1) * 0.14

                            Circle()
                                .fill(Color.white)
                                .frame(width: 2.5, height: 2.5)
                                .opacity(opacity)
                                .position(x: sparkleX, y: sparkleY)
                        }
                    }
                }
            }

            // Content overlay
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 100)

                Text("You've Found")
                    .font(.custom("Titan One", size: 42))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 6, y: 3)

                Text("Your Peace!")
                    .font(.custom("Titan One", size: 42))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 6, y: 3)

                Spacer()

                Button(action: onReturnHome) {
                    Text("Home")
                        .font(.body.bold())
                        .padding(.horizontal, 24)
                        .padding(.vertical, 1)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                .padding(.horizontal, 36)

                Spacer().frame(height: 80)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .animation(.easeOut(duration: 0.8), value: appeared)
        }
        .onAppear {
            appeared = true
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                sunPulse = true
            }
        }
    }
}

#Preview {
    PeaceCompletionView(onReturnHome: {})
}
