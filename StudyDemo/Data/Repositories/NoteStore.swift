import Foundation
import SwiftData
import Combine

/// NoteStore отделяет редактор заметок от прямой работы с ModelContext.
/// Это делает логику предсказуемой:
/// - view отправляет intention (`create`, `pin`, `insertMarkdownSnippet`)
/// - store меняет модель
/// - UI просто перечитывает состояние
@MainActor
final class NoteStore: ObservableObject {
    private let modelContext: ModelContext
    @Published private(set) var changeToken = 0

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func ensureSeedDataIfNeeded(taskStore: TaskStore) {
        var descriptor = FetchDescriptor<NoteRecord>()
        descriptor.fetchLimit = 1

        guard (try? modelContext.fetchCount(descriptor)) == 0 else { return }
        seedDemoNotes(taskStore: taskStore)
    }

    func resetToDemoData(taskStore: TaskStore) {
        let descriptor = FetchDescriptor<NoteRecord>()
        let notes = (try? modelContext.fetch(descriptor)) ?? []

        for note in notes {
            modelContext.delete(note)
        }

        try? modelContext.save()
        changeToken += 1
        seedDemoNotes(taskStore: taskStore)
    }

    private func seedDemoNotes(taskStore: TaskStore) {
        let projects = taskStore.allProjects()
        let tasks = taskStore.allTasks()
        let swiftUIProject = projects.first(where: { $0.fullPath == "Study App/SwiftUI Basics" })
        let dataProject = projects.first(where: { $0.fullPath == "Study App/Data Layer" })
        let researchProject = projects.first(where: { $0.fullPath == "Personal/Research" })
        let analyticsTask = tasks.first(where: { $0.title.contains("completion analytics") })
        let workspaceTask = tasks.first(where: { $0.title.contains("NavigationSplitView") })

        let introNote = NoteRecord(
            title: "Как читать этот проект",
            markdownText: """
            # Маршрут чтения

            1. Открой `AppContainer`.
            2. Потом посмотри `TaskStore`.
            3. После этого переходи к `PlannerWorkspaceView`.

            > Идея в том, чтобы читать проект сверху вниз: composition root -> stores -> views.

            ## Зачем здесь Markdown

            - можно писать заметки по проектам
            - можно вести research notes
            - можно связывать note с конкретной задачей
            """,
            isPinned: true,
            projectID: swiftUIProject?.id,
            taskID: workspaceTask?.id
        )

        let architectureNote = NoteRecord(
            title: "Разница между Core Data и SwiftData",
            markdownText: """
            # Core Data vs SwiftData

            **Core Data** в этом проекте хранит задачи и проекты.

            **SwiftData** хранит:

            - study sessions
            - markdown notes

            ```swift
            @Model
            final class NoteRecord {
                var title: String
                var markdownText: String
            }
            ```
            """,
            projectID: dataProject?.id,
            taskID: analyticsTask?.id
        )

        let researchNote = NoteRecord(
            title: "Observation и проектные заметки",
            markdownText: """
            # Observation notes

            ## Что проверить

            - [ ] Как `@Observable` влияет на крупные view-model
            - [ ] Когда достаточно `ObservableObject`
            - [ ] Где лучше держать derived state

            > Хорошая учебная заметка не только хранит текст, но и ссылается на проект и задачу.

            ```swift
            @Observable
            final class WorkspaceState {
                var selectedProjectID: UUID?
            }
            ```
            """,
            projectID: researchProject?.id
        )

        modelContext.insert(introNote)
        modelContext.insert(architectureNote)
        modelContext.insert(researchNote)
        try? modelContext.save()
        changeToken += 1
    }

    func allNotes() -> [NoteRecord] {
        _ = changeToken

        let descriptor = FetchDescriptor<NoteRecord>()

        let notes = (try? modelContext.fetch(descriptor)) ?? []

        // Сортируем вручную, чтобы код одинаково работал в разных SDK-конфигурациях
        // и не зависел от перегрузок SortDescriptor для Bool/NSObject.
        return notes.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }

            return lhs.updatedAt > rhs.updatedAt
        }
    }

    func note(idString: String) -> NoteRecord? {
        guard let targetID = UUID(uuidString: idString) else { return nil }
        return allNotes().first(where: { persistentModelIDHash(for: $0) == targetID })
    }

    func notes(for project: ProjectEntity) -> [NoteRecord] {
        allNotes().filter { $0.projectID == project.id }
    }

    func notes(for task: TaskEntity) -> [NoteRecord] {
        allNotes().filter { $0.taskID == task.id }
    }

    func createNote(
        title: String = "Новая заметка",
        markdownText: String = "# Новая заметка\n\nОпиши идею, решение или план.",
        projectID: UUID? = nil,
        taskID: UUID? = nil
    ) -> NoteRecord {
        let note = NoteRecord(
            title: title,
            markdownText: markdownText,
            projectID: projectID,
            taskID: taskID
        )

        modelContext.insert(note)
        save()
        return note
    }

    func duplicate(note: NoteRecord) -> NoteRecord {
        createNote(
            title: "\(note.title) Copy",
            markdownText: note.markdownText,
            projectID: note.projectID,
            taskID: note.taskID
        )
    }

    func touch(_ note: NoteRecord) {
        note.updatedAt = .now
        save()
    }

    func togglePin(_ note: NoteRecord) {
        note.isPinned.toggle()
        note.updatedAt = .now
        save()
    }

    func delete(_ note: NoteRecord) {
        modelContext.delete(note)
        save()
    }

    func insertMarkdownSnippet(_ snippet: MarkdownSnippet, into note: NoteRecord) {
        let separator = note.markdownText.isEmpty ? "" : "\n\n"
        note.markdownText.append(separator + snippet.template)
        note.updatedAt = .now
        save()
    }

    func persistentModelIDHash(for note: NoteRecord) -> UUID {
        // SwiftData не даёт "человеческий" UUID из коробки для generic model identity.
        // Для UI-selection нам нужен стабильный string key, поэтому детерминированно
        // хешируем persistentModelID в UUID-подобный контейнер.
        let string = String(describing: note.persistentModelID)
        let data = Array(string.utf8)
        var bytes = [UInt8](repeating: 0, count: 16)

        for (index, byte) in data.enumerated() {
            bytes[index % 16] ^= byte
        }

        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }

    private func save() {
        try? modelContext.save()
        changeToken += 1
    }
}

enum MarkdownSnippet: String, CaseIterable, Identifiable {
    case heading
    case checklist
    case quote
    case code
    case bold

    var id: String { rawValue }

    var title: String {
        switch self {
        case .heading: "H1"
        case .checklist: "Checklist"
        case .quote: "Quote"
        case .code: "Code"
        case .bold: "Bold"
        }
    }

    var template: String {
        switch self {
        case .heading:
            "# Новый раздел"
        case .checklist:
            "- [ ] Первый пункт\n- [ ] Второй пункт"
        case .quote:
            "> Важная мысль или вывод"
        case .code:
            "```swift\nprint(\"Hello, StudyDemo\")\n```"
        case .bold:
            "**Ключевая мысль**"
        }
    }
}
