# iOS Voice Chat App

Minimal SwiftUI app demonstrating push-to-talk voice chat over the OpenAI Realtime API.

This target supports two modes:
- Full WebRTC via Swift Package Manager (LiveKit WebRTC) for actual audio. No CocoaPods required.
- Fallback (no WebRTC): builds and runs using a stub to validate the UI and push‑to‑talk flow.

## Quick Start

1) Backend: ensure the Node service is running on `http://localhost:8080`.

2) Option A — Fallback build (no Pods)
```bash
open ios/VoiceChatGpt.xcodeproj
```
Run on an iOS 16+ simulator. The app uses a stubbed `RealtimeClient` that simulates connection and a final reply when you release the button.

3) Option B — Full WebRTC via SPM (recommended)
- The project already references LiveKit’s maintained WebRTC package.
- Open and run the project:
```bash
open ios/VoiceChatGpt.xcodeproj
```
Xcode will resolve the `https://github.com/livekit/webrtc` package and link the `WebRTC` framework automatically.

## Notes

- AVAudioSession configured for voice chat and Bluetooth.
- Minimal SwiftUI UI with push‑to‑talk.
- Real WebRTC wiring enabled via LiveKit’s `WebRTC` Swift Package.
- Local transcript ring buffer and basic PII redaction.
