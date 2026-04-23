//
//  MusicSearchViewModel.swift
//  Resonance
//
//  Created by Rhonda Davis on 3/26/26.
//

import SwiftUI
import MusicKit

@Observable
final class MusicSearchViewModel {
    var query: String = ""
    var songs: [Song] = []
    var nowPlaying: Song? = nil
    var statusText: String = ""
    var authDenied: Bool = false

    @MainActor
    func ensureAuthorized() async {
        let status = MusicAuthorization.currentStatus
        switch status {
        case .authorized:
            authDenied = false
        case .notDetermined:
            let newStatus = await MusicAuthorization.request()
            authDenied = newStatus == .denied || newStatus == .restricted
        case .denied, .restricted:
            authDenied = true
        @unknown default:
            authDenied = true
        }
    }

    @MainActor
    func searchSongs() async {
        guard !authDenied, !query.isEmpty else {
            songs = []
            statusText = authDenied ? "Access to Apple Music denied." : "Enter a search term."
            return
        }

        statusText = "Searching for \"\(query)\"..."
        do {
            var request = MusicCatalogSearchRequest(term: query, types: [Song.self])
            request.limit = 25
            let response = try await request.response()
            let results = Array(response.songs)

            // Prefer items that have play parameters (more likely streamable)
            let playable = results.filter { $0.playParameters != nil }
            songs = playable.isEmpty ? results : playable

            if songs.isEmpty {
                statusText = "No songs found for \"\(query)\"."
            } else {
                statusText = "Found \(songs.count) songs."
            }
        } catch {
            songs = []
            statusText = "Search failed: \(error.localizedDescription)"
        }
    }

    @MainActor
    func play(_ song: Song) async {
        nowPlaying = song
        do {
            let subscription = try await MusicSubscription.current
            guard subscription.canPlayCatalogContent else {
                statusText = "An Apple Music subscription is required to play songs."
                nowPlaying = nil
                return
            }
            let player = ApplicationMusicPlayer.shared
            player.queue = ApplicationMusicPlayer.Queue(for: [song])
            try await player.play()
            statusText = "Playing: \(song.title)"
        } catch {
            statusText = "Playback failed: \(error.localizedDescription)"
            nowPlaying = nil
        }
    }

    @MainActor
    func stop() async {
        let player = ApplicationMusicPlayer.shared
        player.stop()
        nowPlaying = nil
        statusText = "Playback stopped."
    }
}
