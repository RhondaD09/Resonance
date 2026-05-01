//
//  ContentView.swift
//  Resonance
//
//  Created by Rhonda Davis on 3/26/26.
//

import SwiftUI

enum AppScreen {
    case landing, moodSelection, main, checkin
}

struct ContentView: View {
    @State private var state = AppState()
    @State private var screen: AppScreen = .landing

    var body: some View {
        switch screen {
        case .landing:
            LandingView {
                withAnimation(.easeInOut(duration: 0.8)) {
                    screen = .moodSelection
                }
            }
            .transition(.opacity)
        case .moodSelection:
            MoodSelectionView { mood in
                state.selectedMood = mood
                withAnimation(.easeInOut(duration: 0.8)) {
                    state.selectedTab = .wellness
                    screen = .main
                }
            }
            .transition(.opacity)
        case .checkin:
            PostBreathingCheckinView { mood in
                state.selectedMood = mood
                state.markDone(.breath)
                withAnimation(.easeInOut(duration: 0.6)) {
                    screen = .moodSelection
                }
            }
            .transition(.opacity)
        case .main:
            mainApp
                .transition(.opacity)
        }
    }

    private var mainApp: some View {
        screenContent
            .sensoryFeedback(.selection, trigger: state.selectedTab)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if state.selectedTab != .wellness {
                    bottomNavBar
                }
            }
// /           .background {
//                AnimatedSpiralBackground()
//            }
            .preferredColorScheme(.dark)
            .transition(.opacity)
    }

    @ViewBuilder
    private var screenContent: some View {
        switch state.selectedTab {
        case .wellness:
            WellnessView(state: state, onChangeMood: {
                withAnimation(.easeInOut(duration: 0.6)) {
                    screen = .checkin
                }
            }, onReturnHome: {
                withAnimation(.easeInOut(duration: 0.8)) {
                    screen = .landing
                }
            })
        case .music:
            MusicView(state: state)
        case .connect:
            ConnectView(state: state)
        }
    }

    // Ambient Orbs

    private var ambientOrbs: some View {
        ZStack {
            Circle()
                .fill(Color.rViolet)
                .frame(width: 500, height: 500)
                .blur(radius: 130)
                .opacity(0.35)
                .offset(x: -100, y: -300)

            Circle()
                .fill(Color.rTealDark)
                .frame(width: 400, height: 400)
                .blur(radius: 130)
                .opacity(0.30)
                .offset(x: 100, y: 300)

            Circle()
                .fill(Color(red: 180/255, green: 83/255, blue: 9/255))
                .frame(width: 300, height: 300)
                .blur(radius: 130)
                .opacity(0.22)
                .offset(x: -40, y: 0)
        }
        .ignoresSafeArea()
    }

    //Bottom Navigation

    private var bottomNavBar: some View {
        HStack(spacing: 0) {
            // Home button navigates back to MoodSelectionView
            Button {
                withAnimation(.easeInOut(duration: 0.8)) {
                    screen = .moodSelection
                }
            } label: {
                VStack(spacing: 3) {
                    Image(systemName: "house")
                        .font(.system(size: 18))
                    Text("Home")
                        .font(.system(size: 10))
                        .tracking(0.4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .foregroundStyle(Color.rMuted)
            }
            .accessibilityLabel("Home")
            navButton(tab: .wellness, systemImage: "leaf", label: "Wellness")
            navButton(tab: .music, systemImage: "music.note.list", label: "Music")

            // Connect with notification dot
            Button {
                state.selectedTab = .connect
            } label: {
                VStack(spacing: 3) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "person.2")
                            .font(.system(size: 18))
                        if !state.doneTasks.contains(.connect) {
                            Circle()
                                .fill(Color.rRose)
                                .frame(width: 6, height: 6)
                                .offset(x: 4, y: -2)
                        }
                    }
                    Text("Connect")
                        .font(.system(size: 10))
                        .tracking(0.4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .foregroundStyle(state.selectedTab == .connect ? Color.rAccent : Color.rMuted)
            }
            .accessibilityLabel("Connect")
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(
            Color.rBg.opacity(0.85)
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.rBorder)
                .frame(height: 1)
        }
    }

    private func navButton(tab: Tab, systemImage: String, label: String) -> some View {
        Button {
            state.selectedTab = tab
        } label: {
            VStack(spacing: 3) {
                Image(systemName: systemImage)
                    .font(.system(size: 18))
                Text(label)
                    .font(.system(size: 10))
                    .tracking(0.4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .foregroundStyle(state.selectedTab == tab ? Color.rAccent : Color.rMuted)
        }
        .accessibilityLabel(label)
    }
}

// Zen Orb Page

//struct ZenOrbView: View {
//    var onContinue: () -> Void
//
//    @State private var orbScale: CGFloat = 0.6
//    @State private var orbOpacity: Double = 0
//    @State private var breathing: Bool = false
//    @State private var hueRotation: Double = 0
//    @State private var textOpacity: Double = 0
//
//    var body: some View {
//        ZStack {
//            // Background
//            Color.rBg.ignoresSafeArea()
//
//            // Orb layers
//            ZStack {
//                // Outermost aura
//                Circle()
//                    .fill(
//                        RadialGradient(
//                            colors: [
//                                Color.rViolet.opacity(0.5),
//                                Color.rTealDark.opacity(0.3),
//                                Color.clear
//                            ],
//                            center: .center,
//                            startRadius: 20,
//                            endRadius: 220
//                        )
//                    )
//                    .frame(width: 440, height: 440)
//                    .blur(radius: 40)
//                    .scaleEffect(breathing ? 1.25 : 0.75)
//
//                // Mid glow ring
//                Circle()
//                    .fill(
//                        RadialGradient(
//                            colors: [
//                                Color.rAccent.opacity(0.4),
//                                Color.rTeal.opacity(0.3),
//                                Color.clear
//                            ],
//                            center: .center,
//                            startRadius: 10,
//                            endRadius: 160
//                        )
//                    )
//                    .frame(width: 320, height: 320)
//                    .blur(radius: 25)
//                    .scaleEffect(breathing ? 1.18 : 0.82)
//
//                // Inner warm core
//                Circle()
//                    .fill(
//                        RadialGradient(
//                            colors: [
//                                Color.rGold.opacity(0.5),
//                                Color.rRose.opacity(0.3),
//                                Color.rViolet.opacity(0.2),
//                                Color.clear
//                            ],
//                            center: .center,
//                            startRadius: 5,
//                            endRadius: 100
//                        )
//                    )
//                    .frame(width: 200, height: 200)
//                    .blur(radius: 15)
//                    .scaleEffect(breathing ? 0.85 : 1.15)
//
//                // Bright center
//                Circle()
//                    .fill(
//                        RadialGradient(
//                            colors: [
//                                Color.white.opacity(0.6),
//                                Color.rAccent.opacity(0.4),
//                                Color.clear
//                            ],
//                            center: .center,
//                            startRadius: 0,
//                            endRadius: 50
//                        )
//                    )
//                    .frame(width: 100, height: 100)
//                    .blur(radius: 8)
//            }
//            .hueRotation(.degrees(hueRotation))
//            .scaleEffect(orbScale)
//            .opacity(orbOpacity)
//
//            // Bottom text + tap prompt
//            VStack {
//                Spacer()
//
//                Text("Tap to begin your journey")
//                    .font(.system(size: 14))
//                    .tracking(1)
//                    .foregroundStyle(Color.rMuted)
//                    .opacity(textOpacity)
//                    .padding(.bottom, 80)
//            }
//        }
//        .preferredColorScheme(.dark)
//        .onTapGesture {
//            onContinue()
//        }
//        .onAppear {
//            // Orb entrance
//            withAnimation(.easeOut(duration: 1.5)) {
//                orbScale = 1.0
//                orbOpacity = 1.0
//            }
//
//            // Start breathing pulse
//            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true).delay(1.0)) {
//                breathing = true
//            }
//
//            // Slow hue drift
//            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
//                hueRotation = 360
//            }
//
//            // Show tap prompt
//            withAnimation(.easeOut(duration: 0.8).delay(2.0)) {
//                textOpacity = 1.0
//            }
//        }
//    }
//}

// Landing Page

struct LandingView: View {
    var onFinished: () -> Void

    @State private var logoOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var floating: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Arched title over logo
            ZStack {
                // Arched text
                ArcTextView(
                    text: "A Piece of Peace",
                    radius: 140,
                    font: .custom("Georgia", size: 40),
                    color: Color.rAccent
                )
                .opacity(titleOpacity)

                // Glow behind logo
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 260, height: 260)
                    .blur(radius: 60)
                    .opacity(logoOpacity)
                    .offset(y: 20)

                // Logo
                Image("Image")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 36))
                    .shadow(color: Color.white.opacity(0.3), radius: 40, y: 10)
                    .opacity(logoOpacity)
                    .offset(y: 20)
            }
            .frame(height: 280)
            .offset(y: floating ? -8 : 8)
            .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: floating)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            LinearGradient(
                colors: [
                    Color(red: 45/255, green: 20/255, blue: 80/255),
                    Color(red: 25/255, green: 10/255, blue: 50/255),
//                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Fade in logo
            withAnimation(.easeOut(duration: 1.0)) {
                logoOpacity = 1
            }
            // Start floating
            floating = true
            // Fade in title
            withAnimation(.easeOut(duration: 1.0).delay(0.4)) {
                titleOpacity = 1
            }
            // Auto-advance after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                onFinished()
            }
        }
    }
}

// Arc Text

struct ArcTextView: View {
    let text: String
    let radius: CGFloat
    let font: Font
    let color: Color

    var body: some View {
        let characters = Array(text)
        // Approximate character angular width (degrees)
        let charSpacing: Double = 7.5
        let totalAngle = Double(characters.count - 1) * charSpacing
        let startAngle = -90.0 - totalAngle / 2.0

        ZStack {
            ForEach(characters.indices, id: \.self) { index in
                let angle = startAngle + Double(index) * charSpacing
                let radians = angle * .pi / 180

                Text(String(characters[index]))
                    .font(font)
                    .foregroundStyle(color)
                    .rotationEffect(.degrees(angle + 90))
                    .offset(
                        x: radius * cos(radians),
                        y: radius * sin(radians)
                    )
            }
        }
    }
}

//#Preview("Zen Orb") {
//    ZenOrbView { }
//}

#Preview {
    ContentView()
}
