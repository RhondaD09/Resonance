//
//  HomeView.swift
//  Resonance
//
//  Created by Rhonda Davis on 3/26/26.
//


#if false
import SwiftUI

struct HomeView: View {
    @Bindable var state: AppState
    @State private var quoteText = "You don't have to regulate everything. Sometimes just noticing is enough."
    @State private var quoteAuthor = "A Piece of Peace Daily"
    @State private var quoteLoaded = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                headerSection
                dailyRingCard
                wellnessGrid
                dailyQuoteCard
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task {
            await fetchDailyQuote()
        }
    }

    private func fetchDailyQuote() async {
        guard !quoteLoaded,
              let url = URL(string: "https://zenquotes.io/api/today") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            struct ZenQuote: Decodable { let q: String; let a: String }
            let quotes = try JSONDecoder().decode([ZenQuote].self, from: data)
            if let first = quotes.first {
                quoteText = first.q
                quoteAuthor = first.a
                quoteLoaded = true
            }
        } catch {
            // Keep the fallback quote on failure
        }
    }

    //Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(colors: [Color.rViolet, Color.rTealDark],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 36, height: 36)
                    Text("✦")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                }

                HStack(spacing: 5) {
                    Text("A Piece of ")
                        .font(.custom("Georgia", size: 40))
                        .foregroundStyle(Color.rText)
                    Text("PEACE")
                        .font(.custom("Georgia", size: 40))
                        .italic()
                        .foregroundStyle(Color.rAccent)
                }
            }
            .padding(.bottom, 14)

            VStack(alignment: .leading, spacing: 0) {
                Text(greetingText + ",")
                    .font(.custom("Georgia", size: 28))
                    .fontWeight(.light)
                    .foregroundStyle(Color.rText)
                Text("How are you holding up?")
                    .font(.custom("Georgia", size: 28))
                    .fontWeight(.light)
                    .italic()
                    .foregroundStyle(Color.rTeal)
            }
            .lineSpacing(2)
            .padding(.bottom, 6)

            Text(dateString.uppercased())
                .font(.system(size: 12))
                .tracking(0.7)
                .foregroundStyle(Color.rMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 20)
        .padding(.bottom, 14)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 17 { return "Good afternoon" }
        return "Good evening"
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()

    private var dateString: String {
        Self.dateFormatter.string(from: Date())
    }

    //Daily Ring

    private var dailyRingCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.05), lineWidth: 5)
                    .frame(width: 56, height: 56)
                Circle()
                    .trim(from: 0, to: state.completionPercentage)
                    .stroke(
                        LinearGradient(colors: [Color.rAccent, Color.rTeal],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 1), value: state.completionPercentage)
                Text("\(Int(state.completionPercentage * 100))%")
                    .font(.custom("Georgia", size: 13))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Daily Wellness")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.rText)
                Text("Complete all activities for a full ring")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.rMuted)

                HStack(spacing: 6) {
                    WellnessBadge(label: "🌬️ Breathe", done: state.doneTasks.contains(.breath))
                    WellnessBadge(label: "🤝 Connect", done: state.doneTasks.contains(.connect))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.rSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.rBorder, lineWidth: 1))
    }

    //Wellness Grid

    private var wellnessGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            WellnessCard(
                icon: "🌬️",
                name: "Breathe",
                subtitle: "4-7-8 or box breathing guided with music",
                streak: "3🔥",
                glowColor: Color.rTeal,
                done: state.doneTasks.contains(.breath)
            ) {
                state.selectedTab = .wellness
            }
            WellnessCard(
                icon: "🤝",
                name: "Connect",
                subtitle: "2 friends waiting to hear from you",
                streak: nil,
                glowColor: Color.rRose,
                done: state.doneTasks.contains(.connect)
            ) {
                state.selectedTab = .connect
            }
        }
    }

    // Daily Quote

    private var dailyQuoteCard: some View {
        CardView {
            CardLabel(text: "Moment of the Day")
                .padding(.bottom, 14)
            Text("\u{201C}\(quoteText)\u{201D}")
                .font(.custom("Georgia", size: 18))
                .fontWeight(.light)
                .italic()
                .foregroundStyle(Color.rMuted2)
                .lineSpacing(4)
            Text("— \(quoteAuthor)")
                .font(.system(size: 11))
                .foregroundStyle(Color.rMuted)
                .padding(.top, 10)
        }
    }
}

//Supporting Views

struct WellnessBadge: View {
    let label: String
    let done: Bool

    var body: some View {
        Text(label)
            .font(.system(size: 10))
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .foregroundStyle(done ? Color.rGreen : Color.rMuted2)
            .background(done ? Color.rGreen.opacity(0.08) : Color.clear)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(done ? Color.rGreen : Color.rBorder2, lineWidth: 1)
            )
    }
}

struct WellnessCard: View {
    let icon: String
    let name: String
    let subtitle: String
    let streak: String?
    let glowColor: Color
    let done: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                Text(icon)
                    .font(.system(size: 26))
                    .padding(.bottom, 8)
                HStack {
                    Text(name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.rText)
                    if done {
                        Text("✓")
                            .foregroundStyle(Color.rGreen)
                            .font(.system(size: 13))
                    }
                }
                .padding(.bottom, 3)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.rMuted)
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.rSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.rBorder, lineWidth: 1)
            )
            .overlay(alignment: .topTrailing) {
                if let streak {
                    Text(streak)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.rGold)
                        .padding(.top, 10)
                        .padding(.trailing, 10)
                }
            }
            .opacity(done ? 0.6 : 1)
        }
        .buttonStyle(.plain)
    }
}


#Preview {
    HomeView(state: AppState())
}
#endif
