//
//  WellnessView.swift
//  Resonance
//
//  Created by Rhonda Davis on 3/26/26.
//

import SwiftUI

struct WellnessView: View {
    @Bindable var state: AppState
    var onChangeMood: (() -> Void)? = nil
    var onReturnHome: (() -> Void)? = nil

    @State private var completionCount                = 0
    @State private var showCompletionPopup            = false
    @State private var navigateToMusicViewOnDismiss   = false
    @State private var navigateToConnectViewOnDismiss = false
    @State private var navigateToMoodOnDismiss        = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            if let onChangeMood {
                Button(action: onChangeMood) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .medium))
                        Text("Change Mood")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(Color.rAccent)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 12)
            }

//            SectionHeader(
//                title: "Breathe Your",
//                highlight: "Peace",
//                subtitle: "Body, breath, and balance"
//            )
//            .padding(.horizontal, 18)

            NeonMandalaView(onComplete: {
                completionCount += 1
                state.markDone(.breath)
                withAnimation(.easeInOut(duration: 0.4)) {
                    showCompletionPopup = true
                }
            })
        }
        .sensoryFeedback(.success, trigger: completionCount)
        .fullScreenCover(isPresented: $showCompletionPopup, onDismiss: {
            if navigateToMoodOnDismiss {
                navigateToMoodOnDismiss = false
                onChangeMood?()
            } else if navigateToConnectViewOnDismiss {
                navigateToConnectViewOnDismiss = false
                state.selectedTab = .connect
            } else if navigateToMusicViewOnDismiss {
                navigateToMusicViewOnDismiss = false
                state.selectedTab = .music
            }
        }) {
            BreathCompletionCheckIn(
                onFeelingGrounded: {
                    navigateToMusicViewOnDismiss = true
                    dismissCompletion()
                },
                onNeedMorePeace: {
                    showCompletionPopup = false
                },
                onNavigateToConnect: {
                    navigateToConnectViewOnDismiss = true
                    dismissCompletion()
                },
                onNavigateToMusic: {
                    navigateToMusicViewOnDismiss = true
                    dismissCompletion()
                },
                onReturnHome: {
                    dismissCompletion()
                    onReturnHome?()
                },
                onStartOver: {
                    showCompletionPopup = false
                }
            )
        }
    }

    private func dismissCompletion() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showCompletionPopup = false
        }
    }
}

#Preview {
    WellnessView(state: AppState())
        .background(Color.rBg)
        .preferredColorScheme(.dark)
}
