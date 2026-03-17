import Foundation
import Testing
@testable import DopamineCore

struct OpenAIResponsesClientTests {
    @Test("OpenAI client sends a Responses request and extracts reply text")
    func extractsReplyText() async throws {
        let endpoint = URL(string: "https://example.com/v1/responses/\(UUID().uuidString)")!
        let session = makeMockSession(endpoint: endpoint) { request in
            #expect(request.url?.absoluteString == endpoint.absoluteString)
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-key")
            #expect(request.httpMethod == "POST")

            let requestURL = try #require(request.url)
            let response = try #require(HTTPURLResponse(
                url: requestURL,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            ))
            let data = Data(#"{"output":[{"content":[{"text":"Hi back."}]}]}"#.utf8)
            return (response, data)
        }

        let client = OpenAIResponsesClient(
            session: session,
            endpoint: endpoint,
            model: "gpt-4.1-mini"
        )

        let reply = try await client.generateReply(
            apiKey: "test-key",
            messages: [ChatMessage(id: "m1", role: .user, content: "Hi", createdAt: .now, projectID: "p1")]
        )

        #expect(reply == "Hi back.")
    }

    @Test("OpenAI client surfaces API error bodies")
    func surfacesAPIErrors() async throws {
        let endpoint = URL(string: "https://example.com/v1/responses/\(UUID().uuidString)")!
        let session = makeMockSession(endpoint: endpoint) { request in
            let response = HTTPURLResponse(
                url: try #require(request.url),
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = Data(#"{"error":{"message":"Invalid API key"}}"#.utf8)
            return (response, data)
        }

        let client = OpenAIResponsesClient(
            session: session,
            endpoint: endpoint
        )

        await #expect(throws: OpenAIResponsesClientError.api(statusCode: 401, message: "Invalid API key")) {
            _ = try await client.generateReply(
                apiKey: "bad-key",
                messages: [ChatMessage(id: "m1", role: .user, content: "Hi", createdAt: .now, projectID: "p1")]
            )
        }
    }

    private func makeMockSession(
        endpoint: URL,
        handler: @escaping @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)
    ) -> URLSession {
        MockURLProtocol.setHandler(handler, for: endpoint.absoluteString)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

private final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    private nonisolated(unsafe) static var handlers: [String: @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)] = [:]
    private static let lock = NSLock()

    static func setHandler(
        _ handler: @escaping @Sendable (URLRequest) throws -> (HTTPURLResponse, Data),
        for url: String
    ) {
        lock.lock()
        handlers[url] = handler
        lock.unlock()
    }

    private static func handler(for url: String) -> (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))? {
        lock.lock()
        defer { lock.unlock() }
        return handlers[url]
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url?.absoluteString,
              let handler = Self.handler(for: url) else {
            client?.urlProtocol(self, didFailWithError: OpenAIResponsesClientError.invalidResponse)
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
