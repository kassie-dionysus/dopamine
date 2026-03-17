#if canImport(SwiftUI)
import SwiftUI
import DopamineCore

/// Adaptive local shell for validating the Dopamine experience on Apple platforms.
public struct DopamineRootView: View {
    @State private var model = DopamineViewModel()

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    public init() {}

    public var body: some View {
        Group {
            #if os(iOS)
            if horizontalSizeClass == .compact {
                MobileShellView(model: model)
            } else {
                DesktopShellView(model: model)
            }
            #else
            DesktopShellView(model: model)
            #endif
        }
        .sheet(isPresented: $model.isOpenAISettingsPresented) {
            OpenAISettingsView(model: model)
        }
    }
}

private struct DesktopShellView: View {
    @Bindable var model: DopamineViewModel

    var body: some View {
        GeometryReader { geometry in
            NavigationSplitView {
                ProjectRailView(model: model)
                    .navigationTitle("Dopamine")
            } detail: {
                VStack(spacing: 0) {
                    MetricStripView(model: model)
                        .frame(height: max(160, geometry.size.height * 0.25))
                        .background(Color(hex: "#111827"))

                    ConversationPaneView(model: model)
                        .frame(height: max(220, geometry.size.height * 0.75))
                }
                .background(Color(hex: "#0b0e14"))
            }
        }
        .toolbar {
            ToolbarItem {
                Button("OpenAI") {
                    model.openOpenAISettings()
                }
            }
        }
    }
}

#if os(iOS)
private struct MobileShellView: View {
    @Bindable var model: DopamineViewModel
    @State private var isProjectSheetPresented = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ActiveProjectChipsView(model: model)
                    .padding(.top, 8)

                MetricStripView(model: model)
                    .frame(height: 150)
                    .background(Color(hex: "#111827"))

                ConversationPaneView(model: model)
            }
            .background(Color(hex: "#0b0e14"))
            .navigationTitle("Dopamine")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("OpenAI") {
                        model.openOpenAISettings()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Projects") {
                        isProjectSheetPresented = true
                    }
                }
            }
            .sheet(isPresented: $isProjectSheetPresented) {
                NavigationStack {
                    ProjectRailView(model: model)
                        .navigationTitle("Projects")
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") {
                                    isProjectSheetPresented = false
                                }
                            }
                        }
                }
            }
        }
    }
}
#endif

private struct MetricStripView: View {
    @Bindable var model: DopamineViewModel

    var body: some View {
        VStack(spacing: 12) {
            ForEach(model.bars, id: \.id) { bar in
                Button {
                    model.toggleMetric(bar.id)
                } label: {
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.07))
                                .frame(height: 38)

                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(hex: bar.colorHex))
                                .frame(
                                    width: proxy.size.width * min(max(bar.value, 0), 100) / 100,
                                    height: 38
                                )

                            if bar.revealed {
                                Text("\(bar.id.rawValue.capitalized) \(Int(bar.value))%")
                                    .font(.footnote.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .frame(height: 38)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(bar.id.rawValue.capitalized) metric")
                .accessibilityValue("\(Int(bar.value)) percent")
            }
        }
        .padding()
    }
}

