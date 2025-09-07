import Foundation
import Combine
import AVFoundation

final class VoiceChatViewModel: ObservableObject {
    @Published var connectionState: String = "disconnected"
    @Published var isTalking: Bool = false
    @Published var lastUserTranscript: String = ""
    @Published var lastAssistantTranscript: String = ""
    @Published var analyticsConsent: Bool = false

    private let client = RealtimeClient()
    private var transcripts = TranscriptRingBuffer(capacity: 10)

    private let audioEngine = AVAudioEngine()
    private let silenceThreshold: Float = -50.0 // Adjust threshold as needed
    private let silenceDuration: TimeInterval = 1.0 // Duration to detect pause
    private var silenceTimer: Timer?

    func connect() {
        // Register callbacks before establishing connection
        client.onStatus = { [weak self] status in
            DispatchQueue.main.async { self?.connectionState = status }
        }
        client.onAssistantTextDelta = { [weak self] text in
            DispatchQueue.main.async { self?.lastAssistantTranscript = PIIRedactor.redact(text) }
        }
        client.onAssistantResponseCompleted = { [weak self] finalText in
            guard let self else { return }
            DispatchQueue.main.async {
                let redactedAssistant = PIIRedactor.redact(finalText)
                self.lastAssistantTranscript = redactedAssistant
                if self.analyticsConsent {
                    self.sendAnalytics(event: "assistant_final", payload: ["assistant": redactedAssistant])
                }
            }
        }
        client.connect()
    }

    func startTalking() {
        isTalking = true
        client.startTalking()
        startAudioProcessing()
    }

    func stopTalking() {
        isTalking = false
        stopAudioProcessing()
        client.stopTalking() // just disable local track; model VAD & request final handled separately
        client.requestFinalResponse()
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

    private func startAudioProcessing() {
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
        try? audioEngine.start()
    }

    private func stopAudioProcessing() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        silenceTimer?.invalidate()
    }

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let channelDataValue = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
        let rms = sqrt(channelDataValue.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
        let averagePower = 20 * log10(rms)

        if averagePower < silenceThreshold {
            DispatchQueue.main.async { [weak self] in
                self?.handleSilenceDetected()
            }
        } else {
            silenceTimer?.invalidate()
        }
    }

    private func handleSilenceDetected() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceDuration, repeats: false) { [weak self] _ in
            self?.stopTalking()
        }
    }
}
