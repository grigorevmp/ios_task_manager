import SwiftUI

/// NotesHomeView показывает editor/preview цикл для markdown-заметок.
/// Для учебного проекта это важно, потому что тут одновременно встречаются:
/// - SwiftData model
/// - navigation selection
/// - двустороннее редактирование
/// - markdown preview без сторонних библиотек
struct NotesHomeView: View {
    @EnvironmentObject private var noteStore: NoteStore
    @EnvironmentObject private var taskStore: TaskStore

    @SceneStorage("notes.selectedNoteID") private var selectedNoteID = ""
    @State private var displayMode: NoteDisplayMode = .editor
    @State private var isPresentingCreateSheet = false

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .navigationSplitViewStyle(.balanced)
        .onAppear(perform: ensureValidSelection)
        .onChange(of: noteStore.changeToken) { _, _ in
            ensureValidSelection()
        }
        .sheet(isPresented: $isPresentingCreateSheet) {
            NoteCreationSheet(
                projects: taskStore.allProjects(),
                suggestedProject: nil
            ) { title, markdownText, projectID in
                let note = noteStore.createNote(
                    title: title,
                    markdownText: markdownText,
                    projectID: projectID
                )
                selectedNoteID = noteStore.persistentModelIDHash(for: note).uuidString
            }
        }
    }

    private var sidebar: some View {
        List(selection: selectedNoteBinding) {
            Section("Все заметки") {
                ForEach(noteStore.allNotes(), id: \.persistentModelID) { note in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(note.title)
                                .font(.headline)
                            Text(note.updatedAt, format: .dateTime.day().month().hour().minute())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if note.isPinned {
                            Image(systemName: "pin.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                    .tag(noteStore.persistentModelIDHash(for: note).uuidString)
                }
            }
        }
        .navigationTitle("Заметки")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingCreateSheet = true
                } label: {
                    Label("Новая заметка", systemImage: "square.and.pencil")
                }
            }
        }
    }

    private var detail: some View {
        Group {
            if let note = noteStore.note(idString: selectedNoteID) {
                NoteInspectorView(
                    note: note,
                    displayMode: $displayMode
                )
            } else {
                VStack(spacing: 18) {
                    ContentUnavailableView(
                        "Открой заметку",
                        systemImage: "note.text",
                        description: Text("Во вкладке можно редактировать Markdown и сразу смотреть preview.")
                    )

                    Button("Создать заметку") {
                        isPresentingCreateSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private var selectedNoteBinding: Binding<String?> {
        Binding(
            get: { selectedNoteID.isEmpty ? nil : selectedNoteID },
            set: { selectedNoteID = $0 ?? "" }
        )
    }

    private func ensureValidSelection() {
        let notes = noteStore.allNotes()

        // Для вкладки заметок сохраняем такое же поведение, как и для проектов:
        // при открытии пользователь сначала видит список заметок, а не случайно
        // открытый detail. Автоматический выбор здесь только мешает ориентации.
        guard !notes.isEmpty else {
            selectedNoteID = ""
            return
        }

        if noteStore.note(idString: selectedNoteID) == nil {
            selectedNoteID = ""
        }
    }
}