private struct ActiveProjectChipsView: View {
    @Bindable var model: DopamineViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(model.activeProjects) { project in
                    Button {
                        model.selectProject(project.id)
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: project.colorHex))
                                .frame(width: 10, height: 10)
                            Text(project.name)
                                .font(.footnote.weight(.semibold))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(model.selectedProjectID == project.id ? Color.white.opacity(0.18) : Color.white.opacity(0.08))
                        )
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct ProjectRailView: View {
    @Bindable var model: DopamineViewModel
    @State private var pendingRename: Project?
    @State private var renameValue = ""

    var body: some View {
        List {
            Section("Active") {
                ForEach(model.activeProjects) { project in
                    HStack {
                        Circle()
                            .fill(Color(hex: project.colorHex))
                            .frame(width: 10, height: 10)
                        Text(project.name)
                            .foregroundStyle(.primary)
                        Spacer()
                        Button("Rename") {
                            pendingRename = project
                            renameValue = project.name
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        model.selectProject(project.id)
                    }
                    .listRowBackground(model.selectedProjectID == project.id ? Color.blue.opacity(0.2) : Color.clear)
                }
            }

            Section("Archived") {
                ForEach(model.archivedProjects) { project in
                    HStack {
                        Circle()
                            .fill(Color.gray.opacity(0.8))
                            .frame(width: 10, height: 10)
                        Text(project.name)
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        model.selectProject(project.id)
                    }
                    .onAppear {
                        model.loadArchivedIfNeeded(currentProjectID: project.id)
                    }
                }
            }
        }
        .sheet(item: $pendingRename) { project in
            NavigationStack {
                Form {
                    TextField("Project name", text: $renameValue)
                }
                .navigationTitle("Rename Project")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            pendingRename = nil
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            model.renameProject(projectID: project.id, name: renameValue)
                            pendingRename = nil
                        }
                        .disabled(renameValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
    }
}

private struct ConversationPaneView: View {
    @Bindable var model: DopamineViewModel

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label(model.replyModeLabel, systemImage: model.openAIEnabled ? "bolt.horizontal.circle.fill" : "bubble.left.and.bubble.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.88))

                    Spacer()

                    if model.isSending {
                        ProgressView()
                            .controlSize(.small)
                    }

                    Button(model.openAIEnabled ? "Settings" : "Enable OpenAI") {
                        model.openOpenAISettings()
                    }
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.bordered)
                }

                if let status = model.openAIStatusMessage {
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(model.openAIErrorMessage == nil ? .white.opacity(0.7) : .red.opacity(0.9))
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(model.visibleMessages) { message in
                        MessageCard(
                            message: message,
                            projectColor: colorForProject(id: message.projectID),
                            projects: model.activeProjects + model.archivedProjects,
                            onReassign: { projectID in
                                model.reassignMessage(messageID: message.id, projectID: projectID)
                            }
                        )
                    }
                }
                .padding()
            }

            Divider()

            HStack(spacing: 8) {
                TextField("Tell dopamine your next step...", text: $model.input, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...3)
                    .disabled(model.isSending)
                    .onSubmit {
                        model.sendMessage()
                    }

                Button(model.isSending ? "Sending..." : "Send") {
                    model.sendMessage()
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isSending || model.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
    }

    private func colorForProject(id: String) -> Color {
        let project = (model.activeProjects + model.archivedProjects).first(where: { $0.id == id })
        return Color(hex: project?.colorHex ?? "#8a8f9e")
    }
}

private struct OpenAISettingsView: View {
    @Bindable var model: DopamineViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Mode") {
                    Toggle(
                        "Use OpenAI replies",
                        isOn: Binding(
                            get: { model.openAIEnabled },
                            set: { model.setOpenAIEnabled($0) }
                        )
                    )

                    HStack {
                        Text("Model")
                        Spacer()
                        Text(model.openAIModelName)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("API Key") {
                    if model.openAIKeySource == .environment {
                        Text("Using `OPENAI_API_KEY` from the Xcode scheme/runtime environment. Nothing needs to be stored in the simulator for this to work.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if model.hasKeychainOpenAIKey {
                        Text("A fallback API key is stored in Keychain for this device.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Paste a fallback API key to store it in Keychain for this simulator or device.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    SecureField("sk-...", text: $model.openAIKeyDraft)
#if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
#endif

                    Button("Save Key") {
                        model.saveOpenAIKey()
                    }
                    .disabled(model.openAIKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    if let source = model.openAIKeySourceLabel {
                        Text("Active source: \(source)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if model.hasKeychainOpenAIKey {
                        Button("Remove Key", role: .destructive) {
                            model.clearOpenAIKey()
                        }
                    }
                }

                if let status = model.openAIStatusMessage {
                    Section("Status") {
                        Text(status)
                            .foregroundStyle(model.openAIErrorMessage == nil ? Color.secondary : Color.red)
                    }
                }
            }
            .navigationTitle("OpenAI")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct MessageCard: View {
    var message: ChatMessage
    var projectColor: Color
    var projects: [Project]
    var onReassign: (String) -> Void

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(projectColor)
                .frame(width: 5)

            VStack(alignment: .leading, spacing: 8) {
                Text(message.content)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if message.role == .user {
                    Menu("Move") {
                        ForEach(projects) { project in
                            Button(project.name) {
                                onReassign(project.id)
                            }
                        }
                    }
                    .font(.caption)
                }
            }
            .padding(10)
        }
        .background(message.role == .user ? Color(hex: "#183447") : Color(hex: "#1b2536"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#endif
