//
//  CosmicBreathingView.swift
//  Resonance
//
//  Created by Rhonda Davis on 4/16/26.
//

import SwiftUI
import AVFoundation
import CoreMotion
import Combine
import CoreGraphics

//Motion Manager

final class MotionManager: ObservableObject {
    private let manager = CMMotionManager()

    @Published var tiltX: CGFloat = 0
    @Published var tiltY: CGFloat = 0

    init() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1 / 60

        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self = self, let motion = motion else { return }
            DispatchQueue.main.async {
                self.tiltX = CGFloat(motion.gravity.x).clamped(to: -0.3...0.3)
                self.tiltY = CGFloat(motion.gravity.y).clamped(to: -0.3...0.3)
            }
        }
    }

    deinit { manager.stopDeviceMotionUpdates() }
}

// Helpers

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

//Breath Phase

enum BreathPhase: Int, CaseIterable {
    case inhale, hold, exhale

    var label: String {
        ["Inhale", "Hold", "Exhale"][rawValue]
    }

    var duration: Double {
        [4, 7, 8][rawValue]
    }
}

//Audio Manager

final class AudioManager: ObservableObject {
    private var engine: AVAudioEngine?
    @Published var amplitude: CGFloat = 0

    func start() {
        #if targetEnvironment(simulator)
        return
        #else
        let audioEngine = AVAudioEngine()
        self.engine = audioEngine

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)

        guard format.channelCount > 0 else { return }

        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            let level = self.rms(buffer: buffer)
            DispatchQueue.main.async {
                self.amplitude = level
            }
        }

        do {
            try audioEngine.start()
        } catch {
            // Audio engine unavailable — continue without mic input
        }
        #endif
    }

    private func rms(buffer: AVAudioPCMBuffer) -> CGFloat {
        guard let data = buffer.floatChannelData?[0] else { return 0 }
        let frames = Int(buffer.frameLength)
        let sum = (0..<frames).map { data[$0] * data[$0] }.reduce(0, +)
        return CGFloat(min(max(sqrt(sum / Float(frames)) * 8, 0), 1))
    }
}

//Voice Guide

final class VoiceGuideManager: ObservableObject {
    private let synth = AVSpeechSynthesizer()

    func speak(_ text: String) {
        let u = AVSpeechUtterance(string: text)
        u.rate = 0.4
        u.pitchMultiplier = 0.9
        synth.speak(u)
    }
}

//Main View

struct CosmicBreathingView: View {

    var onComplete: (() -> Void)? = nil

    @StateObject private var motion = MotionManager()
    @StateObject private var audio = AudioManager()
    @StateObject private var voice = VoiceGuideManager()

    @State private var phase: BreathPhase = .inhale
    @State private var progress: Double = 0
    @State private var breathScale: CGFloat = 1.0
    @State private var isRunning = false
    @State private var countdown = 4
    @State private var cycleCount = 0

    @State private var timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
    @State private var orbBreathing: Bool = false
    @State private var phaseTrigger: Int = 0
    @State private var cycleTrigger: Int = 0
    @State private var buttonTrigger: Int = 0


    private var orbGlowIntensity: Double {
        if isRunning {
            let normalized = (breathScale - 0.85) / 0.30
            return 0.3 + Double(normalized.clamped(to: 0...1)) * 0.7
        }
        return 0.5 // idle baseline — orbBreathing animation handles the rest
    }

    var body: some View {
        ZStack {
            // Dark background with stars
            Color(red: 5/255, green: 3/255, blue: 15/255)
                .ignoresSafeArea()

            StarsBackground(breathScale: breathScale)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text(isRunning ? phase.label : "Start Breathing")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(Color(red: 125/255, green: 10/255, blue: 255/255))
                    .padding(.top, 60)

                Spacer()

                // Spiral + lotus + glowing orb
                ZStack {
                    AnimatedSpiralBackground(breathScale: breathScale)
                        .frame(width: 390, height: 390)
                        .clipShape(Circle())

                    // Cosmic mandala — meditative focal point.
                    // Sacred-geometry rings sit above the spiral but beneath
                    // the orb glow so the orb burns at the mandala's heart.
//                    CosmicMandala(
//                        breathScale: breathScale,
//                        glowIntensity: orbGlowIntensity
//                    )
//                    .frame(width: 360, height: 360)
//                    .allowsHitTesting(false)

                    // Wide ambient halo — big soft throb
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.3, blue: 0.9).opacity(0.12 * orbGlowIntensity),
                                    Color(red: 0.3, green: 0.2, blue: 0.7).opacity(0.05 * orbGlowIntensity),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 180
                            )
                        )
                        .frame(width: 360, height: 360)
                        .scaleEffect(orbBreathing ? 1.4 : 0.7)
                        .blur(radius: 40)

