import Foundation

public enum OpenAIResponsesClientError: Error, LocalizedError, Equatable {
    case missingAPIKey
    case invalidResponse
    case emptyResponse
    case api(statusCode: Int, message: String)

    public var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "An OpenAI API key is required."
        case .invalidResponse:
            return "The OpenAI API returned an invalid response."
        case .emptyResponse:
            return "The OpenAI API returned no text."
        case let .api(statusCode, message):
            return "OpenAI API error (\(statusCode)): \(message)"
        }
    }
}

/// Minimal wrapper around the OpenAI Responses API for plain text chat turns.
public final class OpenAIResponsesClient: @unchecked Sendable {
    public let endpoint: URL
    public let model: String

    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    public init(
        session: URLSession = .shared,
        endpoint: URL = URL(string: "https://api.openai.com/v1/responses")!,
        model: String = "gpt-4.1-mini"
    ) {
        self.session = session
        self.endpoint = endpoint
        self.model = model
    }

    public func generateReply(apiKey: String, messages: [ChatMessage]) async throws -> String {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            throw OpenAIResponsesClientError.missingAPIKey
        }

        let inputMessages = messages
            .filter { !$0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map {
                ResponseRequest.Message(
                    role: $0.role.rawValue,
                    content: [.init(text: $0.content)]
                )
            }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try encoder.encode(
            ResponseRequest(
                model: model,
                input: inputMessages.isEmpty
                    ? [.init(role: MessageRole.user.rawValue, content: [.init(text: "Hi")])]
                    : inputMessages
            )
        )

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIResponsesClientError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let errorEnvelope = try? decoder.decode(APIErrorEnvelope.self, from: data)
            let message = errorEnvelope?.error.message ?? "Unexpected API error."
            throw OpenAIResponsesClientError.api(statusCode: httpResponse.statusCode, message: message)
        }

        let payload = try decoder.decode(ResponseEnvelope.self, from: data)
        if let outputText = payload.outputText?.trimmingCharacters(in: .whitespacesAndNewlines),
           !outputText.isEmpty {
            return outputText
        }

        let extracted = payload.output
            .flatMap(\.content)
            .compactMap(\.text)
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !extracted.isEmpty else {
            throw OpenAIResponsesClientError.emptyResponse
        }

        return extracted
    }
}

private struct ResponseRequest: Encodable {
    let model: String
    let input: [Message]

    struct Message: Encodable {
        let role: String
        let content: [Content]
    }

    struct Content: Encodable {
        let type = "input_text"
        let text: String
    }
}

private struct ResponseEnvelope: Decodable {
    let outputText: String?
    let output: [OutputItem]

    private enum CodingKeys: String, CodingKey {
        case output
        case outputText = "output_text"
    }

    struct OutputItem: Decodable {
        let content: [ContentItem]
    }

    struct ContentItem: Decodable {
        let text: String?
    }
}

private struct APIErrorEnvelope: Decodable {
    let error: APIErrorDetail

    struct APIErrorDetail: Decodable {
        let message: String
    }
}
