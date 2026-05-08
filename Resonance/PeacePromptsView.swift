//
//  PeacePromptsView.swift
//  Resonance
//
//  Created by Rhonda Davis on 3/26/26.
//

import SwiftUI
import Speech
import AVFoundation
import Combine

//Speech Recognizer

@MainActor
class SpeechRecognizerManager: ObservableObject {
    @Published var transcribedText: String = ""
    @Published var isListening: Bool = false
    @Published var isAuthorized: Bool = false

    private var recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    init() {
        recognizer = SFSpeechRecognizer(locale: Locale.current)
    }

    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                self?.isAuthorized = (status == .authorized)
            }
        }
    }

    func startListening() {
        guard let recognizer, recognizer.isAvailable, !isListening else { return }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest else { return }
            recognitionRequest.shouldReportPartialResults = true

            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }

            recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                Task { @MainActor in
                    if let result {
                        self?.transcribedText = result.bestTranscription.formattedString
                    }
                    if error != nil || (result?.isFinal ?? false) {
                        self?.stopListening()
                    }
                }
            }

            audioEngine.prepare()
            try audioEngine.start()
            isListening = true
        } catch {
            stopListening()
        }
    }

    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isListening = false
    }
}

// Journal Storage

//struct JournalEntry: Codable, Identifiable {
//    var id = UUID()
//    let text: String
//    let date: Date
//}

//enum JournalStore {
//    private static let key = "peaceReflections"

//    static func save(_ text: String) {
//        var entries = load()
//        entries.insert(JournalEntry(text: text, date: Date()), at: 0)
//        if let data = try? JSONEncoder().encode(entries) {
//            UserDefaults.standard.set(data, forKey: key)
//        }
//    }

//    static func load() -> [JournalEntry] {
//        guard let data = UserDefaults.standard.data(forKey: key),
//              let entries = try? JSONDecoder().decode([JournalEntry].self, from: data) else {
//            return []
//        }
//        return entries
//    }


//Peace Prompts View

struct PeacePromptsView: View {
    var onDismiss: () -> Void
    var onNavigateToConnect: (() -> Void)?
    var onNavigateToMusic: (() -> Void)?

    @State private var appeared = false
    @State private var randomPrompt: String = ""
    @State private var orbFloat = false
//    @State private var reflectionText: String = ""
//    @State private var saved = false
//    @FocusState private var isTextFocused: Bool
//    @StateObject private var speechManager = SpeechRecognizerManager()

//    private var isReflect: Bool { randomPrompt == "Go For A Walk" }

    private let prompts = [
        "GO FOR A WALK",
        "TEXT A FRIEND THAT MAKES YOU SMILE",
        "STRETCH FOR A MINUTE",
        "DANCE BREAK!",
//        "REFLECT",
//        "STAND UP!",
        "CALL A FRIEND YOU'VE MISSED",
        "DO ABSOLUTELY NOTHING FOR 5 MINUTES"
    ]

    private var isFriendPrompt: Bool {
        randomPrompt == "TEXT A FRIEND THAT MAKES YOU SMILE" ||
        randomPrompt == "CALL A FRIEND YOU'VE MISSED"
    }

    private var isDancePrompt: Bool {
        randomPrompt == "DANCE BREAK!"
    }

    // Colors matching the reference design
    private let deepPurple = Color(red: 45/255, green: 20/255, blue: 90/255)
    private let midPurple = Color(red: 80/255, green: 50/255, blue: 160/255)
    private let lightPurple = Color(red: 160/255, green: 130/255, blue: 240/255)
    private let cardBg = Color(red: 55/255, green: 35/255, blue: 110/255)

    var body: some View {
        ZStack {
            // Purple and black gradient background
            LinearGradient(
                colors: [
                    Color(red: 45/255, green: 20/255, blue: 80/255),
                    Color(red: 25/255, green: 10/255, blue: 50/255),
                    Color(red: 15/255, green: 8/255, blue: 35/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Floating purple orb (top-right accent like the reference)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [midPurple.opacity(0.8), deepPurple.opacity(0.0)],
                        center: .center, startRadius: 10, endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .blur(radius: 40)
                .offset(x: 100, y: -280)
                .offset(y: orbFloat ? -10 : 10)
                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: orbFloat)

            // Small solid orb accent
            Image(systemName: "peacesign")
                .resizable(capInsets: EdgeInsets(top: 1, leading: 1, bottom: 1, trailing: 1))
                .foregroundColor(midPurple)
                .frame(width: 100, height: 100)
                .shadow(color: midPurple.opacity(0.2), radius: 2)
                .offset(x: -3, y: -305)
                .opacity(appeared ? 1 : 0)

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 200)
                
                // Title
                VStack(spacing: 4) {
                    Text("Peace")
                        .font(.custom("Titan One", size: 38))
                        .foregroundStyle(.white)
                        .fontWeight(.bold)
                    Text("Prompts")
                        .font(.custom("Titan One", size: 38))
                        .foregroundStyle(.white)
                        .fontWeight(.bold)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : -15)
                
                Spacer()
                    .frame(height: 60)
                
                promptCard
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.9)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if isFriendPrompt {
                            NotificationCenter.default.post(name: .navigateToConnect, object: nil)
                        } else if isDancePrompt {
                            NotificationCenter.default.post(name: .navigateToMusic, object: nil)
                        } else {
                            onDismiss()
                        }
                    }

                Spacer()

                // Tap to dismiss hint
                Text(isFriendPrompt ? "Tap the card to connect with a friend" : isDancePrompt ? "Tap the card to find your beat" : "Tap anywhere to continue")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(lightPurple.opacity(0.4))
                    .padding(.bottom, 50)
                    .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            randomPrompt = prompts.randomElement() ?? prompts[0]
            orbFloat = true
            withAnimation(.easeOut(duration: 0.7)) {
                appeared = true
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onDismiss()
        }
    }