                    // Main orb glow — large, soft pulse
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.5, green: 0.4, blue: 1.0).opacity(0.35 * orbGlowIntensity),
                                    Color(red: 0.3, green: 0.2, blue: 0.8).opacity(0.18 * orbGlowIntensity),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 25,
                                endRadius: 75
                            )
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(orbBreathing ? 1.3 : 0.75)
                        .blur(radius: 12)

                    // Inner core — soft and big
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.4 * orbGlowIntensity),
                                    Color(red: 0.6, green: 0.5, blue: 1.0).opacity(0.25 * orbGlowIntensity),
                                    Color(red: 0.4, green: 0.3, blue: 0.9).opacity(0.1 * orbGlowIntensity),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                        .frame(width: 100, height: 100)
                        .scaleEffect(orbBreathing ? 1.2 : 0.8)
                        .blur(radius: 8)

                    // Center point — soft glow
                    Circle()
                        .fill(Color.white.opacity(orbBreathing ? 0.5 : 0.15))
                        .frame(width: 40, height: 40)
                        .blur(radius: 6)
                        .scaleEffect(orbBreathing ? 1.15 : 0.85)

                    // Soft ring pulse — big and gentle
                    Circle()
                        .stroke(
                            Color(red: 0.6, green: 0.5, blue: 1.0).opacity(orbBreathing ? 0.18 : 0.03),
                            lineWidth: 1.5
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(orbBreathing ? 1.4 : 0.75)
                        .blur(radius: 6)

                    // Countdown over the orb
                    if isRunning {
                        Text("\(countdown)")
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .foregroundColor(Color(red: 125/255, green: 10/255,  blue: 255/255))
                    }
                }

                Spacer()

                Button(action: {
                    toggle()
                }) {
                    Text(isRunning ? "Stop" : "Begin")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .tracking(1)
                        .foregroundColor(Color(red: 125/255, green: 120/255, blue: 255/255))
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.clear)
                                .overlay(
                                    Capsule()
                                        .stroke(Color(red: 125/255, green: 10/255, blue: 255/255), lineWidth: 1.5)
                                )
                        )
                }
                .padding(.bottom, 16)

                Text("Cycle \(cycleCount)")
                    .font(.system(.footnote, design: .rounded, weight: .light))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            audio.start()
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                orbBreathing = true
            }
        }
        .sensoryFeedback(.selection, trigger: phaseTrigger)
        .sensoryFeedback(.impact(weight: .heavy), trigger: cycleTrigger)
        .sensoryFeedback(.impact(weight: .light), trigger: buttonTrigger)
        .onReceive(timer) { _ in tick() }
        .dynamicTypeSize(.xSmall ... .xxxLarge)
    }

    //Logic

    private func toggle() {
        buttonTrigger += 1
        isRunning.toggle()
        progress = 0
        phase = .inhale
        countdown = Int(phase.duration)
        if !isRunning {
            withAnimation(.easeOut(duration: 0.5)) {
                breathScale = 1.0
            }
        }
    }

    private func tick() {
        let dt = 1.0 / 60.0

        guard isRunning else { return }

        progress += dt / phase.duration

        let remaining = phase.duration * (1 - progress)
        countdown = max(1, Int(remaining.rounded(.up)))

        // Audio influence
        breathScale += audio.amplitude * 0.02

        if progress >= 1 {
            progress = 0

            let next = (phase.rawValue + 1) % BreathPhase.allCases.count
            if let newPhase = BreathPhase(rawValue: next) {
                phase = newPhase
                phaseTrigger += 1
            }

            // Voice
            voice.speak(phase.label)

            // Count completed cycles
            if phase == .inhale {
                cycleCount += 1
                cycleTrigger += 1
                if cycleCount >= 4 {
                    isRunning = false
                    withAnimation(.easeOut(duration: 0.5)) {
                        breathScale = 1.0
                    }
                    onComplete?()
                    return
                }
            }
        }

        // Breathing drives the spiral scale
        switch phase {
        case .inhale:
            breathScale = 0.85 + 0.3 * CGFloat(progress)
        case .hold:
            breathScale = 1.15
        case .exhale:
            breathScale = 1.15 - 0.3 * CGFloat(progress)
        }
    }
}


