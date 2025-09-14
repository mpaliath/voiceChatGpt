# Node Service

Express proxy for the iOS voice chat demo. Exchanges WebRTC SDP with OpenAI Realtime API and stores no API keys on the client.

## Setup

```bash
cp .env.example .env
npm install
npm run dev
```

## Endpoints

### `POST /webrtc/offer`
Exchanges an SDP offer for an answer using OpenAI's Realtime API.

```bash
curl -X POST http://localhost:8080/webrtc/offer \
  -H 'Content-Type: application/json' \
  -d '{"sdp":"SDP_OFFER"}'
```

### `POST /analytics`
Accepts anonymized analytics events when consent is provided.

```bash
curl -X POST http://localhost:8080/analytics \
  -H 'Content-Type: application/json' \
  -d '{"event":"test","payload":{"msg":"hello"},"consent":true}'
```

## Testing

```bash
npm test
```
