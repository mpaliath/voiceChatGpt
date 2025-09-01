import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = VoiceChatViewModel()

    var body: some View {
        VStack(spacing: 24) {
            Text(viewModel.connectionState)
                .font(.caption)
                .foregroundColor(.gray)

            Spacer()

            Button(action: {}) {
                Circle()
                    .fill(viewModel.isTalking ? Color.red : Color.blue)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: viewModel.isTalking ? "mic.fill" : "mic")
                            .foregroundColor(.white)
                            .font(.system(size: 40))
                    )
            }
            .simultaneousGesture(LongPressGesture(minimumDuration: 0.1)
                .onChanged { _ in viewModel.startTalking() }
                .onEnded { _ in viewModel.stopTalking() })

            VStack(alignment: .leading, spacing: 4) {
                Text("You: \(viewModel.lastUserTranscript)")
                    .font(.caption)
                Text("Bot: \(viewModel.lastAssistantTranscript)")
                    .font(.caption)
            }

            Toggle("Send analytics", isOn: $viewModel.analyticsConsent)
                .padding()
        }
        .padding()
        .onAppear { viewModel.connect() }
    }
}

#Preview {
    ContentView()
}
