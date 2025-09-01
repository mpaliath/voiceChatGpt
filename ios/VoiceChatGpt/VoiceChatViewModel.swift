import Foundation
import Combine

final class VoiceChatViewModel: ObservableObject {
    @Published var connectionState: String = "disconnected"
    @Published var isTalking: Bool = false
    @Published var lastUserTranscript: String = ""
    @Published var lastAssistantTranscript: String = ""
    @Published var analyticsConsent: Bool = false

    private let client = RealtimeClient()
    private var transcripts = TranscriptRingBuffer(capacity: 10)

    func connect() {
        client.connect { [weak self] state in
            DispatchQueue.main.async {
                self?.connectionState = state
            }
        }
    }

    func startTalking() {
        isTalking = true
        client.startTalking()
    }

    func stopTalking() {
        isTalking = false
        client.stopTalking { [weak self] user, assistant in
            guard let self = self else { return }
            DispatchQueue.main.async {
                let redactedUser = PIIRedactor.redact(user)
                let redactedAssistant = PIIRedactor.redact(assistant)
                self.lastUserTranscript = redactedUser
                self.lastAssistantTranscript = redactedAssistant
                self.transcripts.append(user: redactedUser, assistant: redactedAssistant)
                if self.analyticsConsent {
                    self.sendAnalytics(event: "exchange", payload: ["user": redactedUser, "assistant": redactedAssistant])
                }
            }
        }
    }

    private func sendAnalytics(event: String, payload: [String: String]) {
        guard let url = URL(string: "http://localhost:8080/analytics") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["event": event, "payload": payload, "consent": true]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request).resume()
    }
}
