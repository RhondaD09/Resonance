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

    /// Maps breathScale to glow intensity. When not running, uses the
    /// independent orbBreathing animation for a gentle idle pulse.
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

            StarsBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text(isRunning ? phase.label : "Start Breathing")
                    .font(.system(size: 30, weight: .light))
                    .tracking(1.5)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top, 60)

                Spacer()

                // Spiral + glowing orb
                ZStack {
                    AnimatedSpiralBackground(breathScale: breathScale)
                        .frame(width: 380, height: 380)
                        .clipShape(Circle())

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
                            .font(.system(size: 48, weight: .ultraLight))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                Spacer()

                Button(action: {
                    toggle()
                }) {
                    Text(isRunning ? "Stop" : "Begin")
                        .font(.system(size: 16, weight: .medium))
                        .tracking(1)
                        .foregroundColor(Color("NewPurple"))
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.clear)
                                .overlay(
                                    Capsule()
                                        .stroke(Color("NewPurple"), lineWidth: 1.5)
                                )
                        )
                }
                .padding(.bottom, 16)

                Text("Cycle \(cycleCount)")
                    .font(.system(size: 13, weight: .light))
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
        .onReceive(timer) { _ in tick() }
    }

    //Logic

    private func toggle() {
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
            }

            // Voice
            voice.speak(phase.label)

            // Count completed cycles
            if phase == .inhale {
                cycleCount += 1
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



// Stars Background

private struct StarsBackground: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let starCount = 120
                for i in 0..<starCount {
                    let seed = Double(i)
                    let x = CGFloat(frac(sin(seed * 127.1 + 311.7) * 43758.5453)) * size.width
                    let y = CGFloat(frac(sin(seed * 269.5 + 183.3) * 43758.5453)) * size.height

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

    private func frac(_ x: Double) -> Double {
        x - floor(x)
    }
}

#Preview {
    CosmicBreathingView()
}
