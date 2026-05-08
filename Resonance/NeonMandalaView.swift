//
//  NeonMandalaView.swift
//  Resonance
//
//  Created by Rhonda Davis on 4/28/26.
//
//  An animated neon mandala on black — concentric rings of glowing
//  lotus petals with a small cyan starburst at its heart.
//
//  Tap the flower to start a 4-7-8 breathing exercise:
//    • Inhale  – 4 seconds (mandala expands)
//    • Hold    – 7 seconds (mandala holds expanded)
//    • Exhale  – 8 seconds (mandala contracts)
//  The cycle repeats four times, then stops automatically. Tapping
//  again at any point ends the session early.
//
//  Each phase transition is marked with a soft haptic tap and a
//  gentle sine-wave chime (C5 / E5 / G4 — a C-major triad).
//
//  Drop in as a root view:
//      NeonMandalaView()
//

import SwiftUI
import AVFoundation
import UIKit

// Breathing Phase

private enum NeonBreathPhase: String {
    case idle
    case inhale = "Inhale"
    case hold   = "Hold"
    case exhale = "Exhale"

    var seconds: Int {
        switch self {
        case .idle:   return 0
        case .inhale: return 4
        case .hold:   return 7
        case .exhale: return 8
        }
    }

    var chimeFrequency: Double {
        switch self {
        case .inhale: return 523.25
        case .hold:   return 659.25
        case .exhale: return 392.00
        case .idle:   return 0
        }
    }

    var hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .inhale: return .soft
        case .hold:   return .light
        case .exhale: return .medium
        case .idle:   return .light
        }
    }
}

//Root View

struct NeonMandalaView: View {

    var onComplete: (() -> Void)? = nil

    private let inhaleDuration: Double = 4
    private let holdDuration:   Double = 7
    private let exhaleDuration: Double = 8
    private let totalCycles:    Int    = 4

    private let restScale:    CGFloat = 1.00
    private let inhaledScale: CGFloat = 1.18

    @State private var isBreathing  = false
    @State private var sessionStart = Date()
    @State private var sessionID    = UUID()

    @State private var chimePlayer  = NeonChimePlayer()

    private var cycleDuration: Double {
        inhaleDuration + holdDuration + exhaleDuration
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TimelineView(.animation) { ctx in
                NeonMandalaContent(
                    date: ctx.date,
                    isBreathing: isBreathing,
                    totalCycles: totalCycles,
                    breathInfo: breathInfo(at: ctx.date)
                )
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { toggleBreathing() }
        .task(id: sessionID) {
            guard isBreathing else { return }
            await runSession()
        }
    }

    //Tap handling

    private func toggleBreathing() {
        if isBreathing {
            stopBreathing()
        } else {
            startBreathing()
        }
    }

    private func startBreathing() {
        sessionStart = Date()
        isBreathing  = true
        sessionID    = UUID()
    }

    private func stopBreathing() {
        withAnimation(.easeOut(duration: 0.4)) {
            isBreathing = false
        }
        chimePlayer.stop()
        sessionID = UUID()
    }

    // Session loop

    @MainActor
    private func runSession() async {
        for _ in 0..<totalCycles {
            trigger(.inhale)
            guard await sleep(inhaleDuration) else { return }

            trigger(.hold)
            guard await sleep(holdDuration) else { return }

            trigger(.exhale)
            guard await sleep(exhaleDuration) else { return }
        }
        if isBreathing {
            withAnimation(.easeOut(duration: 0.4)) {
                isBreathing = false
            }
            onComplete?()
        }
    }

    @MainActor
    private func trigger(_ phase: NeonBreathPhase) {
        guard isBreathing else { return }

        let gen = UIImpactFeedbackGenerator(style: phase.hapticStyle)
        gen.prepare()
        gen.impactOccurred()

        chimePlayer.playChime(frequency: phase.chimeFrequency)
    }

    private func sleep(_ duration: Double) async -> Bool {
        do {
            try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
        } catch {
            return false
        }
        return isBreathing
    }

    //Breath calculation

    fileprivate struct BreathInfo {
        var scale: CGFloat
        var phase: NeonBreathPhase
        var phaseProgress: Double
        var cycleIndex: Int
    }

    private func breathInfo(at now: Date) -> BreathInfo {
        guard isBreathing else {
            return BreathInfo(scale: restScale,
                              phase: .idle,
                              phaseProgress: 0,
                              cycleIndex: 0)
        }

        let elapsed    = now.timeIntervalSince(sessionStart)
        let cycleIndex = Int(elapsed / cycleDuration)

        if cycleIndex >= totalCycles {
            return BreathInfo(scale: restScale,
                              phase: .idle,
                              phaseProgress: 1,
                              cycleIndex: totalCycles)
        }

        let phaseTime = elapsed.truncatingRemainder(dividingBy: cycleDuration)

        if phaseTime < inhaleDuration {
            let p = phaseTime / inhaleDuration
            return BreathInfo(
                scale: restScale + (inhaledScale - restScale) * smoothstep(p),
                phase: .inhale,
                phaseProgress: p,
                cycleIndex: cycleIndex
            )
        } else if phaseTime < inhaleDuration + holdDuration {
            let p = (phaseTime - inhaleDuration) / holdDuration
            return BreathInfo(
                scale: inhaledScale,
                phase: .hold,
                phaseProgress: p,
                cycleIndex: cycleIndex
            )
        } else {
            let p = (phaseTime - inhaleDuration - holdDuration) / exhaleDuration
            return BreathInfo(
                scale: inhaledScale - (inhaledScale - restScale) * smoothstep(p),
                phase: .exhale,
                phaseProgress: p,
                cycleIndex: cycleIndex
            )
        }
    }

    private func smoothstep(_ x: Double) -> CGFloat {
        let t = max(0, min(1, x))
        return CGFloat(t * t * (3 - 2 * t))
    }
}

//Timeline Content

private struct NeonMandalaContent: View {
    let date: Date
    let isBreathing: Bool
    let totalCycles: Int
    let breathInfo: NeonMandalaView.BreathInfo