    // Standard Prompt Card

    @ViewBuilder
    var promptCard: some View {
                    VStack(spacing: 16) {
                        Text("Today's prompt")
                            .font(.system(size: 11, weight: .medium))
                            .tracking(1.8)
                            .foregroundStyle(lightPurple.opacity(0.7))
                            .textCase(.uppercase)
                        
                        Text(randomPrompt)
                            .font(.custom("We Love Peace", size: 22))
                            .tracking(0.5)
                            .foregroundStyle(.white.opacity(0.95))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                        
                        Circle()
                            .stroke(lightPurple.opacity(0.3), lineWidth: 2)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .fill(midPurple.opacity(0.5))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName:"heart.fill")
                                            .font(Font.system(size: 25))
                                            .foregroundStyle(lightPurple)
                                    )
                            )
                            .padding(.top, 4)
                    }
                
                    .padding(.vertical, 28)
                    .padding(.horizontal, 32)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(cardBg.opacity(0.6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(lightPurple.opacity(0.15), lineWidth: 1)
                            )
                    )
                
                    .shadow(color: deepPurple.opacity(0.5), radius: 20, y: 10)
                    .padding(.horizontal, 32)
                }
            
    //Reflect Card (Share How You're Doing)

//    private var reflectCard: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            Text("SHARE HOW YOU'RE DOING")
//                .font(.system(size: 10, weight: .medium))
//                .tracking(1.8)
//                .foregroundStyle(lightPurple.opacity(0.7))
//
//            // Text box with mic button
//            ZStack(alignment: .bottomTrailing) {
//                TextEditor(text: $reflectionText)
//                    .font(.system(size: 14))
//                    .foregroundStyle(.white.opacity(0.9))
//                    .scrollContentBackground(.hidden)
//                    .frame(height: 120)
//                    .padding(.horizontal, 14)
//                    .padding(.top, 12)
//                    .padding(.bottom, 40) // room for mic button
//                    .background(
//                        RoundedRectangle(cornerRadius: 12)
//                            .fill(Color.white.opacity(0.06))
//                    )
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 12)
//                            .stroke(
//                                speechManager.isListening
//                                    ? lightPurple.opacity(0.5)
//                                    : lightPurple.opacity(0.15),
//                                lineWidth: speechManager.isListening ? 1.5 : 1
//                            )
//                    )
//                    .overlay(alignment: .topLeading) {
//                        if reflectionText.isEmpty && !speechManager.isListening {
//                            Text("Tap the mic and speak your reflection…")
//                                .font(.system(size: 14))
//                                .foregroundStyle(lightPurple.opacity(0.35))
//                                .padding(.horizontal, 18)
//                                .padding(.vertical, 16)
//                                .allowsHitTesting(false)
//                        }
//                    }
//                    .focused($isTextFocused)
//                    .onChange(of: speechManager.transcribedText) { _, newValue in
//                        reflectionText = newValue
//                    }

                // Microphone button
//                Button {
//                    if speechManager.isListening {
//                        speechManager.stopListening()
//                    } else {
//                        isTextFocused = false
//                        speechManager.transcribedText = reflectionText
//                        speechManager.startListening()
//                    }
//                } label: {
//                    HStack(spacing: 6) {
//                        Image(systemName: speechManager.isListening ? "mic.fill" : "mic")
//                            .font(.system(size: 14))
//                        if speechManager.isListening {
//                            Text("Listening…")
//                                .font(.system(size: 11, weight: .medium))
//                        }
//                    }
//                    .foregroundStyle(speechManager.isListening ? .white : lightPurple.opacity(0.7))
//                    .padding(.horizontal, 12)
//                    .padding(.vertical, 7)
//                    .background(
//                        Capsule()
//                            .fill(speechManager.isListening ? midPurple : Color.white.opacity(0.08))
//                    )
//                }
//                .padding(8)
//            }

            // Save and dismiss buttons
//            HStack {
//                if saved {
//                    Text("Saved ✓")
//                        .font(.system(size: 12, weight: .medium))
//                        .foregroundStyle(Color(red: 134/255, green: 239/255, blue: 172/255))
//                }
//                Spacer()
//                Button {
//                    saveReflection()
//                } label: {
//                    Text("Save ✦")
//                        .font(.system(size: 12, weight: .medium))
//                        .padding(.horizontal, 20)
//                        .padding(.vertical, 8)
//                        .foregroundStyle(.white)
//                        .background(midPurple)
//                        .clipShape(Capsule())
//                }
//            }
//        }
//        .padding(20)
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .background(
//            RoundedRectangle(cornerRadius: 22)
//                .fill(cardBg.opacity(0.6))
//                .overlay(
//                    RoundedRectangle(cornerRadius: 22)
//                        .stroke(lightPurple.opacity(0.15), lineWidth: 1)
//                )
//        )
//        .shadow(color: deepPurple.opacity(0.5), radius: 20, y: 10)
//        .padding(.horizontal, 24)
//        .onAppear {
//            speechManager.requestAuthorization()
//        }
//        .onDisappear {
//            if speechManager.isListening {
//                speechManager.stopListening()
//            }
//        }
//    }

//    private func saveReflection() {
//        let text = reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
//        guard !text.isEmpty else { return }
//
//        if speechManager.isListening {
//            speechManager.stopListening()
//        }
//        isTextFocused = false

//        JournalStore.save(text)
//        withAnimation { saved = true }

//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
//            onDismiss()
//        }
//    }
}

#Preview {
    PeacePromptsView(onDismiss: {})
}

