import SwiftUI

// MARK: - Calm Emoji View

struct CalmEmoji: View {
    var mood: Mood

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(colors: [mood.color.opacity(0.4), mood.color.opacity(0.3)],
                                   center: .center,
                                   startRadius: 10,
                                   endRadius: 120)
                )
                .blur(radius: 25)

            Text(mood == .joyful ? "🥰" : "☺️")
                .font(.system(size: 64))
        }
        .frame(width: 140, height: 140)
    }
}