    var body: some View {
        ZStack {
            BreathingStarField(
                t: date.timeIntervalSinceReferenceDate,
                breathScale: breathInfo.scale
            )

            NeonMandala(t: date.timeIntervalSinceReferenceDate, breathScale: breathInfo.scale)

            VStack {
                Spacer()
                NeonBreathHUD(
                    phase: breathInfo.phase,
                    phaseProgress: breathInfo.phaseProgress,
                    cycleIndex: breathInfo.cycleIndex,
                    totalCycles: totalCycles,
                    isActive: isBreathing
                )
                .padding(.bottom, 60)
            }
        }
    }
}

// Breathing Star Field

private struct BreathingStarField: View {
    let t: Double
    let breathScale: CGFloat

    private static let stars: [(x: CGFloat, y: CGFloat, size: CGFloat, speed: Double, phase: Double)] = {
        var list: [(CGFloat, CGFloat, CGFloat, Double, Double)] = []
        var seed: UInt64 = 42
        for _ in 0..<80 {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            let x = CGFloat(seed % 10000) / 10000
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            let y = CGFloat(seed % 10000) / 10000
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            let size = 1.0 + CGFloat(seed % 10000) / 10000 * 2.5
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            let speed = 0.5 + Double(seed % 10000) / 10000 * 2.0
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            let phase = Double(seed % 10000) / 10000 * .pi * 2
            list.append((x, y, size, speed, phase))
        }
        return list
    }()

    var body: some View {
        Canvas { context, size in
            let glowIntensity = (breathScale - 1.0) / (1.18 - 1.0)
            let cx = size.width / 2
            let cy = size.height / 2

            for star in Self.stars {
                let baseX = star.x * size.width
                let baseY = star.y * size.height

                let dx = baseX - cx
                let dy = baseY - cy
                let drift = 1.0 + glowIntensity * 0.06
                let x = cx + dx * drift
                let y = cy + dy * drift

                let twinkle = 0.3 + 0.3 * sin(t * star.speed + star.phase)
                let breathBoost = 0.4 * glowIntensity
                let alpha = min(1.0, twinkle + breathBoost)

                let s = star.size * (1.0 + glowIntensity * 0.3)
                let rect = CGRect(x: x - s / 2, y: y - s / 2, width: s, height: s)
                context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(alpha)))

                if s > 2.2 {
                    let glowSize = s * (2.5 + glowIntensity * 1.5)
                    let glowRect = CGRect(
                        x: x - glowSize / 2,
                        y: y - glowSize / 2,
                        width: glowSize,
                        height: glowSize
                    )
                    context.fill(
                        Path(ellipseIn: glowRect),
                        with: .color(.cyan.opacity(alpha * 0.15))
                    )
                }
            }
        }
    }
}

