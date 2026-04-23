//
//  MusicView.swift
//  Resonance
//
//  Created by Rhonda Davis on 3/26/26.
//

import SwiftUI
import AVFoundation
import MusicKit

// Tap Audio Engine

final class TapAudioEngine {
    private var engine: AVAudioEngine?
    private let rs = RS()

    final class RS: @unchecked Sendable {
        var bellTrigger: Bool = false
        var bellEnvelope: Float = 0
        var bellPhase: Double = 0
        var padPhase0: Double = 0
        var padPhase1: Double = 0
        var padPhase2: Double = 0
        var padLfo0: Double = 0
        var padLfo1: Double = 0
        var padAmplitude: Float = 0
        var padTarget: Float = 0.0
        var padFreq: Double = 110
        var padFreqTarget: Double = 110
    }

    func start() {
        stopImmediately()

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)

        let newEngine = AVAudioEngine()
        let sampleRate = newEngine.outputNode.outputFormat(forBus: 0).sampleRate
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2) else { return }

        let st = rs
        let twoPi = 2.0 * Double.pi
        let sr = sampleRate

        let sourceNode = AVAudioSourceNode(format: format) { _, _, frameCount, bufferList -> OSStatus in
            let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
            let fadeIn: Float = 1.0 / Float(sr) * 0.5
            let fadeOut: Float = 1.0 / Float(sr) * 2.0

            for frame in 0..<Int(frameCount) {
                if st.bellTrigger {
                    st.bellTrigger = false
                    st.bellEnvelope = 0.45
                    st.bellPhase = 0
                }
                st.bellEnvelope *= 0.99988

                var bell: Float = 0
                if st.bellEnvelope > 0.001 {
                    let f1 = Float(sin(st.bellPhase * twoPi)) * 0.5
                    let f2 = Float(sin(st.bellPhase * 2.0 * twoPi)) * 0.25
                    let f3 = Float(sin(st.bellPhase * 2.378 * twoPi)) * 0.12
                    let f4 = Float(sin(st.bellPhase * 3.0 * twoPi)) * 0.08
                    bell = (f1 + f2 + f3 + f4) * st.bellEnvelope
                    st.bellPhase += 392.0 / sr
                }

                if st.padAmplitude < st.padTarget {
                    st.padAmplitude = min(st.padAmplitude + fadeIn, st.padTarget)
                } else if st.padAmplitude > st.padTarget {
                    st.padAmplitude = max(st.padAmplitude - fadeOut, st.padTarget)
                }

                let freqStep = 0.05 / sr
                if st.padFreq < st.padFreqTarget {
                    st.padFreq = min(st.padFreq + freqStep * 20, st.padFreqTarget)
                } else if st.padFreq > st.padFreqTarget {
                    st.padFreq = max(st.padFreq - freqStep * 20, st.padFreqTarget)
                }

                var padL: Float = 0
                var padR: Float = 0
                if st.padAmplitude > 0.001 {
                    let breathe = Float(sin(st.padLfo0 * twoPi)) * 0.25 + 0.75
                    let drift = Float(sin(st.padLfo1 * twoPi)) * 0.1
                    let v0 = Float(sin(st.padPhase0 * twoPi)) * 0.35
                    let v1 = Float(sin(st.padPhase1 * twoPi)) * 0.35
                    let v2 = Float(sin(st.padPhase2 * twoPi)) * 0.20

                    padL = (v0 + v2) * st.padAmplitude * breathe * 0.30
                    padR = (v1 + v2) * st.padAmplitude * breathe * 0.30
                    padL += drift * st.padAmplitude * 0.05
                    padR -= drift * st.padAmplitude * 0.05

                    st.padPhase0 += st.padFreq / sr
                    st.padPhase1 += (st.padFreq + 0.3) / sr
                    st.padPhase2 += (st.padFreq * 1.498) / sr
                    st.padLfo0 += 0.045 / sr
                    st.padLfo1 += 0.07 / sr
                }

                let sL = bell + padL
                let sR = bell + padR

                if st.bellPhase > 100_000 { st.bellPhase -= 100_000 }
                if st.padPhase0 > 100_000 { st.padPhase0 -= 100_000 }
                if st.padPhase1 > 100_000 { st.padPhase1 -= 100_000 }
                if st.padPhase2 > 100_000 { st.padPhase2 -= 100_000 }
                if st.padLfo0 > 100_000 { st.padLfo0 -= 100_000 }
                if st.padLfo1 > 100_000 { st.padLfo1 -= 100_000 }

                for ch in 0..<min(buffers.count, 2) {
                    let data = buffers[ch].mData!.assumingMemoryBound(to: Float.self)
                    data[frame] = ch == 0 ? sL : sR
                }
            }
            return noErr
        }

        newEngine.attach(sourceNode)
        newEngine.connect(sourceNode, to: newEngine.mainMixerNode, format: format)

        do {
            try newEngine.start()
        } catch {
            print("TapAudioEngine: failed to start – \(error)")
        }

        self.engine = newEngine
    }

    func tap(bpm: Int?) {
        if engine == nil { start() }
        rs.bellTrigger = true
        if rs.padTarget < 0.15 { rs.padTarget = 0.15 }

        guard let bpm else { return }
        if bpm > 120 {
            rs.padFreqTarget = 72
        } else if bpm > 80 {
            rs.padFreqTarget = 110
        } else {
            rs.padFreqTarget = 55
        }
    }

    func stop() {
        rs.padTarget = 0
        rs.bellEnvelope = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.stopImmediately()
        }
    }

    private func stopImmediately() {
        engine?.stop()
        engine = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

//Music View

struct MusicView: View {
    @Bindable var state: AppState

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(
                    title: "Your",
                    highlight: "music",
                    subtitle: "Interactive sound that meets you where you are"
                )
                MoodMappingCard(state: state)
                AppleMusicCard(state: state)
//                TapToRegulateCard()
                AmbientMixerCard()
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 45/255, green: 20/255, blue: 80/255),
                    Color(red: 25/255, green: 10/255, blue: 50/255),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

//Mood Mapping

struct MoodMappingCard: View {
    @Bindable var state: AppState
    @State private var heavyLight: Double = 50
    @State private var loudQuiet: Double = 50
    @State private var fastSlow: Double = 50
    @State private var selectedColor: Int? = nil
    @State private var selectedWords: Set<String> = []
    @State private var moodResult: MoodMatch? = nil
    @State private var moodFindCount = 0
    @State private var wordToggleCount = 0
    @State private var sliderDragCount = 0

    private let moodColors: [(color: Color, label: String, tone: String)] = [
        (.red,    "Stressed",  "tender"),
        (.orange, "Warm",      "hopeful"),
        (.yellow, "Happy",     "clear"),
        (.green,  "Balanced",  "grounded"),
        (.blue,   "Calm",      "peaceful"),
        (.purple, "Dreamy",    "introspective"),
    ]

    private let moodWords: [(word: String, weight: Double)] = [
        ("anxious", -1),   ("peaceful", -1),  ("drained", -2),
        ("restless", 0),   ("hopeful", 0),     ("tender", -1),
        ("mellow", -2),    ("upbeat", 1),      ("acoustic", -1),
        ("ambient", -2),   ("soulful", -1),    ("energizing", 1),
    ]

    // All possible mood results, matched by energy range and optional tone
    private static let moodResults: [(minEnergy: Double, maxEnergy: Double, tones: Set<String>?, match: MoodMatch)] = [
        (0, 20, nil,
         MoodMatch(name: "Deep Rest", description: "Slow ambient · 432Hz · deep stillness",
                   color: .rAccent, searchTerms: ["ambient sleep", "432Hz healing", "deep calm music"])),
        (20, 40, ["introspective", "tender"],
         MoodMatch(name: "Still Waters", description: "Soft piano · gentle rain · reflective",
                   color: .rAccent, searchTerms: ["soft piano", "rainy day music", "reflective ambient"])),
        (20, 40, nil,
         MoodMatch(name: "Quiet Earth", description: "Nature sounds · acoustic · grounded",
                   color: .rGreen, searchTerms: ["nature sounds relaxing", "acoustic calm", "lo-fi chill"])),
        (40, 60, ["tender", "introspective"],
         MoodMatch(name: "Gentle Drift", description: "Mellow soul · easy rhythm · 70 BPM",
                   color: .rRose, searchTerms: ["mellow soul", "easy listening R&B", "chill vibes"])),
        (40, 60, nil,
         MoodMatch(name: "Steady Ground", description: "Lo-fi beats · warm jazz · centered",
                   color: .rTeal, searchTerms: ["lo-fi jazz", "warm instrumental", "chill beats"])),
        (60, 80, ["hopeful", "clear"],
         MoodMatch(name: "Rising Light", description: "Uplifting strings · binaural · focus",
                   color: .rGold, searchTerms: ["uplifting instrumental", "focus music", "positive acoustic"])),
        (60, 80, nil,
         MoodMatch(name: "Open Sky", description: "Airy synths · gentle energy · momentum",
                   color: .rSky, searchTerms: ["chill electronic", "dreamy synth", "feel good indie"])),
        (80, 101, nil,
         MoodMatch(name: "Bright Momentum", description: "Energizing beats · feel-good · movement",
                   color: .rGold, searchTerms: ["feel good playlist", "upbeat acoustic", "energizing music"])),
    ]

    var body: some View {
        VStack(spacing: 0) {
            CardView {
                CardLabel(text: "Mood Mapping")
                    .padding(.bottom, 14)

                moodSlider(leftLabel: "Heavy", rightLabel: "Light", value: $heavyLight, color: .rAccent)
                moodSlider(leftLabel: "Loud", rightLabel: "Quiet", value: $loudQuiet, color: .rTeal)
                moodSlider(leftLabel: "Fast", rightLabel: "Slow", value: $fastSlow, color: .rGold)

                colorSwatches
                wordTags
                findButton
            }

            if let result = moodResult {
                moodResultCard(result)
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: moodFindCount)
        .sensoryFeedback(.selection, trigger: selectedColor)
        .sensoryFeedback(.selection, trigger: wordToggleCount)
        .sensoryFeedback(.selection, trigger: sliderDragCount)
    }

    //Subviews

    private var colorSwatches: some View {
        HStack(spacing: 0) {
            ForEach(moodColors.indices, id: \.self) { index in
                let isSelected = selectedColor == index
                VStack(spacing: 6) {
                    Circle()
                        .fill(moodColors[index].color)
                        .frame(width: 36, height: 36)
                        .overlay(Circle().stroke(.white, lineWidth: isSelected ? 2 : 0))
                        .scaleEffect(isSelected ? 1.15 : 1.0)
                        .shadow(color: isSelected ? moodColors[index].color.opacity(0.4) : .clear, radius: 10)
                    Text(moodColors[index].label)
                        .font(.system(size: 9))
                        .foregroundStyle(isSelected ? Color.rText : Color.rMuted)
                }
                .frame(maxWidth: .infinity)
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        selectedColor = isSelected ? nil : index
                    }
                }
            }
        }
        .padding(.bottom, 10)
    }

    private var wordTags: some View {
        FlowLayout(spacing: 7) {
            ForEach(moodWords, id: \.word) { item in
                MoodWordTag(word: item.word, isSelected: selectedWords.contains(item.word)) {
                    if selectedWords.contains(item.word) {
                        selectedWords.remove(item.word)
                    } else {
                        selectedWords.insert(item.word)
                    }
                    wordToggleCount += 1
                }
            }
        }
        .padding(.bottom, 8)
    }

    private var findButton: some View {
        Button { findMood() } label: {
            Text("Find my music")
                .font(.system(size: 14, weight: .medium))
                .tracking(0.5)
                .foregroundStyle(.white)
                .bold()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(AnimatedMeshGradient())
                .clipShape(Capsule())
        }
        .padding(.top, 8)
    }

    private func moodResultCard(_ result: MoodMatch) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("YOUR MATCH")
                .font(.system(size: 10))
                .tracking(1.8)
                .foregroundStyle(Color.rMuted)
            Text(result.name)
                .font(.custom("Georgia", size: 22))
                .foregroundStyle(result.color)
            Text(result.description)
                .font(.system(size: 12))
                .foregroundStyle(Color.rMuted)
                .padding(.bottom, 4)

            Text("SEARCH SUGGESTIONS")
                .font(.system(size: 9))
                .tracking(1.5)
                .foregroundStyle(Color.rMuted)

            FlowLayout(spacing: 6) {
                ForEach(result.searchTerms, id: \.self) { term in
                    Button {
                        state.musicSearchQuery = term
                    } label: {
                        Text(term)
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .foregroundStyle(result.color)
                            .background(result.color.opacity(0.1))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(result.color.opacity(0.25), lineWidth: 1))
                    }
                    .sensoryFeedback(.selection, trigger: state.musicSearchQuery)
                }
            }

            Button { } label: {
                Text("Save")
                    .font(.system(size: 12))
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(.white)
                    .background(AnimatedMeshGradient())
                    .clipShape(Capsule())
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color.rSurface2)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(result.color.opacity(0.2), lineWidth: 1))
        .padding(.top, 14)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // Slider Helpers

    private func moodSlider(leftLabel: String, rightLabel: String, value: Binding<Double>, color: Color) -> some View {
        VStack(spacing: 7) {
            HStack {
                Text(leftLabel).font(.system(size: 11)).foregroundStyle(Color.rMuted)
                Spacer()
                Text(rightLabel).font(.system(size: 11)).foregroundStyle(Color.rMuted)
            }
            Slider(value: value, in: 0...100)
                .tint(color)
                .onChange(of: value.wrappedValue) {
                    let snapped = (value.wrappedValue / 10).rounded() * 10
                    if abs(value.wrappedValue - snapped) < 1.5 {
                        sliderDragCount += 1
                    }
                }
        }
        .padding(.bottom, 12)
    }

    private func findMood() {
        let sliderAvg = (heavyLight + loudQuiet + fastSlow) / 3.0
        let wordShift = moodWords
            .filter { selectedWords.contains($0.word) }
            .reduce(0.0) { $0 + $1.weight * 5.0 }
        let energy = min(max(sliderAvg + min(max(wordShift, -20), 20), 0), 100)

        let tone: String
        if let colorIndex = selectedColor {
            tone = moodColors[colorIndex].tone
        } else if energy < 40 {
            tone = "peaceful"
        } else if energy < 70 {
            tone = "hopeful"
        } else {
            tone = "clear"
        }

// Find the first matching result by energy range and tone
        let match = Self.moodResults.first { entry in
            energy >= entry.minEnergy && energy < entry.maxEnergy &&
            (entry.tones == nil || entry.tones!.contains(tone))
        }

        withAnimation(.easeOut(duration: 0.4)) {
            moodResult = match?.match
        }
        moodFindCount += 1
    }
}