// MARK: - Cosmic Mandala
//
// A sacred-geometry focal point: concentric rings of triangles, dots,
// diamonds, and star polygons that slowly counter-rotate around the
// orb. Crisp geometric edges (rather than blurred glow) give the
// mandala a clear, contemplative presence against the spiral and orb.
// The whole figure scales gently with `breathScale` and brightens
// with `glowIntensity`, so it breathes alongside the orb.

struct CosmicMandala: View {
    let breathScale: CGFloat
    let glowIntensity: Double

    // Violet palette tuned to the existing cosmic theme
    private let bright  = Color(red: 0.92, green: 0.88, blue: 1.00)
    private let primary = Color(red: 0.65, green: 0.50, blue: 1.00)
    private let accent  = Color(red: 0.85, green: 0.55, blue: 1.00)

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            let slow = t * 2.5  // ~144s/revolution — meditative pace

            GeometryReader { geo in
                let s = min(geo.size.width, geo.size.height)

                ZStack {
                    // Outermost guide circle — single thin boundary
                    Circle()
                        .stroke(primary.opacity(0.30 * glowIntensity), lineWidth: 1.0)
                        .frame(width: s * 0.94, height: s * 0.94)

                    // Outer flower-of-life ring — 24 overlapping circles
                    flowerOfLifeRing(count: 24,
                                     ringRadius: s * 0.42,
                                     overlap: 1.18,
                                     rotation: slow * 0.4,
                                     color: bright,
                                     opacity: 0.50,
                                     lineWidth: 0.9)

                    // 8-pointed star (octagram) — outer sacred polygon
                    StarPolygon(points: 8, innerRatio: 0.5)
                        .stroke(accent.opacity(0.55 * glowIntensity), lineWidth: 1.2)
                        .frame(width: s * 0.74, height: s * 0.74)
                        .rotationEffect(.degrees(-slow * 0.7))

                    // Middle flower-of-life ring — 18 circles, counter-rotating
                    flowerOfLifeRing(count: 18,
                                     ringRadius: s * 0.30,
                                     overlap: 1.20,
                                     rotation: -slow * 0.6,
                                     color: primary,
                                     opacity: 0.55,
                                     lineWidth: 0.9)

                    // 6-pointed star (hexagram) — inner sacred polygon
                    StarPolygon(points: 6, innerRatio: 0.58)
                        .stroke(bright.opacity(0.70 * glowIntensity), lineWidth: 1.0)
                        .frame(width: s * 0.42, height: s * 0.42)
                        .rotationEffect(.degrees(slow * 1.5))

                    // Tiny dot ring weaving between the larger elements
                    dotRing(count: 24,
                            radius: s * 0.36,
                            size: s * 0.008,
                            rotation: -slow * 0.5,
                            color: bright,
                            opacity: 0.9)

                    // Inner flower-of-life ring — 12 circles
                    flowerOfLifeRing(count: 12,
                                     ringRadius: s * 0.18,
                                     overlap: 1.22,
                                     rotation: slow * 0.9,
                                     color: accent,
                                     opacity: 0.60,
                                     lineWidth: 0.9)

                    // Seed of Life at the heart — 1 center + 6 around
                    seedOfLife(unit: s * 0.045,
                               color: bright,
                               opacity: 0.75,
                               lineWidth: 0.9)
                }
                .frame(width: s, height: s)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                .scaleEffect(breathScale) // breathes with the user
                .shadow(color: primary.opacity(0.35 * glowIntensity), radius: 6)
            }
        }
    }

    // Building blocks

    /// A ring of `count` overlapping circles around the center.
    /// Adjacent circles intersect to form vesica-piscis petals — the
    /// foundation of flower-of-life sacred geometry.
    @ViewBuilder
    private func flowerOfLifeRing(count: Int, ringRadius: CGFloat,
                                  overlap: CGFloat, rotation: Double,
                                  color: Color, opacity: Double,
                                  lineWidth: CGFloat) -> some View {
        // Small-circle radius so adjacent circles touch (overlap = 1) or
        // overlap (overlap > 1).
        let r = ringRadius * CGFloat(sin(.pi / Double(count))) * overlap

        ForEach(0..<count, id: \.self) { i in
            let angle = Double(i) * 360.0 / Double(count) + rotation
            Circle()
                .stroke(color.opacity(opacity * glowIntensity), lineWidth: lineWidth)
                .frame(width: r * 2, height: r * 2)
                .offset(y: -ringRadius)
                .rotationEffect(.degrees(angle))
        }
    }

    /// Classic Seed of Life — 1 center circle + 6 around, all the same
    /// radius, surrounding circles centered exactly one radius from the
    /// origin so they overlap the center one perfectly.
    @ViewBuilder
    private func seedOfLife(unit: CGFloat, color: Color,
                            opacity: Double, lineWidth: CGFloat) -> some View {
        Circle()
            .stroke(color.opacity(opacity * glowIntensity), lineWidth: lineWidth)
            .frame(width: unit * 2, height: unit * 2)

        ForEach(0..<6, id: \.self) { i in
            Circle()
                .stroke(color.opacity(opacity * glowIntensity), lineWidth: lineWidth)
                .frame(width: unit * 2, height: unit * 2)
                .offset(y: -unit)
                .rotationEffect(.degrees(Double(i) * 60.0))
        }
    }

    @ViewBuilder
    private func dotRing(count: Int, radius: CGFloat, size: CGFloat,
                         rotation: Double, color: Color, opacity: Double) -> some View {
        ForEach(0..<count, id: \.self) { i in
            let angle = Double(i) * 360.0 / Double(count) + rotation
            Circle()
                .fill(color.opacity(opacity * glowIntensity))
                .frame(width: size, height: size)
                .offset(y: -radius)
                .rotationEffect(.degrees(angle))
        }
    }
}