//Neon Mandala Drawing

private struct NeonMandala: View {
    let t: Double
    let breathScale: CGFloat

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let baseRadius = min(size.width, size.height) * 0.50 * breathScale

            // Three concentric petal rings
            let ringConfigs: [(petals: Int, radiusFraction: CGFloat, color: Color, petalWidth: CGFloat)] = [
                (12, 1.0,  .cyan,    0.38),
                (10, 0.68, .purple,  0.34),
                (8,  0.40, .pink,    0.30),
            ]

            for (i, ring) in ringConfigs.enumerated() {
                let ringRadius = baseRadius * ring.radiusFraction
                let rotationOffset = t * (0.15 + Double(i) * 0.08) * (i.isMultiple(of: 2) ? 1 : -1)

                for j in 0..<ring.petals {
                    let angle = (Double(j) / Double(ring.petals)) * .pi * 2 + rotationOffset
                    let petalLength = ringRadius * 0.55
                    let petalW = ringRadius * ring.petalWidth

                    let petalCenter = CGPoint(
                        x: center.x + cos(angle) * ringRadius * 0.5,
                        y: center.y + sin(angle) * ringRadius * 0.5
                    )

                    var petalPath = Path()
                    petalPath.addEllipse(in: CGRect(
                        x: petalCenter.x - petalW / 2,
                        y: petalCenter.y - petalLength / 2,
                        width: petalW,
                        height: petalLength
                    ))

                    let transform = CGAffineTransform.identity
                        .translatedBy(x: petalCenter.x, y: petalCenter.y)
                        .rotated(by: CGFloat(angle) + .pi / 2)
                        .translatedBy(x: -petalCenter.x, y: -petalCenter.y)

                    let rotatedPetal = petalPath.applying(transform)

                    let glowAlpha = 0.25 + 0.15 * sin(t * 2.0 + Double(j) * 0.5)
                    context.fill(rotatedPetal, with: .color(ring.color.opacity(glowAlpha)))

                    context.stroke(
                        rotatedPetal,
                        with: .color(ring.color.opacity(0.7 + 0.3 * sin(t * 1.5 + Double(j)))),
                        lineWidth: 1.5
                    )
                }
            }

            // Breath-reactive glow intensity: 0 at rest, 1 at full inhale
            let glowIntensity = CGFloat((breathScale - 1.0) / (1.18 - 1.0))

            // Outer glow halo — large, soft, breathes with inhale/exhale
            let outerGlowSize: CGFloat = 90 + 50 * glowIntensity
            let outerGlowRect = CGRect(
                x: center.x - outerGlowSize / 2,
                y: center.y - outerGlowSize / 2,
                width: outerGlowSize,
                height: outerGlowSize
            )
            let outerPulse = 0.12 + 0.18 * glowIntensity + 0.04 * sin(t * 1.8)
            context.fill(
                Path(ellipseIn: outerGlowRect),
                with: .color(.cyan.opacity(outerPulse))
            )

            // Middle glow ring
            let midGlowSize: CGFloat = 56 + 30 * glowIntensity
            let midGlowRect = CGRect(
                x: center.x - midGlowSize / 2,
                y: center.y - midGlowSize / 2,
                width: midGlowSize,
                height: midGlowSize
            )
            let midPulse = 0.2 + 0.3 * glowIntensity + 0.05 * sin(t * 2.2 + 0.5)
            context.fill(
                Path(ellipseIn: midGlowRect),
                with: .color(.cyan.opacity(midPulse))
            )

