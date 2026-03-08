import SwiftUI
import DopamineCore

/// Primary SwiftUI composition for project rail, metric strip, and conversation pane.
public struct DopamineRootView: View {
    @StateObject private var model = DopamineViewModel()

    public init() {}

    public var body: some View {
        GeometryReader { geometry in
            NavigationSplitView {
                ProjectRailView(model: model)
                    .navigationTitle("dopamine")
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
    }
}

private struct MetricStripView: View {
    @ObservedObject var model: DopamineViewModel

    var body: some View {
        VStack(spacing: 12) {
            ForEach(model.bars, id: \.id) { bar in
                Button {
                    model.toggleMetric(bar.id)
                } label: {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.07))
                            .frame(height: 38)

                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: bar.colorHex))
                            .frame(width: max(0, bar.value) * 3.0, height: 38)

                        if bar.revealed {
                            Text("\(bar.id.rawValue.capitalized) \(Int(bar.value))%")
                                .font(.footnote.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(bar.id.rawValue.capitalized) metric")
            }
        }
        .padding()
    }
}

private struct ProjectRailView: View {
    @ObservedObject var model: DopamineViewModel
    @State private var pendingRename: Project?
    @State private var renameValue = ""

    var body: some View {
        List {
            Section("Active") {
                ForEach(model.activeProjects) { project in
                    Button {
                        model.selectProject(project.id)
                    } label: {
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
                    }
                    .listRowBackground(model.selectedProjectID == project.id ? Color.blue.opacity(0.2) : Color.clear)
                }
            }

            Section("Archived") {
                ForEach(model.archivedProjects) { project in
                    Button {
                        model.selectProject(project.id)
                    } label: {
                        HStack {
                            Circle()
                                .fill(Color.gray.opacity(0.8))
                                .frame(width: 10, height: 10)
                            Text(project.name)
                                .foregroundStyle(.secondary)
                        }
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
                    Button("Save") {
                        model.renameProject(projectID: project.id, name: renameValue)
                        pendingRename = nil
                    }
                }
                .navigationTitle("Rename Project")
            }
        }
    }
}

private struct ConversationPaneView: View {
    @ObservedObject var model: DopamineViewModel

    var body: some View {
        VStack(spacing: 0) {
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

                Button("Send") {
                    model.sendMessage()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    private func colorForProject(id: String) -> Color {
        let project = (model.activeProjects + model.archivedProjects).first(where: { $0.id == id })
        return Color(hex: project?.colorHex ?? "#8a8f9e")
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
