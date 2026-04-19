import SwiftUI

/// Общий экран раскрытия задачи.
/// Он используется из канбана, проектов и dashboard-карточек, чтобы у приложения
/// был один понятный способ открыть задачу из любой обзорной секции.
struct TaskInspectorView: View {
    @EnvironmentObject private var taskStore: TaskStore
    @EnvironmentObject private var noteStore: NoteStore

    let task: TaskEntity
    @State private var selectedTaskID = ""
    @State private var selectedNoteID = ""
    @State private var noteDisplayMode: NoteDisplayMode = .preview

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                TaskDetailView(task: task)
                TaskRelationshipDetailCard(
                    task: task,
                    projects: taskStore.relatedProjects(for: task),
                    siblingTasks: taskStore.relatedTasks(for: task),
                    notes: noteStore.notes(for: task),
                    onOpenTask: { sibling in
                        selectedTaskID = sibling.id.uuidString
                    },
                    onOpenNote: { note in
                        selectedNoteID = noteStore.persistentModelIDHash(for: note).uuidString
                    }
                )
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(task.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: selectedNoteBinding) { note in
            NavigationStack {
                NoteInspectorView(note: note, displayMode: $noteDisplayMode)
            }
        }
        .sheet(item: selectedTaskBinding) { task in
            NavigationStack {
                TaskInspectorView(task: task)
            }
        }
    }

    private var selectedNoteBinding: Binding<NoteRecord?> {
        Binding(
            get: { noteStore.note(idString: selectedNoteID) },
            set: { selectedNoteID = $0.map(noteStore.persistentModelIDHash(for:)).map(\.uuidString) ?? "" }
        )
    }

    private var selectedTaskBinding: Binding<TaskEntity?> {
        Binding(
            get: { taskStore.task(idString: selectedTaskID) },
            set: { selectedTaskID = $0?.id.uuidString ?? "" }
        )
    }
}

enum NoteDisplayMode: String, CaseIterable, Identifiable {
    case editor
    case preview
    case split

    var id: String { rawValue }

    var title: String {
        switch self {
        case .editor: "Editor"
        case .preview: "Preview"
        case .split: "Split"
        }
    }
}

/// Общий экран раскрытия заметки.
/// Важно, что он переиспользуется и внутри Notes tab, и из всех остальных мест,
/// где заметка показывается как связанная сущность.
struct NoteInspectorView: View {
    @EnvironmentObject private var noteStore: NoteStore
    @EnvironmentObject private var taskStore: TaskStore

    let note: NoteRecord
    @Binding var displayMode: NoteDisplayMode

    var body: some View {
        VStack(spacing: 0) {
            header
            divider

            switch displayMode {
            case .editor:
                editor
            case .preview:
                preview
            case .split:
                HStack(spacing: 0) {
                    editor
                    divider
                    preview
                }
            }
        }
        .navigationTitle(note.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Название заметки", text: Binding(
                get: { note.title },
                set: {
                    note.title = $0
                    note.updatedAt = .now
                    noteStore.touch(note)
                }
            ))
            .font(.title.bold())
            .textFieldStyle(.roundedBorder)

            HStack {
                Picker("Mode", selection: $displayMode) {
                    ForEach(NoteDisplayMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Spacer()

                Button(note.isPinned ? "Unpin" : "Pin") {
                    noteStore.togglePin(note)
                }

                Menu("Markdown") {
                    ForEach(MarkdownSnippet.allCases) { snippet in
                        Button(snippet.title) {
                            noteStore.insertMarkdownSnippet(snippet, into: note)
                        }
                    }
                }

                Menu("Связать") {
                    ForEach(taskStore.allProjects(), id: \.id) { project in
                        Button(project.title) {
                            note.projectID = project.id
                            note.updatedAt = .now
                            noteStore.touch(note)
                        }
                    }
                }
            }

            if let linkedInfo = linkedInfoText {
                Text(linkedInfo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    private var editor: some View {
        TextEditor(text: Binding(
            get: { note.markdownText },
            set: {
                note.markdownText = $0
                note.updatedAt = .now
                noteStore.touch(note)
            }
        ))
        .font(.body.monospaced())
        .padding()
    }

    private var preview: some View {
        ScrollView {
            MarkdownPreviewView(markdownText: note.markdownText)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.15))
            .frame(height: 1)
    }

    private var linkedInfoText: String? {
        if let projectID = note.projectID,
           let project = taskStore.allProjects().first(where: { $0.id == projectID }) {
            return "Связано с проектом: \(project.title)"
        }
        return nil
    }
}
