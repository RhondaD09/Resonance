//
//  WhiteNoisePlayer.swift
//  Resonance
//

import SwiftUI
import AVFoundation
import Observation

//AmbientSound

enum AmbientSound: String, CaseIterable, Identifiable {
    case white, pink, brown, rain, ocean, fire

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .white:  return "🌫️"
        case .pink:   return "🌸"
        case .brown:  return "🌿"
        case .rain:   return "🌧️"
        case .ocean:  return "🌊"
        case .fire:   return "🔥"
        }
    }

    var accent: Color {
        switch self {
        case .white:  return .rText
        case .pink:   return .rRose
        case .brown:  return .rGold
        case .rain:   return .rSky
        case .ocean:  return .rTeal
        case .fire:   return Color(red: 251/255, green: 146/255, blue: 60/255)
        }
    }

    var subtitle: String {
        switch self {
        case .white:  return "Pure · masking"
        case .pink:   return "Soft · balanced"
        case .brown:  return "Deep · grounding"
        case .rain:   return "Gentle · rhythmic"
        case .ocean:  return "Flowing · vast"
        case .fire:   return "Crackling · warm"
        }
    }
}

//SoundState

private final class SoundState: @unchecked Sendable {
    // Amplitude smoothing
    var amplitude: Float = 0
    var target: Float = 0

    // Pink noise IIR state (Kellett algorithm)
    var b0: Float = 0
    var b1: Float = 0
    var b2: Float = 0
    var b3: Float = 0
    var b4: Float = 0
    var b5: Float = 0
    var b6: Float = 0

    // Brown noise integrator
    var brown: Float = 0

    // LFO phases for rain/ocean/fire
    var lfo0: Double = 0
    var lfo1: Double = 0
}

// WhiteNoisePlayer

@Observable
final class WhiteNoisePlayer {
    static let shared = WhiteNoisePlayer()

    var activeSounds: Set<AmbientSound> = []
    var volumes: [AmbientSound: Float] = {
        var dict: [AmbientSound: Float] = [:]
        for s in AmbientSound.allCases { dict[s] = 0.65 }
        return dict
    }()

    /// Aggregate energy 0…1 based on active sounds and their volumes
    var energy: Double {
        guard !activeSounds.isEmpty else { return 0 }
        let totalVol = activeSounds.reduce(0.0) { $0 + Double(volumes[$1] ?? 0.65) }
        let avgVol = totalVol / Double(activeSounds.count)
        // Scale up with more sounds (1 sound = base, 6 sounds = 1.0)
        let countFactor = min(Double(activeSounds.count) / 4.0, 1.0)
        return min(avgVol * (0.5 + countFactor * 0.5), 1.0)
    }

    /// Pulse speed multiplier based on sound character
    var pulseSpeed: Double {
        guard !activeSounds.isEmpty else { return 1.0 }
        // Faster sounds (fire, rain) pulse quicker; slower (ocean, brown) pulse slower
        var speed = 0.0
        for sound in activeSounds {
            switch sound {
            case .fire:   speed += 1.4
            case .rain:   speed += 1.2
            case .white:  speed += 1.0
            case .pink:   speed += 0.9
            case .ocean:  speed += 0.7
            case .brown:  speed += 0.6
            }
        }
        return speed / Double(activeSounds.count)
    }

    private var engine = AVAudioEngine()
    private var nodes: [AmbientSound: AVAudioSourceNode] = [:]
    private var states: [AmbientSound: SoundState] = {
        var dict: [AmbientSound: SoundState] = [:]
        for s in AmbientSound.allCases { dict[s] = SoundState() }
        return dict
    }()
    private var engineRunning: Bool = false

    private init() {}

    deinit {
        engine.stop()
    }

    // Public API

    func toggle(_ sound: AmbientSound) {
        if activeSounds.contains(sound) {
            activeSounds.remove(sound)
            states[sound]?.target = 0
            scheduleStop()
        } else {
            activeSounds.insert(sound)
            let vol = volumes[sound] ?? 0.65
            states[sound]?.target = vol
            ensureRunning()
        }
    }

    func setVolume(_ vol: Float, for sound: AmbientSound) {
        let clamped = min(max(vol, 0), 1)
        volumes[sound] = clamped
        if activeSounds.contains(sound) {
            states[sound]?.target = clamped
        }
    }

    func stopAll() {
        for sound in activeSounds {
            states[sound]?.target = 0
        }
        activeSounds.removeAll()
        scheduleStop()
    }

    //Private – Engine lifecycle

    private func ensureRunning() {
        guard !engineRunning else { return }

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: .mixWithOthers)
        try? session.setActive(true)

        let sr = engine.outputNode.outputFormat(forBus: 0).sampleRate
        guard let fmt = AVAudioFormat(standardFormatWithSampleRate: sr, channels: 2) else { return }

        // Pre-create all nodes if not already created
        for sound in AmbientSound.allCases {
            if nodes[sound] == nil {
                let node = makeNode(sound: sound, sr: sr, fmt: fmt)
                nodes[sound] = node
                engine.attach(node)
                engine.connect(node, to: engine.mainMixerNode, format: fmt)
            }
        }

