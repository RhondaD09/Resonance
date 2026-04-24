//
//  Theme.swift
//  Resonance
//
//  Created by Rhonda Davis on 3/26/26.
//



import SwiftUI

// Color Theme

extension Color {
    static let rBg = Color(red: 7/255, green: 8/255, blue: 15/255)
    static let rSurface = Color(red: 15/255, green: 16/255, blue: 24/255)
    static let rSurface2 = Color(red: 22/255, green: 23/255, blue: 32/255)
    static let rSurface3 = Color(red: 29/255, green: 30/255, blue: 44/255)
    static let rBorder = Color.white.opacity(0.06)
    static let rBorder2 = Color.white.opacity(0.1)
    static let rText = Color(red: 228/255, green: 228/255, blue: 240/255)
    static let rMuted = Color(red: 228/255, green: 228/255, blue: 240/255).opacity(0.4)
    static let rMuted2 = Color(red: 228/255, green: 228/255, blue: 240/255).opacity(0.6)
    static let rAccent = Color(red: 196/255, green: 181/255, blue: 253/255)
    static let rTeal = Color(red: 94/255, green: 234/255, blue: 212/255)
    static let rGold = Color(red: 251/255, green: 191/255, blue: 36/255)
    static let rRose = Color(red: 251/255, green: 113/255, blue: 133/255)
    static let rSky = Color(red: 125/255, green: 211/255, blue: 252/255)
    static let rGreen = Color(red: 134/255, green: 239/255, blue: 172/255)
    static let rViolet = Color(red: 109/255, green: 40/255, blue: 217/255)
    static let rTealDark = Color(red: 13/255, green: 148/255, blue: 136/255)
    static let rPink = Color(red: 249/255, green: 168/255, blue: 212/255)
}

// Data Models

struct Track: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
}

struct ThemeBreathPhase {
    let label: String
    let duration: Int
    let isInhale: Bool
}

struct Friend: Identifiable, Codable {
    var id = UUID()
    var name: String
    var avatar: String
    var colorName: String
    var lastTalkedDate: Date = Date()
    var waved: Bool = false
    var messaged: Bool = false
    var phoneNumber: String = ""

    // Only encode/decode stored properties
    enum CodingKeys: String, CodingKey {
        case id, name, avatar, colorName, lastTalkedDate, waved, messaged, phoneNumber
    }

    // Human-readable time since last contact
    var lastTalked: String {
        let seconds = Date().timeIntervalSince(lastTalkedDate)
        let minutes = seconds / 60
        let hours = minutes / 60
        let days = hours / 24
        let weeks = days / 7

        if seconds < 60 { return "Just added" }
        if minutes < 60 { return "\(Int(minutes)) min ago" }
        if hours < 24 { return "\(Int(hours))h ago" }
        if days < 2 { return "Yesterday" }
        if days < 7 { return "\(Int(days)) days ago" }
        if weeks < 2 { return "1 week ago" }
        if weeks < 3 { return "2 weeks ago" }
        if weeks < 4 { return "3 weeks ago" }
        return "Over a month ago"
    }

    // Overdue if it's been more than 2 weeks since last contact
    var overdue: Bool {
        Date().timeIntervalSince(lastTalkedDate) > 14 * 24 * 60 * 60
    }

    // Look up the actual Color from the color name
    var color: Color {
        switch colorName {
        case "rose": return .rRose
        case "gold": return .rGold
        case "green": return .rGreen
        case "sky": return .rSky
        case "accent": return .rAccent
        case "teal": return .rTeal
        case "pink": return .rPink
        default: return .rAccent
        }
    }

    // Background color is a lighter version of the main color
    var bgColor: Color {
        color.opacity(0.25)
    }
}

struct ForumPost: Identifiable {
    let id = UUID()
    let avatar: String
    let username: String
    let time: String
    let avatarBg: Color
    let avatarColor: Color
    let body: String
    var likes: Int
    let replies: Int
    var liked: Bool = false
}

// Mood

enum Mood: String, CaseIterable {
    case joyful      = "Joyful"
    case peaceful    = "Peaceful"
    case neutral     = "Low Energy"
    case overwhelmed = "Overwhelmed"
    case frustrated  = "Frustrated"
    case heavy       = "Heavy"

    var color: Color {
        switch self {
        case .joyful:     return .rGold
        case .peaceful:   return .rTeal
        case .neutral:    return .rAccent
        case .overwhelmed: return .rRose
        case .frustrated: return Color(red: 251/255, green: 146/255, blue: 60/255)
        case .heavy:      return .red
        }
    }

    var isNegative: Bool {
        switch self {
        case .overwhelmed, .frustrated, .heavy: return true
        default: return false
        }
    }

    static var positiveMoods: [Mood] {
        [.joyful, .peaceful, .neutral]
    }

    var tagline: String {
        switch self {
        case .joyful:     return "Carrying light today"
        case .peaceful:   return "Settled and still"
        case .neutral:    return "Just here, that's okay"
        case .overwhelmed: return "A lot on your plate"
        case .frustrated: return "Something's stirring"
        case .heavy:      return "Carrying weight today"
        }
    }

