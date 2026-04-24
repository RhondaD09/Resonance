//
//  ConnectView.swift
//  Resonance
//
//  Created by Rhonda Davis on 3/26/26.
//



import SwiftUI
import ContactsUI

struct ConnectView: View {
    @Bindable var state: AppState

    // Card colors matching PeacePromptsView style
    private let cardBg = Color(red: 55/255, green: 35/255, blue: 110/255)
    private let cardBorder = Color(red: 160/255, green: 130/255, blue: 240/255)
    private let cardShadow = Color(red: 45/255, green: 20/255, blue: 90/255)

    // Controls whether the "Add Friend" sheet is showing
    @State private var showingAddFriend = false

    // Tracks which friend is being edited
    @State private var editingFriendIndex: Int?
    @State private var showingEditFriend = false

    private let checkinMessages = [
        "👋 Hey, been thinking about you — hope you're doing okay!",
        "🎵 Discovered something I think you'd love — want to share?",
        "☕ Miss you! Can we catch up soon?",
        "💙 Just checking in — no pressure, just wanted you to know I care",
    ]

    // Tracks which check-in message was sent (nil means none sent yet)
    @State private var sentCheckin: Int?

    // Tracks which check-in message the user wants to send (for friend picker)
    @State private var pendingCheckinIndex: Int?
    @State private var showingFriendPickerForCheckin = false

    // Community forum posts
    @State private var posts: [ForumPost] = [
        ForumPost(avatar: "🌿", username: "River", time: "2h ago",
                  avatarBg: Color.rGreen.opacity(0.12), avatarColor: .rGreen,
                  body: "Used the 4-7-8 breathing today with the ocean sounds music pairing. First time I've felt calm before noon in weeks. Sharing in case it helps someone else.",
                  likes: 14, replies: 3),
        ForumPost(avatar: "✨", username: "Sage", time: "5h ago",
                  avatarBg: Color.rAccent.opacity(0.12), avatarColor: .rAccent,
                  body: "Reminded to check in with my sister after 2 weeks. We ended up on a 2-hour call. Sometimes the nudge is all you need.",
                  likes: 31, replies: 7),
        ForumPost(avatar: "🌊", username: "Arlo", time: "Yesterday",
                  avatarBg: Color.rSky.opacity(0.12), avatarColor: .rSky,
                  body: "Stretch + music combo is underrated. I did the desk break set during lunch and actually felt the afternoon energy shift. Try it.",
                  likes: 9, replies: 2),
    ]

    // Text for the "write a post" input
    @State private var newPostText = ""

