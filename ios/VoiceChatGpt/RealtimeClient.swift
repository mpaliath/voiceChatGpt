import Foundation
import WebRTC

final class RealtimeClient: NSObject {
    private var peerConnection: RTCPeerConnection?
    private var dataChannel: RTCDataChannel?
    private var audioTrack: RTCAudioTrack?

    func connect(status: @escaping (String) -> Void) {
        let factory = RTCPeerConnectionFactory()
        let config = RTCConfiguration()
        config.sdpSemantics = .unifiedPlan
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        peerConnection = factory.peerConnection(with: config, constraints: constraints, delegate: self)

        let stream = factory.audioSource(with: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil))
        audioTrack = factory.audioTrack(with: stream, trackId: "audio0")
        if let track = audioTrack {
            track.isEnabled = false
            peerConnection?.add(track, streamIds: ["stream0"])
        }

        let dcConfig = RTCDataChannelConfiguration()
        dataChannel = peerConnection?.dataChannel(forLabel: "oai-events", configuration: dcConfig)

        peerConnection?.offer(for: constraints) { [weak self] offer, error in
            guard let self = self, let offer = offer else { return }
            self.peerConnection?.setLocalDescription(offer) { _ in }
            self.postOffer(sdp: offer.sdp) { answer in
                let remote = RTCSessionDescription(type: .answer, sdp: answer)
                self.peerConnection?.setRemoteDescription(remote) { _ in
                    status("connected")
                }
            }
        }
    }

    func startTalking() {
        audioTrack?.isEnabled = true
    }

    func stopTalking(completion: @escaping (String, String) -> Void) {
        audioTrack?.isEnabled = false
        send(data: ["type": "response.create", "response": ["instructions": "please answer now with a final spoken reply"]])
        // For demo purposes we call completion with empty transcripts
        completion("", "")
    }

    private func send(data: [String: Any]) {
        guard let channel = dataChannel else { return }
        let json = try? JSONSerialization.data(withJSONObject: data)
        if let data = json {
            channel.sendData(RTCDataBuffer(data: data, isBinary: false))
        }
    }

    private func postOffer(sdp: String, completion: @escaping (String) -> Void) {
        guard let url = URL(string: "http://localhost:8080/webrtc/offer") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["sdp": sdp]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                  let answer = json["sdp"] else { return }
            completion(answer)
        }.resume()
    }
}

extension RealtimeClient: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {}
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {}
}
