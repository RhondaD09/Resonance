//
//  PeacePromptsCheckInView.swift
//  Resonance
//
//  Created by Rhonda Davis on 5/7/26.
//

import SwiftUI

struct PeacePromptsCheckInView: View {
    var onFeelingAtPeace: () -> Void
    var onNeedMorePeace: () -> Void

    @State private var appeared = false
    @State private var orbFloat = false

    private let deepPurple = Color(red: 45/255, green: 20/255, blue: 90/255)
    private let midPurple = Color(red: 80/255, green: 50/255, blue: 160/255)
    private let lightPurple = Color(red: 160/255, green: 130/255, blue: 240/255)

    var body: some View {
        ZStack {
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

            Image(systemName: "peacesign")
                .resizable()
                .foregroundColor(midPurple)
                .frame(width: 100, height: 100)
                .shadow(color: midPurple.opacity(0.2), radius: 2)
                .offset(x: -3, y: -305)
                .opacity(appeared ? 1 : 0)

            VStack(spacing: 0) {

                Spacer()

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

                VStack(spacing: 16) {
                    Button {
                        onFeelingAtPeace()
                    } label: {
                        Text("Feeling at Peace")
                            .font(.body.bold())
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)

                    Button {
                        onNeedMorePeace()
                    } label: {
                        Text("Still Need More Peace")
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
        }
        .onAppear {
            appeared = true
            orbFloat = true
        }
    }
}

#Preview {
    PeacePromptsCheckInView(
        onFeelingAtPeace: {},
        onNeedMorePeace: {}
    )
}
