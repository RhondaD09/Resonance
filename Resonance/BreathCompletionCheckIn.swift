//
//  BreathCompletionCheckIn.swift
//  Resonance
//
//  Created by Rhonda Davis on 4/17/26.
//

//
//  BreathCompletionCheckIn.swift
//  Resonance
//
//  Post-breathing check-in screen — dark purple gradient,
//  bold white title, purple pill buttons.
//

import SwiftUI

struct BreathCompletionCheckIn: View {
    var onFeelingGrounded: () -> Void
    var onNeedMorePeace:   () -> Void
    var onNavigateToConnect: (() -> Void)?
    var onNavigateToMusic: (() -> Void)?

    @State private var appeared         = false
    @State private var showPeacePrompts = false

    var body: some View {
        ZStack {

            // ── Background: animated mesh gradient ──────────────────────
            AnimatedMeshGradient()
                .ignoresSafeArea()

            if showPeacePrompts {
                PeacePromptsView(onDismiss: onFeelingGrounded, onNavigateToConnect: onNavigateToConnect, onNavigateToMusic: onNavigateToMusic)
                    .transition(.move(edge: .trailing))
            } else {
                VStack(spacing: 0) {

                    Spacer()

                    // ── Title ─────────────────────────────────────────
                    VStack(spacing: 0) {
                        Text("How Are")
                            .font(.custom("Titan One", size: 42))
                            .foregroundStyle(.white)
                        Text("You Feeling")
                            .font(.custom("Titan One", size: 42))
                            .foregroundStyle(.white)
                        Text("Now?")
                            .font(.custom("We Love Peace", size: 48))
                            .foregroundStyle(.white)
                    }
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -20)
                    .animation(.easeOut(duration: 0.6).delay(0.1), value: appeared)

                    Spacer()

                    // ── Buttons ───────────────────────────────────────
                    VStack(spacing: 16) {

                        // Feeling Grounded
                        Button(action: onFeelingGrounded) {
                            Text("Feeling Grounded")
                                .font(.body.bold())
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glass)

                        // Need More Peace
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showPeacePrompts = true
                            }
                        } label: {
                            Text("Need More Peace")
                                .font(.body.bold())
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glass)
                    }
                    .padding(.horizontal, 36)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)
                    .animation(.easeOut(duration: 0.6).delay(0.3), value: appeared)

                    Spacer().frame(height: 80)
                }
                .transition(.move(edge: .leading))
            }
        }
        .onAppear {
            appeared = true
        }
    }
}

#Preview {
    BreathCompletionCheckIn(
        onFeelingGrounded: {},
        onNeedMorePeace:   {}
    )
}

