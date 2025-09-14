import SwiftUI
import AVFoundation

@main
struct VoiceChatGptApp: App {
    init() {
        configureAudioSession()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    private func configureAudioSession() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth])
            try session.setActive(true)
        } catch {
            print("AudioSession error: \(error)")
        }
        #else
        // Audio session configuration not required / unavailable on macOS for this app target.
        #endif
    }
}
