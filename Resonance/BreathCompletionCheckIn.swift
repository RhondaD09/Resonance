//
//  BreathCompletionCheckIn.swift
//  Resonance
//
//  Created by Rhonda Davis on 4/17/26.
//



import SwiftUI

struct BreathCompletionCheckIn: View {
    var onFeelingGrounded: () -> Void
    var onNeedMorePeace:   () -> Void
    var onNavigateToConnect: (() -> Void)?
    var onNavigateToMusic: (() -> Void)?
    var onReturnHome: (() -> Void)?

    @State private var appeared         = false
    @State private var showPeacePrompts = false
    @State private var showPeaceCompletion = false

    var body: some View {
        ZStack {

            // ── Background: animated mesh gradient ──
            AnimatedMeshGradient()
                .ignoresSafeArea()

            if showPeaceCompletion {
                PeaceCompletionView(onReturnHome: {
                    onReturnHome?()
                })
                .transition(.move(edge: .trailing))
            } else if showPeacePrompts {
                PeacePromptsView(
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showPeaceCompletion = true
                        }
                    },
                    onNavigateToConnect: onNavigateToConnect,
                    onNavigateToMusic: onNavigateToMusic
                )
                .transition(.move(edge: .trailing))
            } else {
                VStack(spacing: 0) {

                    Spacer()

                    // ── Title ───
                    VStack(spacing: 0) {
                        Text("How Are")
                            .font(.custom("Titan One", size: 42))
                            .foregroundStyle(.white)
                        Text("You Feeling")
                            .font(.custom("Titan One", size: 42))
                            .foregroundStyle(.white)
                        Text("Now?")
                            .font(.custom("Titan One", size: 56))
                            .foregroundStyle(.white)
                            .fontWeight(.heavy)
                            .shadow(color: .white.opacity(0.4), radius: 1, x: 0, y: 0)
                    }
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -20)
                    .animation(.easeOut(duration: 0.6).delay(0.1), value: appeared)

                    Spacer()

                    // ── Buttons ───
                    VStack(spacing: 16) {

                        // Feeling Grounded
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showPeaceCompletion = true
                            }
                        } label: {
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

