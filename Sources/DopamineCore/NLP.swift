import Foundation

/// Lightweight tokenization/vectorization utilities for project-topic inference.
public enum NLP {
    private static let stopWords: Set<String> = [
        "the", "a", "an", "and", "or", "to", "of", "in", "for", "on", "with", "is", "it", "this",
        "that", "i", "we", "you", "my", "our", "be", "at", "as", "by", "from", "me"
    ]

    public static func tokenize(_ text: String) -> [String] {
        let lower = text.lowercased()
        let clean = lower.replacingOccurrences(of: "[^a-z0-9\\s]", with: " ", options: .regularExpression)
        return clean
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
            .filter { $0.count > 1 && !stopWords.contains($0) }
    }

    public static func vectorize(_ text: String) -> [String: Double] {
        var counts: [String: Double] = [:]
        for token in tokenize(text) {
            counts[token, default: 0] += 1
        }

        let norm = sqrt(counts.values.reduce(0) { $0 + $1 * $1 })
        guard norm > 0 else { return counts }

        var normalized: [String: Double] = [:]
        for (token, value) in counts {
            normalized[token] = value / norm
        }
        return normalized
    }

    public static func cosineSimilarity(_ lhs: [String: Double], _ rhs: [String: Double]) -> Double {
        lhs.reduce(0) { partial, pair in
            partial + pair.value * (rhs[pair.key] ?? 0)
        }
    }

    public static func blendCentroid(
        centroid: [String: Double],
        vector: [String: Double],
        messageCount: Int
    ) -> [String: Double] {
        guard messageCount > 0 else { return vector }

        var next = centroid
        for (token, value) in vector {
            let previous = centroid[token] ?? 0
            next[token] = (previous * Double(messageCount) + value) / Double(messageCount + 1)
        }
        return next
    }
}