    var breathingLabel: String {
        switch self {
        case .joyful:      return "Gratitude Breath"
        case .peaceful:    return "Deepening Breath"
        case .neutral:     return "Grounding Breath"
        case .overwhelmed: return "Release Breath"
        case .frustrated:  return "Reset Breath"
        case .heavy:       return "Comfort Breath"
        }
    }

    var audioMode: Int {
        switch self {
        case .joyful:     return 1
        case .peaceful:   return 0
        case .neutral:    return 0
        case .overwhelmed: return 2
        case .frustrated: return 1
        case .heavy:      return 2
        }
    }

    var breathingDescription: String {
        switch self {
        case .joyful:     return "Box breath · 4-4-4-4 · celebrate"
        case .peaceful:   return "Box breath . 4-4-4-4 · deepen the stillness"
        case .neutral:    return "4-7-8 · ground and center"
        case .overwhelmed: return "4-7-8 · deep release"
        case .frustrated: return "Box breath · 4-7-8. reset and return"
        case .heavy:      return "4-7-8 · gentle comfort"
        }
    }
}

// App State

enum WellnessTask: String, CaseIterable {
    case breath, connect
}

enum Tab: String, CaseIterable {
    case wellness, music, connect
}

@Observable
class AppState {
    var selectedTab: Tab = .wellness
    var isPlaying: Bool = false
    var selectedMood: Mood = .neutral

    var doneTasks: Set<WellnessTask> = [] {
        didSet { saveDoneTasks() }
    }

    var musicSearchQuery: String = ""

    var currentTrackIndex: Int = 0 {
        didSet { UserDefaults.standard.set(currentTrackIndex, forKey: "currentTrackIndex") }
    }

    var friends: [Friend] = [] {
        didSet { saveFriends() }
    }

    private static let defaultFriends: [Friend] = []

    let tracks: [Track] = [
        Track(title: "Gentle Drift", subtitle: "Soft piano · mood-matched · 4 min"),
        Track(title: "Still Waters", subtitle: "Ambient drone · 432Hz · 6 min"),
        Track(title: "Rising Light", subtitle: "Strings + binaural · 5 min"),
        Track(title: "Deep Calm", subtitle: "Ocean waves · theta · 8 min"),
    ]

    var currentTrack: Track {
        tracks[currentTrackIndex]
    }

    var completionPercentage: Double {
        Double(doneTasks.count) / Double(WellnessTask.allCases.count)
    }

    init() {
        let savedIndex = UserDefaults.standard.integer(forKey: "currentTrackIndex")
        self.currentTrackIndex = (0..<4).contains(savedIndex) ? savedIndex : 0

        if let data = UserDefaults.standard.data(forKey: "doneTasks"),
           let rawValues = try? JSONDecoder().decode([String].self, from: data) {
            self.doneTasks = Set(rawValues.compactMap { WellnessTask(rawValue: $0) })
        }

    // One-time migration: clear old placeholder friends
        if !UserDefaults.standard.bool(forKey: "friendsPlaceholderCleared") {
            UserDefaults.standard.removeObject(forKey: "friends")
            UserDefaults.standard.set(true, forKey: "friendsPlaceholderCleared")
        }

    // Load saved friends, or start with empty list
        if let data = UserDefaults.standard.data(forKey: "friends"),
           let saved = try? JSONDecoder().decode([Friend].self, from: data) {
            self.friends = saved
        } else {
            self.friends = Self.defaultFriends
        }
    }

    func markDone(_ task: WellnessTask) {
        doneTasks.insert(task)
    }

    func nextTrack() {
        currentTrackIndex = (currentTrackIndex + 1) % tracks.count
    }

    func prevTrack() {
        currentTrackIndex = (currentTrackIndex - 1 + tracks.count) % tracks.count
    }

    func togglePlay() {
        isPlaying.toggle()
    }

    private func saveDoneTasks() {
        let rawValues = doneTasks.map(\.rawValue)
        if let data = try? JSONEncoder().encode(rawValues) {
            UserDefaults.standard.set(data, forKey: "doneTasks")
        }
    }

    private func saveFriends() {
        if let data = try? JSONEncoder().encode(friends) {
            UserDefaults.standard.set(data, forKey: "friends")
        }
    }
}

// Reusable Components

struct CardView<Content: View>: View {
    var content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.rSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.rBorder, lineWidth: 1)
        )
    }
}

struct CardLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .regular))
            .tracking(1.8)
            .foregroundStyle(Color.rMuted)
    }
}

struct PillButton: View {
    let title: String
    let filled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(filled ? Color.rAccent : Color.clear)
                .foregroundStyle(filled ? Color(red: 10/255, green: 10/255, blue: 15/255) : Color.rMuted2)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(filled ? Color.clear : Color.rBorder2, lineWidth: 1)
                )
        }
    }
}

struct SectionHeader: View {
    let title: String
    let highlight: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 0) {
                Text(title + " ")
                    .font(.custom("Georgia", size: 26))
                    .fontWeight(.light)
                    .foregroundStyle(Color.rText)
                Text(highlight)
                    .font(.custom("Georgia", size: 26))
                    .fontWeight(.light)
                    .italic()
                    .foregroundStyle(Color.rAccent)
            }
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundStyle(Color.rMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 16)
    }
}
