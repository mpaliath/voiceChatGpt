import Foundation

#if canImport(WebRTC)
import WebRTC

// RealtimeClient encapsulates the WebRTC + OpenAI Realtime data channel protocol.
// It now:
// 1. Creates a peer connection & audio track (muted until speaking).
// 2. Opens the "oai-events" RTCDataChannel used by OpenAI for JSON events.
// 3. Sends a session.update after the data channel opens to configure language, VAD, etc.
// 4. Parses incoming assistant text deltas and completion events.
final class RealtimeClient: NSObject {
    private var peerConnection: RTCPeerConnection?
    private var dataChannel: RTCDataChannel?
    private var audioTrack: RTCAudioTrack?

    // Streaming assistant text buffer for current response
    private var currentAssistantBuffer: String = ""

    // Callbacks for UI layer
    var onStatus: ((String) -> Void)?
    var onAssistantTextDelta: ((String) -> Void)? // receives incremental full text
    var onAssistantResponseCompleted: ((String) -> Void)?

    // Default session configuration values
    private let defaultInstructions = "You are a concise, helpful voice assistant. Always respond in English."

    func connect(instructions: String? = nil) {
        let factory = RTCPeerConnectionFactory()
        let config = RTCConfiguration()
        config.sdpSemantics = .unifiedPlan
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        peerConnection = factory.peerConnection(with: config, constraints: constraints, delegate: self)

        // Local microphone audio track; disabled until user starts talking.
        let source = factory.audioSource(with: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil))
        audioTrack = factory.audioTrack(with: source, trackId: "audio0")
        if let track = audioTrack { track.isEnabled = false; peerConnection?.add(track, streamIds: ["stream0"]) }

        // Data channel for events
        let dcConfig = RTCDataChannelConfiguration()
        dataChannel = peerConnection?.dataChannel(forLabel: "oai-events", configuration: dcConfig)
        dataChannel?.delegate = self

        // Create SDP offer and send to backend -> OpenAI
        peerConnection?.offer(for: constraints) { [weak self] offer, error in
            guard let self, let offer else { return }
            self.peerConnection?.setLocalDescription(offer) { _ in }
            self.postOffer(sdp: offer.sdp) { answer in
                let remote = RTCSessionDescription(type: .answer, sdp: answer)
                self.peerConnection?.setRemoteDescription(remote) { [weak self] _ in
                    self?.onStatus?("connected")
                    // Session update will be sent when data channel reports open; store instructions for later.
                    self?.pendingSessionInstructions = instructions ?? self?.defaultInstructions
                }
            }
        }
    }

    // MARK: - Speaking control
    func startTalking() { audioTrack?.isEnabled = true }
    func stopTalking() { audioTrack?.isEnabled = false }

    // MARK: - Session & Responses
    private var pendingSessionInstructions: String?

    private func sendSessionUpdate(_ instructions: String) {
        let payload: [String: Any] = [
            "type": "session.update",
            "session": [
                "instructions": instructions,
                "modalities": ["text", "audio"],
                // Server VAD handles turn detection so we can just toggle track enable; silence detection optional client-side.
                "turn_detection": [
                    "type": "server_vad",
                    "silence_duration_ms": 800
                ],
                "voice": "alloy",
                "language": "en"
            ]
        ]
        send(data: payload)
    }

    func requestFinalResponse() {
        // Ask model to conclude current turn explicitly
        send(data: [
            "type": "response.create",
            "response": ["instructions": "Provide your final spoken reply now."]
        ])
    }

    // MARK: - Low-level send helper
    private func send(data: [String: Any]) {
        guard let channel = dataChannel else { return }
        guard let json = try? JSONSerialization.data(withJSONObject: data) else { return }
        channel.sendData(RTCDataBuffer(data: json, isBinary: false))
    }

    // MARK: - SDP Exchange via backend
    private func postOffer(sdp: String, completion: @escaping (String) -> Void) {
        guard let url = URL(string: "http://localhost:8080/webrtc/offer") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["sdp": sdp])
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                  let answer = json["sdp"] else { return }
            completion(answer)
        }.resume()
    }
}

// MARK: - Peer Connection Delegate
extension RealtimeClient: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {}
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        // Channel opened: send session.update if we have pending instructions.
        if let pending = pendingSessionInstructions { sendSessionUpdate(pending); pendingSessionInstructions = nil }
    }
}

// MARK: - Data Channel Delegate (parsing OpenAI events)
extension RealtimeClient: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        // Could surface state changes if desired
    }

    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        guard !buffer.isBinary, let jsonObj = try? JSONSerialization.jsonObject(with: buffer.data) as? [String: Any], let type = jsonObj["type"] as? String else { return }

        switch type {
        case "response.output_text.delta":
            if let delta = (jsonObj["delta"] as? String) ?? (jsonObj["text"] as? String) { // handle possible naming
                currentAssistantBuffer.append(delta)
                onAssistantTextDelta?(currentAssistantBuffer)
            }
        case "response.completed":
            onAssistantResponseCompleted?(currentAssistantBuffer)
            currentAssistantBuffer = ""
        case "error":
            if let message = jsonObj["error"] as? String { onStatus?("error: \(message)") }
        default:
            break
        }
    }
}

#endif