        do {
            try engine.start()
            engineRunning = true
        } catch {
            print("WhiteNoisePlayer: engine failed to start – \(error)")
        }
    }

    private func scheduleStop() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self, self.activeSounds.isEmpty else { return }
            self.engine.stop()
            self.engineRunning = false
        }
    }

    //Private – Node factory

    private func makeNode(sound: AmbientSound, sr: Double, fmt: AVAudioFormat) -> AVAudioSourceNode {
        let st = states[sound]!
        let twoPi = 2.0 * Double.pi

        return AVAudioSourceNode(format: fmt) { [weak st] _, _, frameCount, bufferList -> OSStatus in
            guard let st else { return noErr }

            let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
            guard buffers.count >= 2,
                  let ch0 = buffers[0].mData?.assumingMemoryBound(to: Float.self),
                  let ch1 = buffers[1].mData?.assumingMemoryBound(to: Float.self) else {
                return noErr
            }

            let fadeIn:  Float = Float(1.0 / sr) * 0.4
            let fadeOut: Float = Float(1.0 / sr) * 0.25

            for frame in 0..<Int(frameCount) {

                // Smooth amplitude
                if st.amplitude < st.target {
                    st.amplitude = min(st.amplitude + fadeIn, st.target)
                } else if st.amplitude > st.target {
                    st.amplitude = max(st.amplitude - fadeOut, st.target)
                }

                // Write silence cheaply if inaudible
                if st.amplitude <= 0.0001 {
                    ch0[frame] = 0
                    ch1[frame] = 0
                    continue
                }

                var L: Float = 0
                var R: Float = 0

                switch sound {

                // ── White noise ─────────────────────────────────────────
                case .white:
                    L = Float.random(in: -0.5...0.5)
                    R = Float.random(in: -0.5...0.5)

                // ── Pink noise (Kellett algorithm) ───────────────────────
                case .pink:
                    let w = Float.random(in: -1.0...1.0)
                    st.b0 = 0.99886 * st.b0 + w * 0.0555179
                    st.b1 = 0.99332 * st.b1 + w * 0.0750759
                    st.b2 = 0.96900 * st.b2 + w * 0.1538520
                    st.b3 = 0.86650 * st.b3 + w * 0.3104856
                    st.b4 = 0.55000 * st.b4 + w * 0.5329522
                    st.b5 = -0.7616 * st.b5 - w * 0.0168980
                    let pink = (st.b0 + st.b1 + st.b2 + st.b3 + st.b4 + st.b5 + st.b6 + w * 0.5362) * 0.11
                    st.b6 = w * 0.115926
                    L = pink
                    R = pink

                // ── Brown noise ──────────────────────────────────────────
                case .brown:
                    let w = Float.random(in: -1.0...1.0)
                    st.brown = (st.brown + 0.02 * w) / 1.02
                    let b = st.brown * 3.5
                    L = b
                    R = b

                // ── Rain ─────────────────────────────────────────────────
                case .rain:
                    let w = Float.random(in: -1.0...1.0)
                    st.b0 = 0.97 * st.b0 + w * 0.18
                    st.b1 = 0.85 * st.b1 + w * 0.07
                    st.b2 = 0.55 * st.b2 + w * 0.05
                    let filtered = st.b0 + st.b1 + st.b2

                    st.lfo0 += 2.8 / sr
                    if st.lfo0 > 1.0 { st.lfo0 -= 1.0 }
                    st.lfo1 += 0.14 / sr
                    if st.lfo1 > 1.0 { st.lfo1 -= 1.0 }

                    let wave = Float(0.6 + 0.4 * abs(sin(st.lfo0 * twoPi)))
                    let spread = Float(sin(st.lfo1 * twoPi)) * 0.3

                    L = filtered * wave * (1.0 + spread)
                    R = filtered * wave * (1.0 - spread)

                // ── Ocean ────────────────────────────────────────────────
                case .ocean:
                    let w = Float.random(in: -1.0...1.0)
                    st.brown = (st.brown + 0.015 * w) / 1.015

                    st.lfo0 += 0.09 / sr
                    if st.lfo0 > 1.0 { st.lfo0 -= 1.0 }
                    st.lfo1 += 0.11 / sr
                    if st.lfo1 > 1.0 { st.lfo1 -= 1.0 }

                    let wave  = Float(0.5 + 0.5 * sin(st.lfo0 * twoPi))
                    let wide  = Float(sin(st.lfo1 * twoPi)) * 0.45

                    let base = st.brown * 4.0 * wave
                    L = base * (1.0 + wide)
                    R = base * (1.0 - wide)

                // ── Fire ─────────────────────────────────────────────────
                case .fire:
                    let w = Float.random(in: -1.0...1.0)
                    st.b0 = 0.96 * st.b0 + w * 0.22
                    st.b1 = 0.70 * st.b1 + w * 0.09
                    let filtered = st.b0 + st.b1

                    st.lfo0 += 2.3 / sr
                    if st.lfo0 > 1.0 { st.lfo0 -= 1.0 }

                    let crackle = Float(0.75 + 0.25 * abs(sin(st.lfo0 * twoPi)))
                    let jitter  = Float.random(in: -0.15...0.15)

                    L = filtered * crackle * (1.0 + jitter)
                    R = filtered * crackle * (1.0 - jitter)
                }

                ch0[frame] = L * st.amplitude
                ch1[frame] = R * st.amplitude
            }
            return noErr
        }
    }
}
