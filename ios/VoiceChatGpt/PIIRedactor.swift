import Foundation

enum PIIRedactor {
    static func redact(_ text: String) -> String {
        let patterns: [String: String] = [
            "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}": "[REDACTED:EMAIL]",
            "(\\+?\\d{1,2}[\\s-]?)?(\\(?\\d{3}\\)?[\\s-]?\\d{3}[\\s-]?\\d{4})": "[REDACTED:PHONE]",
            "\\b(?:\\d[ -]*?){13,16}\\b": "[REDACTED:CARD]",
            "\\b\\d+\\s+(?:[A-Za-z0-9]+\\s+){0,3}(?:Street|St|Avenue|Ave|Road|Rd|Boulevard|Blvd|Lane|Ln)\\b": "[REDACTED:ADDRESS]"
        ]
        var redacted = text
        for (pattern, token) in patterns {
            let regex = try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            redacted = regex.stringByReplacingMatches(in: redacted, range: NSRange(location: 0, length: redacted.utf16.count), withTemplate: token)
        }
        return redacted
    }
}
