import Foundation

enum OpenAIKeySource: String {
    case environment
    case keychain

    var description: String {
        switch self {
        case .environment:
            return "Xcode runtime environment (`OPENAI_API_KEY`)"
        case .keychain:
            return "device Keychain"
        }
    }
}

struct OpenAIKeyResolution {
    let activeKey: String?
    let activeSource: OpenAIKeySource?
    let hasEnvironmentKey: Bool
    let hasKeychainKey: Bool
}

struct OpenAIKeyResolver {
    private let environment: [String: String]
    private let keychainStore: OpenAIKeychainStore

    init(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        keychainStore: OpenAIKeychainStore = OpenAIKeychainStore()
    ) {
        self.environment = environment
        self.keychainStore = keychainStore
    }

    func resolve() throws -> OpenAIKeyResolution {
        let environmentKey = environment["OPENAI_API_KEY"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEnvironmentKey = environmentKey?.isEmpty == false ? environmentKey : nil

        let keychainKey = try keychainStore.load()?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedKeychainKey = keychainKey?.isEmpty == false ? keychainKey : nil

        if let normalizedEnvironmentKey {
            return OpenAIKeyResolution(
                activeKey: normalizedEnvironmentKey,
                activeSource: .environment,
                hasEnvironmentKey: true,
                hasKeychainKey: normalizedKeychainKey != nil
            )
        }

        if let normalizedKeychainKey {
            return OpenAIKeyResolution(
                activeKey: normalizedKeychainKey,
                activeSource: .keychain,
                hasEnvironmentKey: false,
                hasKeychainKey: true
            )
        }

        return OpenAIKeyResolution(
            activeKey: nil,
            activeSource: nil,
            hasEnvironmentKey: false,
            hasKeychainKey: false
        )
    }
}
