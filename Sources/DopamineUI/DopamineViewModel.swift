#if canImport(SwiftUI)
import Foundation
import Observation
import DopamineCore

/// SwiftUI-facing state for the local Dopamine shell.
@MainActor
@Observable
public final class DopamineViewModel {
    public private(set) var messages: [ChatMessage] = []
    public private(set) var activeProjects: [Project] = []
    public private(set) var archivedProjects: [Project] = []
    public private(set) var scores = Scores(focus: 50, momentum: 50, progress: 50)
    public private(set) var isSending = false
    public private(set) var hasOpenAIKey = false
    public private(set) var hasKeychainOpenAIKey = false
    private(set) var openAIKeySource: OpenAIKeySource?
    public private(set) var openAIErrorMessage: String?
    public var selectedProjectID: String?
    public var input = ""
    public var revealedMetric: MetricID?
    public var isOpenAISettingsPresented = false
    public var openAIEnabled = false
    public var openAIKeyDraft = ""

    @ObservationIgnored private let engine: DopamineEngine
    @ObservationIgnored private let openAIClient: OpenAIResponsesClient
    @ObservationIgnored private let keychainStore = OpenAIKeychainStore()
    @ObservationIgnored private let keyResolver = OpenAIKeyResolver()
    @ObservationIgnored private let sessionID: String
    @ObservationIgnored private var archivedCursor: Int?
    @ObservationIgnored private let openAIEnabledDefaultsKey = "dopamine.openai.enabled"

    public init(
        engine: DopamineEngine = DopamineEngine(),
        openAIClient: OpenAIResponsesClient = OpenAIResponsesClient(),
        sessionID: String = "ios-session"
    ) {
        self.engine = engine
        self.openAIClient = openAIClient
        self.sessionID = sessionID
        refreshOpenAIState()
        start()
    }

    public var openAIModelName: String {
        openAIClient.model
    }

    public var replyModeLabel: String {
        if openAIEnabled, hasOpenAIKey {
            return "OpenAI replies (\(openAIModelName))"
        }
        return "Local Dopamine replies"
    }

    public var openAIKeySourceLabel: String? {
        openAIKeySource?.description
    }

    public var openAIStatusMessage: String? {
        if isSending {
            return "Waiting for OpenAI..."
        }

        if openAIEnabled, let source = openAIKeySource {
            return "Using \(source.description)."
        }

        if openAIEnabled, !hasOpenAIKey {
            return "Set `OPENAI_API_KEY` in the Xcode scheme or store a fallback key here."
        }

        return openAIErrorMessage
    }

    public var bars: [BarState] {
        [
            BarState(id: .focus, value: Double(scores.focus), colorHex: "#00b4d8", revealed: revealedMetric == .focus),
            BarState(id: .momentum, value: Double(scores.momentum), colorHex: "#ff9f1c", revealed: revealedMetric == .momentum),
            BarState(id: .progress, value: Double(scores.progress), colorHex: "#2a9d8f", revealed: revealedMetric == .progress)
        ]
    }

    public var visibleMessages: [ChatMessage] {
        guard let selectedProjectID else {
            return messages
        }
        return messages.filter { $0.projectID == selectedProjectID }
    }

    public func start() {
        let response = engine.start(sessionID: sessionID)
        apply(response: response)
        if response.archivedProjects.count > DopamineEngine.archivedPageSize {
            archivedCursor = DopamineEngine.archivedPageSize
            archivedProjects = Array(response.archivedProjects.prefix(DopamineEngine.archivedPageSize))
        }
    }

    public func sendMessage() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        input = ""
        guard !trimmed.isEmpty else { return }

        if openAIEnabled {
            sendOpenAIMessage(trimmed)
            return
        }