// Mandala Shapes

/// A regular star polygon with `points` outer vertices.
/// `innerRatio` controls how "sharp" the star is (0.5 = classic star).
struct StarPolygon: Shape {
    let points: Int
    let innerRatio: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerR = min(rect.width, rect.height) / 2
        let innerR = outerR * innerRatio
        let totalVerts = points * 2
        let step = (.pi * 2) / CGFloat(totalVerts)

        for i in 0..<totalVerts {
            let r = (i % 2 == 0) ? outerR : innerR
            let angle = -CGFloat.pi / 2 + CGFloat(i) * step
            let pt = CGPoint(
                x: center.x + cos(angle) * r,
                y: center.y + sin(angle) * r
            )
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }
}


// Stars Background

struct StarsBackground: View {
    var breathScale: CGFloat = 1.0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let centerX = size.width / 2
                let centerY = size.height / 2
                let starCount = 120
                for i in 0..<starCount {
                    let seed = Double(i)
                    let baseX = CGFloat(frac(sin(seed * 127.1 + 311.7) * 43758.5453)) * size.width
                    let baseY = CGFloat(frac(sin(seed * 269.5 + 183.3) * 43758.5453)) * size.height

                    let dx = baseX - centerX
                    let dy = baseY - centerY
                    let x = centerX + dx * breathScale
                    let y = centerY + dy * breathScale

                    let brightness = frac(sin(seed * 419.2 + 73.1) * 43758.5453)
                    let twinkleSpeed = 0.4 + brightness * 2.5
                    let twinkle = 0.3 + 0.7 * (0.5 + 0.5 * sin(time * twinkleSpeed + seed * 2.1))
                    let starSize = CGFloat(0.8 + brightness * 2.0)
                    let alpha = twinkle * (0.3 + brightness * 0.6)

                    ctx.fill(
                        Path(ellipseIn: CGRect(x: x - starSize / 2, y: y - starSize / 2,
                                               width: starSize, height: starSize)),
                        with: .color(.white.opacity(alpha))
                    )
                }
            }
        }
    }

    func frac(_ x: Double) -> Double {
        x - floor(x)
    }
}

#Preview {
    CosmicBreathingView()
}
