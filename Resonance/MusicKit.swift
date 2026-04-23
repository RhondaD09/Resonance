//
//  MusicKit.swift
//  Resonance
//
//  Created by Rhonda Davis on 3/30/26.
//

#if false
import SwiftUI
import MusicKit

struct MusicKit: View {
    
    @State private var searchTerm: String = ""
    @State private var songs: [Song] = []
    @State var authStatus: MusicAuthorization.Status = .notDetermined
    @State private var errorMessage: String? = nil

    private let player = ApplicationMusicPlayer.shared

    
    var body: some View {
        VStack {
            
            TextField("Search for a song...", text: $searchTerm)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Search") {
                searchMusic()
            }
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            List(songs, id: \.id) { song in
                VStack(alignment: .leading) {
                    Text(song.title)
                        .font(.headline)
                    
                    Text(song.artistName)
                        .font(.subheadline)
                    
                    Button("Play") {
                        Task {
                            await playSong(song)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .task {
             await requestMusicAuthorization()
        }
    }
    
    func requestMusicAuthorization() async {
        let status = await MusicAuthorization.request()
        authStatus = status
        
    }
    func searchMusic() {
        Task {
            let request = MusicCatalogSearchRequest(term: searchTerm, types: [Song.self])
            if let response = try? await request.response() {
                songs = Array(response.songs)
                errorMessage = nil
            } else {
                songs = []
                errorMessage = "Search failed. Please try again."
            }
        }
    }

@MainActor
   func playSong(_ song: Song) async {
       do {
           // Optional safety check: can this Apple ID play Apple Music catalog songs?
           let subscription = try await MusicSubscription.current
           guard subscription.canPlayCatalogContent else {
               errorMessage = "This Apple ID can't play Apple Music catalog songs."
               return
           }
           // Put selected song in queue and play
           player.queue = [song]
           try await player.play()
           errorMessage = nil
       } catch {
           errorMessage = "Playback failed: \(error.localizedDescription)"
       }
   }
}
#Preview {
   MusicKit()
}

#endif