        let response = engine.postMessage(sessionID: sessionID, content: trimmed)
        apply(response: response)
    }

    public func finishSession() {
        let response = engine.finish(sessionID: sessionID)
        apply(response: response)
    }

    public func selectProject(_ projectID: String) {
        let result = engine.switchProject(sessionID: sessionID, projectID: projectID)
        activeProjects = result.active
        archivedProjects = result.archived
        selectedProjectID = projectID
    }

    public func renameProject(projectID: String, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let updatedProject = engine.renameProject(sessionID: sessionID, projectID: projectID, name: trimmed) else {
            return
        }
        activeProjects = activeProjects.map { project in
            project.id == projectID ? updatedProject : project
        }
        archivedProjects = archivedProjects.map { project in
            project.id == projectID ? updatedProject : project
        }
    }

    public func reassignMessage(messageID: String, projectID: String) {
        guard engine.reassignMessage(sessionID: sessionID, messageID: messageID, projectID: projectID) else { return }
        messages = messages.map { message in
            var updated = message
            if updated.id == messageID { updated.projectID = projectID }
            return updated
        }
    }

    public func loadArchivedIfNeeded(currentProjectID: String) {
        guard let cursor = archivedCursor,
              archivedProjects.last?.id == currentProjectID else {
            return
        }

        let page = engine.archivedPage(sessionID: sessionID, cursor: cursor)
        archivedProjects.append(contentsOf: page.projects)
        archivedCursor = page.nextCursor
    }

    public func toggleMetric(_ metric: MetricID) {
        revealedMetric = (revealedMetric == metric) ? nil : metric
    }

    public func setOpenAIEnabled(_ enabled: Bool) {
        if enabled, !hasOpenAIKey {
            openAIErrorMessage = "Add an OpenAI API key first."
            isOpenAISettingsPresented = true
            openAIEnabled = false
            return
        }

        openAIEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: openAIEnabledDefaultsKey)
        if enabled {
            openAIErrorMessage = nil
        }
    }

    public func saveOpenAIKey() {
        let trimmed = openAIKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            try keychainStore.save(trimmed)
            openAIKeyDraft = ""
            openAIErrorMessage = nil
            refreshOpenAIState()
        } catch {
            openAIErrorMessage = error.localizedDescription
        }
    }

    public func clearOpenAIKey() {
        do {
            try keychainStore.delete()
            openAIKeyDraft = ""
            openAIErrorMessage = nil
            refreshOpenAIState()
            if !hasOpenAIKey {
                openAIEnabled = false
                UserDefaults.standard.set(false, forKey: openAIEnabledDefaultsKey)
            }
        } catch {
            openAIErrorMessage = error.localizedDescription
        }
    }

    public func openOpenAISettings() {
        openAIErrorMessage = nil
        isOpenAISettingsPresented = true
    }

    private func apply(response: ChatResponse) {
        messages = response.messages
        activeProjects = response.activeProjects
        archivedProjects = response.archivedProjects
        scores = response.scores
        selectedProjectID = response.selectedProjectID ?? response.activeProjects.first?.id
    }

    private func apply(pendingTurn: PendingAssistantTurn) {
        messages = pendingTurn.messages
        activeProjects = pendingTurn.activeProjects
        archivedProjects = pendingTurn.archivedProjects
        scores = pendingTurn.scores
        selectedProjectID = pendingTurn.selectedProjectID ?? pendingTurn.activeProjects.first?.id
    }

    private func refreshOpenAIState() {
        do {
            let resolution = try keyResolver.resolve()
            hasOpenAIKey = resolution.activeKey != nil
            hasKeychainOpenAIKey = resolution.hasKeychainKey
            openAIKeySource = resolution.activeSource
        } catch {
            hasOpenAIKey = false
            hasKeychainOpenAIKey = false
            openAIKeySource = nil
            openAIErrorMessage = error.localizedDescription
        }

        let persisted = UserDefaults.standard.bool(forKey: openAIEnabledDefaultsKey)
        openAIEnabled = persisted && hasOpenAIKey
    }

    private func sendOpenAIMessage(_ content: String) {
        guard !isSending else { return }
        let resolution: OpenAIKeyResolution
        do {
            resolution = try keyResolver.resolve()
        } catch {
            openAIEnabled = false
            hasOpenAIKey = false
            hasKeychainOpenAIKey = false
            openAIKeySource = nil
            openAIErrorMessage = error.localizedDescription
            isOpenAISettingsPresented = true
            return
        }

        guard let apiKey = resolution.activeKey, !apiKey.isEmpty else {
            openAIEnabled = false
            hasOpenAIKey = false
            hasKeychainOpenAIKey = false
            openAIKeySource = nil
            openAIErrorMessage = "Set `OPENAI_API_KEY` in the Xcode scheme or add an OpenAI API key here."
            isOpenAISettingsPresented = true
            return
        }

        isSending = true
        openAIErrorMessage = nil
        openAIKeySource = resolution.activeSource

        let pendingTurn = engine.beginAssistantTurn(sessionID: sessionID, content: content)
        let openAIClient = self.openAIClient
        let transcript = openAITranscript(from: pendingTurn.messages)
        apply(pendingTurn: pendingTurn)

        Task {
            do {
                let reply = try await openAIClient.generateReply(
                    apiKey: apiKey,
                    messages: transcript
                )
                let response = engine.completeAssistantTurn(
                    sessionID: sessionID,
                    content: reply,
                    projectID: pendingTurn.selectedProjectID,
                    archiveEvent: pendingTurn.archiveEvent
                )
                apply(response: response)
            } catch {
                let fallback = "\(pendingTurn.localReply)\n\nOpenAI request failed: \(error.localizedDescription)"
                let response = engine.completeAssistantTurn(
                    sessionID: sessionID,
                    content: fallback,
                    projectID: pendingTurn.selectedProjectID,
                    archiveEvent: pendingTurn.archiveEvent
                )
                openAIErrorMessage = error.localizedDescription
                apply(response: response)
            }

            isSending = false
        }
    }

    private func openAITranscript(from messages: [ChatMessage]) -> [ChatMessage] {
        let trimmed = messages
            .filter {
                let normalized = $0.content.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !normalized.isEmpty else { return false }
                return normalized != "Leader mode active. Pick one small deliverable and complete it before opening new threads."
            }
            .suffix(12)
        return Array(trimmed)
    }
}

#endif
