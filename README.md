# Voice Chat GPT

Starter project for a voice-only chat app using OpenAI Realtime API.

## Layout
- `ios/` SwiftUI push-to-talk app
- `service/` Node.js proxy for OpenAI Realtime API

## Quick start

### Backend
```bash
cp service/.env.example service/.env
cd service
npm install
npm run dev
```

### iOS
```bash
cd ios
pod install
open VoiceChatGpt.xcworkspace
```

Hold the button to speak. Release to send audio and hear the model's final spoken reply.

Analytics are disabled by default and require explicit opt-in.

This is a reference implementation; not production ready. Voice PII redaction is best effort after transcription.