// Mood Word Tag

struct MoodWordTag: View {
    let word: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(word)
                .font(.system(size: 12))
                .padding(.horizontal, 13)
                .padding(.vertical, 6)
                .foregroundStyle(isSelected ? Color(red: 10/255, green: 10/255, blue: 15/255) : Color.rMuted)
                .background(isSelected ? Color.rAccent : Color.clear)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isSelected ? Color.rAccent : Color.rBorder, lineWidth: 1))
        }
    }
}

// Mood Match

struct MoodMatch {
    let name: String
    let description: String
    let color: Color
    let searchTerms: [String]
}

//Apple Music

struct AppleMusicCard: View {
    @Bindable var state: AppState
    @State private var vm = MusicSearchViewModel()
    @State private var searchTapCount = 0
    @State private var playTapCount = 0
    @State private var stopTapCount = 0

    var body: some View {
        VStack(spacing: 0) {
            CardView {
                CardLabel(text: "Apple Music").padding(.bottom, 6)
                Text("Search and play from Apple Music")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.rMuted)
                    .padding(.bottom, 14)

                if vm.authDenied {
                    authDeniedView
                } else {
                    searchField
                    statusLabel
                    nowPlayingBar
                }
            }

            songList
        }
        .sensoryFeedback(.selection, trigger: searchTapCount)
        .sensoryFeedback(.selection, trigger: playTapCount)
        .sensoryFeedback(.impact(weight: .light), trigger: stopTapCount)
        .task { await vm.ensureAuthorized() }
        .onChange(of: state.musicSearchQuery) { _, newQuery in
            guard !newQuery.isEmpty else { return }
            vm.query = newQuery
            Task {
                await vm.searchSongs()
                state.musicSearchQuery = ""
            }
        }
    }

    // Apple Music Subviews

    private var authDeniedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.system(size: 32))
                .foregroundStyle(Color.rAccent.opacity(0.5))
                .padding(.bottom, 4)
            Text("Apple Music access is needed to search and play songs.")
                .font(.system(size: 13))
                .foregroundStyle(Color.rMuted2)
                .multilineTextAlignment(.center)
            Text("To enable, go to Settings > A Piece of Peace > Media & Apple Music and turn on access.")
                .font(.system(size: 12))
                .foregroundStyle(Color.rMuted)
                .multilineTextAlignment(.center)
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open Settings")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .bold()
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(AnimatedMeshGradient())
                    .clipShape(Capsule())
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.rMuted)
                TextField("Song, artist, or mood…", text: $vm.query)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.rText)
                    .onSubmit { doSearch() }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.rSurface2)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.rBorder2, lineWidth: 1))

            Button {
                searchTapCount += 1
                doSearch()
            } label: {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.rAccent)
            }
        }
    }

    @ViewBuilder
    private var statusLabel: some View {
        let status = vm.statusText
        let count = vm.songs.count
        if !status.isEmpty {
            Text(count > 0 ? "\(status) (\(count) results)" : status)
                .font(.system(size: 12))
                .foregroundStyle(Color.rMuted)
                .padding(.top, 8)
        }
    }

    @ViewBuilder
    private var nowPlayingBar: some View {
        if let song = vm.nowPlaying {
            HStack(spacing: 12) {
                SongArtwork(artwork: song.artwork, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(song.title).font(.system(size: 13, weight: .medium)).foregroundStyle(Color.rText).lineLimit(1)
                    Text(song.artistName).font(.system(size: 11)).foregroundStyle(Color.rMuted).lineLimit(1)
                }
                Spacer()
                Button {
                    stopTapCount += 1
                    Task { await vm.stop() }
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.rRose)
                }
            }
            .padding(12)
            .background(Color.rAccent.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.rAccent.opacity(0.2), lineWidth: 1))
            .padding(.top, 12)
        }
    }

    @ViewBuilder
    private var songList: some View {
        if !vm.songs.isEmpty {
            VStack(spacing: 0) {
                ForEach(vm.songs, id: \.id) { song in
                    Button {
                        playTapCount += 1
                        Task {
                            await vm.play(song)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            SongArtwork(artwork: song.artwork, size: 40, cornerRadius: 6)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(song.title).font(.system(size: 13, weight: .medium)).foregroundStyle(Color.rText).lineLimit(1)
                                Text(song.artistName).font(.system(size: 11)).foregroundStyle(Color.rMuted).lineLimit(1)
                            }
                            Spacer()
                            Image(systemName: vm.nowPlaying?.id == song.id ? "speaker.wave.2.fill" : "play.circle")
                                .font(.system(size: 18))
                                .foregroundStyle(vm.nowPlaying?.id == song.id ? Color.rAccent : Color.rMuted2)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                    }
                    if song.id != vm.songs.last?.id {
                        Divider().background(Color.rBorder).padding(.leading, 64)
                    }
                }
            }
            .background(Color.rSurface2)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.rBorder, lineWidth: 1))
            .padding(.top, 12)
        }
    }

    private func doSearch() {
        Task { await vm.searchSongs() }
    }
}

