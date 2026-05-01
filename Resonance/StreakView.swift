//
//  StreakView.swift
//  Resonance
//
//  Created by Alexus WIlliams on 5/1/26.
//

import SwiftUI

struct StreakView: View {

    @State private var streak = 0

    let streakColors: [Color] = [
        Color(red: 0.22, green: 0.12, blue: 0.35), // Day 1
        Color(red: 0.30, green: 0.16, blue: 0.45), // Day 2
        Color(red: 0.40, green: 0.22, blue: 0.58), // Day 3
        Color(red: 0.52, green: 0.34, blue: 0.70), // Day 4
        Color(red: 0.64, green: 0.48, blue: 0.82), // Day 5
        Color(red: 0.74, green: 0.62, blue: 0.90), // Day 6
        Color(red: 0.84, green: 0.76, blue: 0.96)  // Day 7
    ]

    var body: some View {

        VStack(spacing: 18) {

            Text("PEACE MOMENTUM DAY \(streak)")
                .font(
                    .system(
                        size: 30,
                        weight: .black,
                        design: .serif
                    )
                )
                .foregroundColor(.black)

            HStack(spacing: 18) {

                // Creates 7 circles
                ForEach(0..<7, id: \.self) { index in

                    Circle()

                        .fill(
                            index < streak
                            ? streakColors[index]
                            : Color.gray.opacity(0.25)
                        )
                        .frame(width: 24, height: 24)

                        .shadow(
                            color:
                                index < streak
                                ? streakColors[index].opacity(0.45)
                                : .clear,
                            radius: 6
                        )

                        .scaleEffect(index < streak ? 1.0 : 0.92)
                        .animation(
                            .easeInOut(duration: 0.35),
                            value: streak
                        )
                }
            }
        }
        .onAppear {

            StreakManager.shared.updateStreak()
            streak = min(
                StreakManager.shared.streakCount,
                7
            )
        }
    }
}

#Preview {
    StreakView()
}

