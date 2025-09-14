import XCTest
@testable import VoiceChatGpt

final class TranscriptRingBufferTests: XCTestCase {
    func testRingBufferStoresLimited() {
        var buffer = TranscriptRingBuffer(capacity: 2)
        buffer.append(user: "u1", assistant: "a1")
        buffer.append(user: "u2", assistant: "a2")
        buffer.append(user: "u3", assistant: "a3")
        XCTAssertEqual(buffer.all().count, 2)
        XCTAssertEqual(buffer.all().first?.user, "u2")
    }
}
