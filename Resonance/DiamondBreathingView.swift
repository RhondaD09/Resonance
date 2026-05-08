//
//  DiamondBreathingView.swift
//  Resonance
//
//  Created by Alexus WIlliams on 5/1/26.
//

import SwiftUI

// triangle piece model
struct TrianglePiece: Identifiable {
    let id: Int
    let scatterOffset: CGSize
    let rotation: Double
    let scatterRotation: Double
    let size: CGFloat
    let delay: Double
}

// triangle shape
struct TriangleShape: Shape {
    var pointsUp: Bool = true

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if pointsUp {
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        } else {
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        }
        path.closeSubpath()
        return path
    }
}


// main diamond view
struct BreathingDiamondView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var isAssembled: Bool = false

    @State private var triangleOpacity: Double = 1.0

    @State private var diamondImageOpacity: Double = 0.0

    @State private var glowOpacity: Double = 0.15
    @State private var glowScale: CGFloat = 0.7

    @State private var imageScale: CGFloat = 0.92

    @State private var breathText: String = "Breathe In"
    @State private var textOpacity: Double = 0.0
    @State private var cycleCount: Int = 0
    @State private var navigateToCompletion: Bool = false


    let diamondColor = Color(red: 0.95, green: 0.45, blue: 0.50)
    let triSize: CGFloat = 88

    let inhaleDuration:  Double = 5.0
    let imageFadeIn:     Double = 1.6
    let holdInhale:      Double = 0.0
    let imageFadeOut:    Double = 1.6
    let exhaleDuration:  Double = 5.0
    let holdExhale:      Double = 0.0

    var pieces: [TrianglePiece] {
        let s = triSize
        let totalPieces = 14

        return (0..<totalPieces).map { index in

            // evenly distribute around a circle
            let angle = Double(index) / Double(totalPieces) * (.pi * 2)

            let x = cos(angle) * 0.75
            let y = sin(angle) * 0.75

            return TrianglePiece(
                id: index,

                scatterOffset: CGSize(
                    width: x,
                    height: y
                ),

                rotation: index % 2 == 0 ? 0 : 180,

                scatterRotation: index % 2 == 0 ? 18 : -18,

                size: s,

                delay: Double(index) * 0.03
            )
        }
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if navigateToCompletion {
                    BreathCompletionCheckIn(
                        onFeelingGrounded: {},
                        onNeedMorePeace: {},
                        onReturnHome: { dismiss() }
                    )
                    .transition(.opacity)
                } else {
                    ZStack {

                    // background
                    Color.black.ignoresSafeArea()
                    StarsBackground()
                        .ignoresSafeArea()
                    RadialGradient(
                        gradient: Gradient(colors: [
                            diamondColor.opacity(0.45),
                            diamondColor.opacity(0.08),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 320
                    )
                    .ignoresSafeArea()
                    .opacity(glowOpacity)
                    .scaleEffect(glowScale)


                    VStack {
                        Spacer()

                        ZStack {
                            ZStack {
                                ForEach(pieces) { piece in TriangleShape(pointsUp: piece.rotation == 0)
                                        .stroke(
                                            diamondColor,
                                            style: StrokeStyle(lineWidth: 2.5, lineJoin: .round)
                                        )
                                        .frame(width: piece.size, height: piece.size * 0.760)
                                        .shadow(color: diamondColor.opacity(0.85), radius: 7)

                                        .offset(
                                            isAssembled
                                            ? .zero
                                            : scaledScatterOffset(from: piece.scatterOffset, in: proxy.size)
                                        )

                                        .rotationEffect(.degrees(
                                            isAssembled
                                                ? piece.rotation
                                                : piece.rotation + piece.scatterRotation
                                        ))

                                        .animation(
                                            .easeInOut(duration: isAssembled ? inhaleDuration : exhaleDuration)
                                            .delay(isAssembled
                                                   ? piece.delay * 0.4
                                                   : piece.delay * 0.8),
                                            value: isAssembled
                                        )
                                }
                            }
                            .opacity(triangleOpacity)
                            Image("Diamond")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 300)
                                .shadow(color: diamondColor.opacity(0.85), radius: 18)
                                .shadow(color: diamondColor.opacity(0.40), radius: 42)
                                .scaleEffect(imageScale)
                                .opacity(diamondImageOpacity)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity).frame(maxWidth: .infinity, maxHeight: .infinity)
                        Text(breathText)
                            .font(.system(size: 20, weight: .ultraLight, design: .rounded))
                            .foregroundColor(diamondColor.opacity(0.80))
                            .tracking(6)
                            .opacity(textOpacity)
                            .padding(.top, 28)

                        Spacer()
                    }
                }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            startBreathingCycle()
                        }
                    }
                    .transition(.opacity)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func scaledScatterOffset(from normalized: CGSize, in container: CGSize) -> CGSize {
        let horizontalPadding = triSize * 0.72
        let verticalPadding = triSize * 1.00

        let maxX = max((container.width * 0.5) - horizontalPadding, 0)
        let maxY = max((container.height * 0.5) - verticalPadding, 0)

        return CGSize(width: normalized.width * maxX, height: normalized.height * maxY)
    }

    func startBreathingCycle() {
        breathText = "Breathe In"
        withAnimation(.easeInOut(duration: 1.0)) {
            textOpacity = 0.85
        }
        withAnimation(.easeInOut(duration: inhaleDuration)) {
            isAssembled = true
        }
        withAnimation(.easeInOut(duration: inhaleDuration + 0.5)) {
            glowOpacity = 0.85
            glowScale   = 1.35
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: imageFadeIn)) {
                diamondImageOpacity = 1.0
                triangleOpacity     = 0.0
            }
            withAnimation(.easeInOut(duration: imageFadeIn)) {
                imageScale = 1.06
            }
        }

        let exhaleStart = inhaleDuration
        // = 4.0s after cycle start
        DispatchQueue.main.asyncAfter(deadline: .now() + exhaleStart) {
            withAnimation(.easeInOut(duration: 0.4)) {
                textOpacity = 0.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                breathText = "Breathe Out"
                withAnimation(.easeInOut(duration: 0.4)) {
                    textOpacity = 0.85
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + exhaleStart + 0.3) {
            withAnimation(.easeInOut(duration: imageFadeOut)) {
                diamondImageOpacity = 0.0
                triangleOpacity     = 1.0
            }
            withAnimation(.easeInOut(duration: imageFadeOut)) {
                imageScale = 0.92
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + exhaleStart + 0.5) {
            withAnimation(.easeInOut(duration: exhaleDuration + 0.5)) {
                glowOpacity = 0.15
                glowScale   = 0.70
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + exhaleStart + 1.2) {
            withAnimation(.easeInOut(duration: exhaleDuration)) {
                isAssembled = false
            }
        }
        let cycleLength = exhaleStart + exhaleDuration + 1.2

        DispatchQueue.main.asyncAfter(deadline: .now() + cycleLength) {
          
// Cycle change
            cycleCount += 1
            if cycleCount < 6 {
                startBreathingCycle()
            } else {
                withAnimation(.easeInOut(duration: 0.8)) {
                    textOpacity = 0.0
                }
                // Navigate to completion check-in after finishing 6 cycles
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
    BreathingDiamondView()
}
