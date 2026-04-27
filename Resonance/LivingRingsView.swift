//
//  LivingRingsView.swift
//  Resonance
//
//  Created by Rhonda Davis on 4/27/26.
//

import SwiftUI

struct LivingRingsView: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                Color.black.ignoresSafeArea()

                // Soft glow behind rings
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.purple.opacity(0.22),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 180
                        )
                    )
                    .frame(width: 360, height: 360)
                    .blur(radius: 22)

                ResonanceRings(t: t)
                    .frame(width: 320, height: 320)
            }
        }
    }
}

private struct ResonanceRings: View {
    let t: TimeInterval
    private let ringCount = 14

    var body: some View {
        ZStack {
            ForEach(0..<ringCount, id: \.self) { i in
                let p = Double(i) / Double(ringCount - 1) // 0...1
                let radius = 22 + CGFloat(i) * 10.8
                let wobble = 0.015 * sin(t * 1.2 + Double(i) * 0.7)
                let rotation = Angle.degrees(t * (i % 2 == 0 ? 3.2 : -2.6) + Double(i) * 6.0)
                let head = 0.78 + 0.14 * sin(t * 0.9 + Double(i) * 0.4)
                let tail = max(0.08, head - (0.62 + 0.06 * sin(t * 1.5 + Double(i))))
                let alpha = 0.55 + 0.35 * sin(t * 1.1 + Double(i) * 0.3)

                Circle()
                    .trim(from: tail + wobble, to: min(0.999, head + wobble))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.25, green: 0.00, blue: 0.45).opacity(0.95), // deep violet
                                Color(red: 0.55, green: 0.20, blue: 0.80).opacity(0.95), // purple
                                Color(red: 0.90, green: 0.84, blue: 0.20).opacity(0.90), // gold
                                Color(red: 0.45, green: 0.00, blue: 0.60).opacity(0.95)  // violet
                            ]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 2.2 - CGFloat(p) * 0.8, lineCap: .round)
                    )
                    .frame(width: radius * 2, height: radius * 2)
                    .rotationEffect(rotation)
                    .opacity(alpha)

                // Subtle full-ring ghost line to keep concentric structure visible
                Circle()
                    .stroke(
                        Color(red: 0.40, green: 0.14, blue: 0.58).opacity(0.22),
                        lineWidth: 0.8
                    )
                    .frame(width: radius * 2, height: radius * 2)
            }

            // Center pulse
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.yellow.opacity(0.85),
                            Color.purple.opacity(0.45),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 28
                    )
                )
                .frame(width: 54, height: 54)
                .scaleEffect(0.92 + 0.10 * sin(t * 2.1))
                .blur(radius: 0.4)
        }
        .compositingGroup()
        .drawingGroup()
    }
}

#Preview {
    LivingRingsView()
}