            // Center starburst — rays scale and brighten with breath
            let starburstRays = 20
            let starburstRadius = baseRadius * (0.14 + 0.08 * glowIntensity)
            for k in 0..<starburstRays {
                let angle = (Double(k) / Double(starburstRays)) * .pi * 2 + t * 0.6
                let rayLength = starburstRadius * (0.5 + 0.5 * sin(t * 2.5 + Double(k) * 0.8))
                var ray = Path()
                ray.move(to: center)
                ray.addLine(to: CGPoint(
                    x: center.x + cos(angle) * rayLength,
                    y: center.y + sin(angle) * rayLength
                ))
                let rayBrightness = 0.5 + 0.5 * glowIntensity + 0.3 * sin(t * 2.0 + Double(k))
                context.stroke(
                    ray,
                    with: .color(.cyan.opacity(min(1.0, rayBrightness))),
                    lineWidth: 1.5 + 0.8 * glowIntensity
                )
            }

            // Inner glow core
            let innerGlowSize: CGFloat = 32 + 14 * glowIntensity
            let innerGlowRect = CGRect(
                x: center.x - innerGlowSize / 2,
                y: center.y - innerGlowSize / 2,
                width: innerGlowSize,
                height: innerGlowSize
            )
            let innerPulse = 0.35 + 0.4 * glowIntensity + 0.06 * sin(t * 2.6 + 1.0)
            context.fill(
                Path(ellipseIn: innerGlowRect),
                with: .color(.white.opacity(innerPulse))
            )

            // Center dot — bright core that intensifies with breath
            let dotSize: CGFloat = 18 + 6 * glowIntensity
            context.fill(
                Path(ellipseIn: CGRect(
                    x: center.x - dotSize / 2,
                    y: center.y - dotSize / 2,
                    width: dotSize,
                    height: dotSize
                )),
                with: .color(.white.opacity(0.85 + 0.15 * glowIntensity))
            )
        }
    }
}

// Breath HUD

private struct NeonBreathHUD: View {
    let phase: NeonBreathPhase
    let phaseProgress: Double
    let cycleIndex: Int
    let totalCycles: Int
    let isActive: Bool

    var body: some View {
        VStack(spacing: 10) {
            if isActive && phase != .idle {
                Text(phase.rawValue)
                    .font(.system(size: 28, weight: .light, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .cyan.opacity(0.7), radius: 6)
                    .transition(.opacity)

                Text("\(remainingSeconds)")
                    .font(.system(size: 44, weight: .ultraLight, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))
                    .monospacedDigit()
                    .shadow(color: .cyan.opacity(0.5), radius: 4)

                Text("Cycle \(min(cycleIndex + 1, totalCycles)) of \(totalCycles)")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                    .padding(.top, 2)
            } else {
                Text("Tap the flower to begin")
                    .font(.system(size: 15, weight: .light, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: phase)
        .animation(.easeInOut(duration: 0.35), value: isActive)
    }

    private var remainingSeconds: Int {
        let total = phase.seconds
        let done  = Int(Double(total) * phaseProgress)
        return max(1, total - done)
    }
}

// Chime Player

@MainActor
final class NeonChimePlayer {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate: Double = 44_100
    private let format: AVAudioFormat
    private var didConfigureSession = false

    init() {
        format = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: 1
        )!
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    func playChime(frequency: Double) {
        guard frequency > 0 else { return }
        configureSessionIfNeeded()
        startEngineIfNeeded()

        let duration: Double = 0.6
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        guard let data = buffer.floatChannelData?[0] else { return }

        let attack: Double = 0.01
        let release: Double = duration - attack

        for i in 0..<Int(frameCount) {
            let time = Double(i) / sampleRate
            let fundamental = sin(2.0 * .pi * frequency * time)
            let overtone = 0.3 * sin(2.0 * .pi * frequency * 2.0 * time)
            let sample = fundamental + overtone

            let envelope: Double
            if time < attack {
                envelope = time / attack
            } else {
                let releaseTime = time - attack
                envelope = max(0, 1.0 - releaseTime / release)
            }

            data[i] = Float(sample * envelope * 0.15)
        }

        player.scheduleBuffer(buffer, completionHandler: nil)
    }

    func stop() {
        player.stop()
    }

    private func configureSessionIfNeeded() {
        guard !didConfigureSession else { return }
        didConfigureSession = true
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: .mixWithOthers)
        try? session.setActive(true)
    }

    private func startEngineIfNeeded() {
        guard !engine.isRunning else { return }
        do {
            try engine.start()
            player.play()
        } catch {
            // Engine failed to start
        }
    }
}



#Preview {
    NeonMandalaView()
}
