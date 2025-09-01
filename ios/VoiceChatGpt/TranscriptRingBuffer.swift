import Foundation

struct TranscriptPair {
    let user: String
    let assistant: String
}

struct TranscriptRingBuffer {
    private var buffer: [TranscriptPair] = []
    private let capacity: Int

    init(capacity: Int) {
        self.capacity = capacity
    }

    mutating func append(user: String, assistant: String) {
        buffer.append(TranscriptPair(user: user, assistant: assistant))
        if buffer.count > capacity {
            buffer.removeFirst(buffer.count - capacity)
        }
    }

    func all() -> [TranscriptPair] {
        buffer
    }
}