//Song Artwork

struct SongArtwork: View {
    let artwork: Artwork?
    var size: CGFloat = 44
    var cornerRadius: CGFloat = 8

    var body: some View {
        if let artwork {
            ArtworkImage(artwork, width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.rSurface3)
                .frame(width: size, height: size)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: size > 40 ? 16 : 14))
                        .foregroundStyle(Color.rMuted)
                )
        }
    }
}

////Tap to Regulate
//
//struct TapToRegulateCard: View {
//    @State private var taps: [Date] = []
//    @State private var bpm: Int? = nil
//    @State private var responseText = "Start tapping to hear how the music responds…"
//    @State private var barHeights: [CGFloat] = Array(repeating: 5, count: 18)
//    @State private var tapPtr = 0
//    @State private var tapScale: CGFloat = 1.0
//    @State private var rippleActive = false
//    @State private var audio = TapAudioEngine()
//
//    var body: some View {
//        CardView {
//            CardLabel(text: "Tap to Regulate")
//                .frame(maxWidth: .infinity)
//                .padding(.bottom, 4)
//            Text("Your rhythm shapes the sound")
//                .font(.system(size: 13))
//                .foregroundStyle(Color.rMuted)
//                .frame(maxWidth: .infinity)
//                .padding(.bottom, 16)
//
//            tapCircle
//            rhythmBars
//            bpmDisplay
//            responseBox
//            waveform
//        }
//        .sensoryFeedback(.impact(weight: .light), trigger: tapPtr)
//    }
//
//    // Tap to Regulate Subviews
//
//    private var tapCircle: some View {
//        ZStack {
//            Circle()
//                .stroke(Color.rAccent.opacity(0.2), lineWidth: 1)
//                .frame(width: 200, height: 200)
//
//            if rippleActive {
//                Circle()
//                    .stroke(Color.rAccent.opacity(0.5), lineWidth: 1)
//                    .frame(width: 200, height: 200)
//                    .scaleEffect(1.2)
//                    .opacity(0)
//            }
//
//            Circle()
//                .fill(
//                    RadialGradient(
//                        colors: [Color.rAccent.opacity(0.2), Color.rViolet.opacity(0.07)],
//                        center: UnitPoint(x: 0.4, y: 0.35),
//                        startRadius: 0, endRadius: 70
//                    )
//                )
//                .frame(width: 140, height: 140)
//                .overlay(Circle().stroke(Color.rAccent.opacity(0.25), lineWidth: 1))
//                .overlay(
//                    VStack(spacing: 4) {
//                        Text("♪").font(.system(size: 28)).foregroundStyle(Color.rText)
//                        Text("TAP ME").font(.system(size: 10)).tracking(1).foregroundStyle(Color.rMuted)
//                    }
//                )
//                .scaleEffect(tapScale)
//        }
//        .frame(maxWidth: .infinity)
//        .contentShape(Circle())
//        .onTapGesture { doTap() }
//        .onDisappear { audio.stop() }
//        .padding(.bottom, 20)
//    }
//
//    private var rhythmBars: some View {
//        HStack(alignment: .bottom, spacing: 3) {
//            ForEach(0..<18, id: \.self) { index in
//                RoundedRectangle(cornerRadius: 3)
//                    .fill(Color.rAccent)
//                    .frame(width: 5, height: barHeights[index])
//                    .opacity(barHeights[index] > 5 ? 1 : 0.3)
//            }
//        }
//        .frame(height: 44)
//        .frame(maxWidth: .infinity)
//        .padding(.bottom, 16)
//    }
//
//    private var bpmDisplay: some View {
//        VStack(spacing: 2) {
//            Text(bpm.map(String.init) ?? "—")
//                .font(.custom("Georgia", size: 52))
//                .foregroundStyle(Color.rAccent)
//            Text("TAPS PER MINUTE")
//                .font(.system(size: 10))
//                .tracking(1.5)
//                .foregroundStyle(Color.rMuted)
//        }
//        .frame(maxWidth: .infinity)
//    }
//
//    private var responseBox: some View {
//        VStack(alignment: .leading, spacing: 5) {
//            Text("MUSIC RESPONSE")
//                .font(.system(size: 10))
//                .tracking(1.5)
//                .foregroundStyle(Color.rMuted)
//            Text(responseText)
//                .font(.system(size: 13))
//                .foregroundStyle(bpm != nil ? Color.rText : Color.rMuted)
//                .lineSpacing(2)
//        }
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .padding(14)
//        .background(Color.rSurface2)
//        .clipShape(RoundedRectangle(cornerRadius: 12))
//        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.rBorder, lineWidth: 1))
//        .padding(.top, 14)
//    }
//
//    private var waveform: some View {
//        HStack(spacing: 3) {
//            ForEach(0..<26, id: \.self) { index in
//                WaveBar(delay: Double(index) * 0.065)
//            }
//        }
//        .frame(height: 50)
//        .frame(maxWidth: .infinity)
//        .padding(.top, 14)
//    }
//
//    //Logic
//
//    private func doTap() {
//        taps.append(Date())
//        if taps.count > 8 { taps.removeFirst() }
//
//        audio.tap(bpm: bpm)
//
//        withAnimation(.easeOut(duration: 0.15)) { tapScale = 0.9 }
//        withAnimation(.easeOut(duration: 0.15).delay(0.15)) { tapScale = 1.0 }
//
//        withAnimation(.easeOut(duration: 0.8)) { rippleActive = true }
//        Task { @MainActor in
//            try? await Task.sleep(for: .milliseconds(800))
//            rippleActive = false
//        }
//
//        let idx = tapPtr % barHeights.count
//        withAnimation(.easeOut(duration: 0.2)) {
//            for i in 0..<barHeights.count { barHeights[i] = max(barHeights[i] - 2, 5) }
//            barHeights[idx] = CGFloat.random(in: 18...46)
//        }
//        tapPtr += 1
//
//        calcBPM()
//    }
//
//    private func calcBPM() {
//        guard taps.count >= 2 else { return }
//        let intervals = zip(taps.dropFirst(), taps).map { $0.timeIntervalSince($1) }
//        let avg = intervals.reduce(0, +) / Double(intervals.count)
//        let calculated = Int(60.0 / avg)
//        bpm = calculated
//        audio.tap(bpm: calculated)
//
//        if calculated > 120 {
//            responseText = "Fast rhythm — the music slows its tempo to guide you down gently"
//        } else if calculated > 80 {
//            responseText = "Finding balance — the music matches your pace and softens over time"
//        } else {
//            responseText = "Slow and grounded — deep bass tones and theta waves are layering in"
//        }
//    }
//}
//
//// Wave Bar
//
//struct WaveBar: View {
//    let delay: Double
//    let targetHeight: CGFloat
//    @State private var animating = false
//
//    init(delay: Double) {
//        self.delay = delay
//        self.targetHeight = CGFloat(Int.random(in: 12...50))
//    }
//
//    var body: some View {
//        RoundedRectangle(cornerRadius: 2)
//            .fill(Color.rAccent.opacity(0.5))
//            .frame(width: 3, height: animating ? targetHeight : 12)
//            .animation(
//                .easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(delay),
//                value: animating
//            )
//            .onAppear { animating = true }
//    }
//}
//

//Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 7

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}

//AmbientMixerCard

struct AmbientMixerCard: View {
    private let player = WhiteNoisePlayer.shared

    @State private var stopAllCount = 0
    @State private var startDate = Date.now

    var isActive: Bool { !player.activeSounds.isEmpty }

    var dominantColor: Color {
        player.activeSounds.sorted { $0.rawValue < $1.rawValue }.first?.accent ?? .rAccent
    }

    var activeLabel: String {
        player.activeSounds
            .map { $0.rawValue.capitalized }
            .sorted()
            .joined(separator: " · ")
    }

    var body: some View {
        CardView {
            // Header
            CardLabel(text: "Ambient Mixer")
            Text("Layer sounds for focus, sleep, or calm")
                .font(.system(size: 13))
                .foregroundStyle(Color.rMuted)
                .padding(.top, 4)
                .padding(.bottom, 16)

            // Reactive orb visualizer
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                let t = context.date.timeIntervalSince(startDate)
                let energy = player.energy
                let speed = player.pulseSpeed

                // Breathing cycle driven by sound character
                let breathCycle = sin(t * speed * 0.8) * 0.5 + 0.5
                let outerScale = isActive
                    ? 0.85 + breathCycle * 0.4 * energy
                    : 0.85 + sin(t * 0.5) * 0.05
                let midScale = isActive
                    ? 1.0 - breathCycle * 0.2 * energy
                    : 1.0 + sin(t * 0.6) * 0.03
                let coreGlow = isActive
                    ? 0.6 + breathCycle * 0.4 * energy
                    : 0.3
                let hue = t * (isActive ? 12.0 + speed * 6.0 : 5.0)

                ZStack {
                    // Outer glow — size and opacity react to energy
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    dominantColor.opacity(isActive ? 0.2 + energy * 0.45 : 0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 110
                            )
                        )
                        .frame(width: 220, height: 220)
                        .blur(radius: 35)
                        .scaleEffect(outerScale)

                    // Mid ring — counter-pulses against outer
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    dominantColor.opacity(isActive ? 0.15 + energy * 0.25 : 0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 65
                            )
                        )
                        .frame(width: 130, height: 130)
                        .blur(radius: 18)
                        .scaleEffect(midScale)

                    // Center orb — brightness tracks energy
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(coreGlow),
                                    Color.white.opacity(coreGlow * 0.3)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 30
                            )
                        )
                        .frame(width: 60, height: 60)
                        .blur(radius: 7)

                    // Label
                    if isActive {
                        Text(activeLabel.uppercased())
                            .font(.system(size: 10, weight: .medium))
                            .tracking(1.4)
                            .foregroundStyle(Color.rText)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("TAP A SOUND\nTO BEGIN")
                            .font(.system(size: 10))
                            .tracking(1.4)
                            .foregroundStyle(Color.rMuted)
                            .multilineTextAlignment(.center)
                    }
                }
                .hueRotation(.degrees(hue.truncatingRemainder(dividingBy: 360)))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .padding(.bottom, 16)
            .animation(.easeInOut(duration: 0.6), value: isActive)

            // Sound grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(AmbientSound.allCases) { sound in
                    SoundChip(
                        sound: sound,
                        isActive: player.activeSounds.contains(sound)
                    ) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            player.toggle(sound)
                        }
                    }
                }
            }
            .padding(.bottom, isActive ? 14 : 0)

            // Volume controls (shown when any sound is active)
            if isActive {
                VStack(alignment: .leading, spacing: 10) {
                    CardLabel(text: "Volumes")
                        .padding(.bottom, 2)

                    ForEach(player.activeSounds.sorted { $0.rawValue < $1.rawValue }) { sound in
                        HStack(spacing: 10) {
                            Text(sound.emoji)
                                .font(.system(size: 16))
                                .frame(width: 24)

                            Slider(
                                value: Binding(
                                    get: { Double(player.volumes[sound] ?? 0.65) },
                                    set: { player.setVolume(Float($0), for: sound) }
                                ),
                                in: 0...1
                            )
                            .tint(sound.accent)

                            Text(sound.rawValue.capitalized)
                                .font(.system(size: 10))
                                .foregroundStyle(Color.rMuted2)
                                .frame(width: 36, alignment: .leading)
                        }
                    }

                    Button {
                        withAnimation(.easeOut(duration: 0.3)) {
                            player.stopAll()
                        }
                        stopAllCount += 1
                    } label: {
                        Text("Stop All")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(AnimatedMeshGradient())
                            .clipShape(Capsule())
                    }
                    .padding(.top, 4)
                }
                .padding(14)
                .background(Color.rSurface2)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.rBorder, lineWidth: 1)
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: stopAllCount)
    }
}

// SoundChip

struct SoundChip: View {
    let sound: AmbientSound
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Text(sound.emoji)
                    .font(.system(size: 24))

                Text(sound.rawValue.capitalized)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isActive ? sound.accent : Color.rMuted2)

                Text(sound.subtitle)
                    .font(.system(size: 9))
                    .foregroundStyle(Color.rMuted)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 6)
            .background(isActive ? sound.accent.opacity(0.1) : Color.rSurface2)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isActive ? sound.accent.opacity(0.35) : Color.rBorder, lineWidth: 1)
            )
            .shadow(
                color: isActive ? sound.accent.opacity(0.15) : Color.clear,
                radius: 8
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isActive)
    }
}



#Preview {
    MusicView(state: AppState())
        .background(Color.rBg)
        .preferredColorScheme(.dark)
}