    // Haptic trigger counter
    @State private var interactionCount = 0

//Main Layout

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 90/255, green: 20/255, blue: 160/255),
                    Color(red: 50/255, green: 10/255, blue: 90/255),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader(
                        title: "Stay",
                        highlight: "connected",
                        subtitle: "Check in before the silence grows too long"
                    )

                    connectHero
                    friendsSection
                    checkinSection
                    communitySection
                }
                .padding(.horizontal, 18)
                .padding(.top, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .sheet(isPresented: $showingAddFriend) {
            FriendFormSheet(state: state)
        }
        .sheet(isPresented: $showingFriendPickerForCheckin) {
            checkinFriendPicker
        }
        .sheet(isPresented: $showingEditFriend) {
            if let index = editingFriendIndex {
                FriendFormSheet(state: state, friendIndex: index)
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: interactionCount)
        .sensoryFeedback(.success, trigger: sentCheckin)
    }

    // Friend picker sheet for check-in messages
    private var checkinFriendPicker: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Send to...")
                    .font(.custom("Georgia", size: 20))
                    .foregroundStyle(Color.rText)
                Spacer()
                Button {
                    showingFriendPickerForCheckin = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.rMuted)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            if let msgIndex = pendingCheckinIndex {
                Text(checkinMessages[msgIndex])
                    .font(.system(size: 13))
                    .foregroundStyle(Color.rMuted2)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }

            ScrollView {
                VStack(spacing: 8) {
                    if state.friends.isEmpty {
                        Text("No friends added yet. Add a friend first!")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.rMuted)
                            .padding(.top, 20)
                    }

                    ForEach(state.friends.indices, id: \.self) { index in
                        let friend = state.friends[index]
                        Button {
                            if let msgIndex = pendingCheckinIndex {
                                sentCheckin = msgIndex
                                state.markDone(.connect)
                                openMessages(
                                    to: friend.phoneNumber,
                                    body: checkinMessages[msgIndex]
                                )
                            }
                            showingFriendPickerForCheckin = false
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(friend.bgColor)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .stroke(friend.color, lineWidth: 2)
                                        )
                                    Text(friend.avatar)
                                        .font(.system(size: 16))
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(friend.name)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(Color.rText)
                                    if !friend.phoneNumber.isEmpty {
                                        Text(friend.phoneNumber)
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color.rMuted)
                                    } else {
                                        Text("No phone number")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color.rRose.opacity(0.6))
                                    }
                                }
                                Spacer()
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.rAccent)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.rSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.rBorder, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(Color.rBg)
        .presentationDetents([.medium])
        .preferredColorScheme(.dark)
    }

    //Hero Banner

    private var connectHero: some View {
        VStack(spacing: 6) {
            Text("You've been thinking of them")
                .font(.custom("Georgia", size: 22))
                .fontWeight(.light)
                .foregroundStyle(Color.rText)

            Text("A Piece of Peace gently reminds you when it's been a while. A small wave can mean everything.")
                .font(.system(size: 13))
                .foregroundStyle(Color.rMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(cardBg.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(cardBorder.opacity(0.15), lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: cardShadow.opacity(0.5), radius: 20, y: 10)
    }

    //Friends List

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FRIENDS TO RECONNECT WITH")
                .font(.system(size: 10))
                .tracking(1.8)
                .foregroundStyle(Color.rMuted)
                .padding(.leading, 2)

            // Show each friend as a row
            ForEach(state.friends.indices, id: \.self) { index in
                friendRow(index: index)
            }

            // "Add a friend" button at the bottom of the list
            Button {
                showingAddFriend = true
            } label: {
                HStack(spacing: 14) {
                    // Plus icon in a circle
                    ZStack {
                        Circle()
                            .fill(Color.rSurface2)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(Color.rBorder2, lineWidth: 1)
                            )
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color.rAccent)
                    }
                    Text("Add a friend")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.rMuted2)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(cardBg.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(cardBorder.opacity(0.15), lineWidth: 1)
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .shadow(color: cardShadow.opacity(0.5), radius: 20, y: 10)
            }
        }
    }

    // @ViewBuilder lets this work like a SwiftUI body (no 'return' needed)
    @ViewBuilder
    private func friendRow(index: Int) -> some View {
        let friend = state.friends[index]
        let borderColor: Color = friend.overdue ? Color.rRose.opacity(0.25) : cardBorder.opacity(0.15)
        let fillColor: Color = cardBg.opacity(0.6)
        let shadowColor: Color = cardShadow.opacity(0.5)

        HStack(spacing: 14) {
            // Avatar circle with emoji — tappable to edit
            Button {
                editingFriendIndex = index
                showingEditFriend = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(friend.bgColor)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(friend.color, lineWidth: 2)
                            )
                        Text(friend.avatar)
                            .font(.system(size: 18))
                    }

                    // Friend name, phone number, and last contact time
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(friend.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.rText)
                            Image(systemName: "pencil")
                                .font(.system(size: 9))
                                .foregroundStyle(Color.rMuted)
                        }
                        if !friend.phoneNumber.isEmpty {
                            Text(friend.phoneNumber)
                                .font(.system(size: 11))
                                .foregroundStyle(Color.rMuted)
                        }
                        Text("Last talked: \(friend.lastTalked)")
                            .font(.system(size: 11))
                            .foregroundStyle(friend.overdue ? Color.rRose : Color.rMuted)
                    }
                }
            }

            Spacer()

            // Wave and message buttons
            HStack(spacing: 7) {
                Button {
                    state.friends[index].waved = true
                    state.friends[index].lastTalkedDate = Date()
                    state.markDone(.connect)
                    interactionCount += 1
                    openMessages(
                        to: friend.phoneNumber,
                        body: "👋 Hey \(friend.name), just thinking about you! Hope you're doing well."
                    )
                } label: {
                    Text(friend.waved ? "✓ Sent!" : "👋 Wave")
                        .font(.system(size: 11))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .foregroundStyle(friend.waved ? Color.rGold : Color.rMuted2)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(friend.waved ? Color.rGold : Color.rBorder2, lineWidth: 1)
                        )
                }

                // Only show message button for overdue friends
                if friend.overdue {
                    Button {
                        state.friends[index].messaged = true
                        state.friends[index].lastTalkedDate = Date()
                        state.markDone(.connect)
                        interactionCount += 1
                        openMessages(
                            to: friend.phoneNumber,
                            body: "Hey \(friend.name)! It's been a while — wanted to reach out and see how you're doing 💙"
                        )
                    } label: {
                        Text(friend.messaged ? "✓" : "💬")
                            .font(.system(size: 11))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .foregroundStyle(friend.messaged ? Color.rGreen : Color.rMuted2)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(friend.messaged ? Color.rGreen : Color.rBorder2, lineWidth: 1)
                            )
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(fillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(borderColor, lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: shadowColor, radius: 20, y: 10)
        .contextMenu {
            Button {
                editingFriendIndex = index
                showingEditFriend = true
            } label: {
                Label("Edit Friend", systemImage: "pencil")
            }
            Button(role: .destructive) {
                let _ = withAnimation {
                    state.friends.remove(at: index)
                }
            } label: {
                Label("Delete Friend", systemImage: "trash")
            }
        }
    }

    // Check-in Prompts

    private var checkinSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("✦ Not sure what to say?")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.rText)

            ForEach(checkinMessages.indices, id: \.self) { index in
                Button {
                    pendingCheckinIndex = index
                    showingFriendPickerForCheckin = true
                } label: {
                    HStack(spacing: 10) {
                        Text(sentCheckin == index ? "✓ Message sent!" : checkinMessages[index])
                            .font(.system(size: 13))
                            .foregroundStyle(sentCheckin == index ? Color.rGreen : Color.rText)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        if sentCheckin != index {
                            Image(systemName: "paperplane")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.rMuted)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(sentCheckin == index ? Color.rGreen.opacity(0.06) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                sentCheckin == index ? Color.rGreen : Color.rBorder,
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(cardBg.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(cardBorder.opacity(0.15), lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: cardShadow.opacity(0.5), radius: 20, y: 10)
    }

//Community Forum

    private var communitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("COMMUNITY CHECK-INS")
                .font(.system(size: 10))
                .tracking(1.8)
                .foregroundStyle(Color.rMuted)
                .padding(.leading, 2)
                .padding(.top, 6)

            // Write a new post
            VStack(alignment: .leading, spacing: 0) {
                CardLabel(text: "Share how you're doing")
                    .padding(.bottom, 10)

                // TextEditor with a custom placeholder on top
                // (SwiftUI TextEditor doesn't have a built-in placeholder,
                //  so we overlay text and hide it when the user starts typing)
                TextEditor(text: $newPostText)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.rText)
                    .scrollContentBackground(.hidden)
                    .frame(height: 80)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.rSurface2)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.rBorder, lineWidth: 1)
                    )
                    .overlay(alignment: .topLeading) {
                        if newPostText.isEmpty {
                            Text("What's on your mind today? This space is safe and kind…")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.rMuted)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 16)
                                .allowsHitTesting(false)
                        }
                    }

                HStack {
                    Spacer()
                    Button {
                        submitPost()
                    } label: {
                        Text("Share ✦")
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .foregroundStyle(Color(red: 10/255, green: 10/255, blue: 15/255))
                            .background(Color.rAccent)
                            .clipShape(Capsule())
                    }
                }
                .padding(.top, 10)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(cardBg.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(cardBorder.opacity(0.15), lineWidth: 1)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: cardShadow.opacity(0.5), radius: 20, y: 10)

            // Display all forum posts
            ForEach(posts.indices, id: \.self) { index in
                postView(index: index)
            }
        }
    }

    @ViewBuilder
    private func postView(index: Int) -> some View {
        let post = posts[index]

        VStack(alignment: .leading, spacing: 0) {
            // Post author info
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(post.avatarBg)
                        .frame(width: 34, height: 34)
                    Text(post.avatar)
                        .font(.system(size: 14))
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(post.username)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.rText)
                    Text(post.time)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.rMuted)
                }
            }
            .padding(.bottom, 10)

            // Post body text
            Text(post.body)
                .font(.system(size: 13))
                .foregroundStyle(Color.rMuted2)
                .lineSpacing(4)
                .padding(.bottom, 12)

            // Like, comment, and share buttons
            HStack(spacing: 16) {
                Button {
                    posts[index].liked.toggle()
                    posts[index].likes += posts[index].liked ? 1 : -1
                    interactionCount += 1
                } label: {
                    HStack(spacing: 4) {
                        Text(post.liked ? "♥" : "♡")
                        Text("\(post.likes)")
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(post.liked ? Color.rRose : Color.rMuted)
                }

                HStack(spacing: 4) {
                    Text("💬")
                    Text("\(post.replies)")
                }
                .font(.system(size: 11))
                .foregroundStyle(Color.rMuted)

                HStack(spacing: 4) {
                    Text("↗")
                    Text("Share")
                }
                .font(.system(size: 11))
                .foregroundStyle(Color.rMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(cardBg.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(cardBorder.opacity(0.15), lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: cardShadow.opacity(0.5), radius: 20, y: 10)
    }

    // Opens the Messages app with a pre-filled SMS
    private func openMessages(to phoneNumber: String, body: String) {
        let smsString = phoneNumber.isEmpty ? "sms:" : "sms:\(phoneNumber)"
        guard var components = URLComponents(string: smsString) else { return }
        components.queryItems = [URLQueryItem(name: "body", value: body)]
        if let url = components.url {
            UIApplication.shared.open(url)
        }
    }

    // Creates a new post from the text input and adds it to the top of the list
    private func submitPost() {
        // Remove extra spaces and blank lines from the edges of the text
        let text = newPostText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Don't post if the text is empty
        guard !text.isEmpty else { return }

        // Create a new post with the user's text
        let newPost = ForumPost(
            avatar: "🎵", username: "You", time: "Just now",
            avatarBg: Color.rAccent.opacity(0.1), avatarColor: .rAccent,
            body: text, likes: 0, replies: 0
        )

        // Add the new post to the top of the list
        posts.insert(newPost, at: 0)

        // Clear the text input
        newPostText = ""
    }
}

// Friend Form Sheet (used for both Add and Edit)

struct FriendFormSheet: View {
    @Bindable var state: AppState
    var friendIndex: Int?
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var selectedAvatar = "👤"
    @State private var selectedColor = "accent"
    @State private var showingContactPicker = false

    private var isEditing: Bool { friendIndex != nil }

    private let avatarChoices = [
        "👩🏽", "👨🏾", "👩🏼", "🧑🏻", "👩🏿",
        "👨🏼", "🧑🏾", "👩🏻", "👨🏽", "🧑🏿",
    ]

    private let colorChoices: [(name: String, color: Color)] = [
        (name: "rose", color: .rRose),
        (name: "gold", color: .rGold),
        (name: "green", color: .rGreen),
        (name: "sky", color: .rSky),
        (name: "accent", color: .rAccent),
        (name: "teal", color: .rTeal),
        (name: "pink", color: .rPink),
    ]

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var selectedColorValue: Color {
        colorChoices.first { $0.name == selectedColor }?.color ?? .rAccent
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(isEditing ? "Edit Friend" : "Add a Friend")
                    .font(.custom("Georgia", size: 22))
                    .foregroundStyle(Color.rText)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.rMuted)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Name input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NAME")
                            .font(.system(size: 10))
                            .tracking(1.8)
                            .foregroundStyle(Color.rMuted)

                        TextField("Enter their name", text: $name)
                            .font(.system(size: 15))
                            .foregroundStyle(Color.rText)
                            .padding(14)
                            .background(Color.rSurface2)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.rBorder2, lineWidth: 1)
                            )
                    }

                    // Phone number input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PHONE NUMBER")
                            .font(.system(size: 10))
                            .tracking(1.8)
                            .foregroundStyle(Color.rMuted)

                        TextField("(313) 555-1234", text: $phoneNumber)
                            .font(.system(size: 15))
                            .foregroundStyle(Color.rText)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                            .padding(14)
                            .background(Color.rSurface2)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.rBorder2, lineWidth: 1)
                            )
                            .onChange(of: phoneNumber) { _, newValue in
                                let formatted = formatPhoneNumber(newValue)
                                if formatted != newValue {
                                    phoneNumber = formatted
                                }
                            }
                    }

                    // Choose from Contacts
                    Button {
                        showingContactPicker = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 16))
                            Text(isEditing ? "Update from Contacts" : "Choose from Contacts")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(Color.rAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.rAccent.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.rAccent.opacity(0.25), lineWidth: 1)
                        )
                    }

                    // Avatar picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("CHOOSE AN AVATAR")
                            .font(.system(size: 10))
                            .tracking(1.8)
                            .foregroundStyle(Color.rMuted)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                            ForEach(avatarChoices, id: \.self) { emoji in
                                Button {
                                    selectedAvatar = emoji
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(selectedAvatar == emoji
                                                ? selectedColorValue.opacity(0.15)
                                                : Color.rSurface2)
                                            .frame(width: 50, height: 50)
                                            .overlay(
                                                Circle()
                                                    .stroke(
                                                        selectedAvatar == emoji
                                                            ? selectedColorValue
                                                            : Color.rBorder,
                                                        lineWidth: selectedAvatar == emoji ? 2 : 1
                                                    )
                                            )
                                        Text(emoji)
                                            .font(.system(size: 22))
                                    }
                                }
                            }
                        }
                    }

                    // Color picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("CHOOSE A COLOR")
                            .font(.system(size: 10))
                            .tracking(1.8)
                            .foregroundStyle(Color.rMuted)

                        HStack(spacing: 10) {
                            ForEach(0..<colorChoices.count, id: \.self) { index in
                                Circle()
                                    .fill(colorChoices[index].color)
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                Color.white,
                                                lineWidth: selectedColor == colorChoices[index].name ? 2 : 0
                                            )
                                    )
                                    .scaleEffect(selectedColor == colorChoices[index].name ? 1.15 : 1.0)
                                    .onTapGesture {
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            selectedColor = colorChoices[index].name
                                        }
                                    }
                            }
                        }
                    }

                    // Save / Add button
                    Button {
                        saveFriend()
                    } label: {
                        Text(isEditing ? "Save Changes ✦" : "Add Friend ✦")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(red: 10/255, green: 10/255, blue: 15/255))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.rAccent)
                            .clipShape(Capsule())
                    }
                    .disabled(trimmedName.isEmpty)
                    .opacity(trimmedName.isEmpty ? 0.5 : 1.0)

                    // Remove button (edit mode only)
                    if let index = friendIndex {
                        Button {
                            state.friends.remove(at: index)
                            dismiss()
                        } label: {
                            Text("Remove Friend")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.rRose)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.rRose.opacity(0.08))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color.rRose.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Color.rBg)
        .preferredColorScheme(.dark)
        .onAppear {
            if let index = friendIndex {
                let friend = state.friends[index]
                name = friend.name
                phoneNumber = friend.phoneNumber
                selectedAvatar = friend.avatar
                selectedColor = friend.colorName
            }
        }
        .fullScreenCover(isPresented: $showingContactPicker) {
            ContactPicker { contact in
                name = [contact.givenName, contact.familyName]
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                if let phone = contact.phoneNumbers.first?.value.stringValue {
                    phoneNumber = formatPhoneNumber(phone)
                }
            }
        }
    }

    private func saveFriend() {
        guard !trimmedName.isEmpty else { return }

        if let index = friendIndex {
            state.friends[index].name = trimmedName
            state.friends[index].phoneNumber = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            state.friends[index].avatar = selectedAvatar
            state.friends[index].colorName = selectedColor
        } else {
            let friend = Friend(
                name: trimmedName,
                avatar: selectedAvatar,
                colorName: selectedColor,
                phoneNumber: phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            state.friends.append(friend)
        }
        dismiss()
    }
}

//Contact Picker

struct ContactPicker: UIViewControllerRepresentable {
    var onSelectContact: (CNContact) -> Void

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelectContact: onSelectContact)
    }

    class Coordinator: NSObject, CNContactPickerDelegate {
        var onSelectContact: (CNContact) -> Void

        init(onSelectContact: @escaping (CNContact) -> Void) {
            self.onSelectContact = onSelectContact
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            onSelectContact(contact)
        }
    }
}

//Phone Number Formatting

// Formats a string of digits into (XXX) XXX-XXXX format
private func formatPhoneNumber(_ value: String) -> String {
    let digits = value.filter { $0.isNumber }
    var result = ""

    for (index, digit) in digits.prefix(10).enumerated() {
        if index == 0 { result += "(" }
        if index == 3 { result += ") " }
        if index == 6 { result += "-" }
        result.append(digit)
    }

    return result
}

#Preview {
    ConnectView(state: AppState())
        .background(Color.rBg)
        .preferredColorScheme(.dark)
}
