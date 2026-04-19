import SwiftUI

struct ProjectCreationSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onCreate: (_ title: String, _ details: String, _ iconName: String, _ colorName: String, _ groupPath: String) -> Void

    @State private var title = ""
    @State private var details = ""
    @State private var iconName = "folder.fill.badge.plus"
    @State private var colorName = "mint"
    @State private var groupPath = "Custom"

    private let iconOptions = [
        "folder.fill.badge.plus",
        "swift",
        "externaldrive.connected.to.line.below",
        "heart.text.square",
        "book.pages",
        "briefcase.fill"
    ]

    private let colorOptions = ["mint", "orange", "blue", "green", "pink", "red"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Основное") {
                    TextField("Название проекта", text: $title)
                    TextField("Описание", text: $details, axis: .vertical)
                    TextField("Группа", text: $groupPath)
                }

                Section("Визуальный стиль") {
                    Picker("Иконка", selection: $iconName) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Label(iconLabel(for: icon), systemImage: icon).tag(icon)
                        }
                    }

                    Picker("Цвет", selection: $colorName) {
                        ForEach(colorOptions, id: \.self) { color in
                            Text(color.capitalized).tag(color)
                        }
                    }
                }
            }
            .navigationTitle("Новый проект")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        onCreate(
                            title,
                            details.isEmpty ? "Пользовательский проект." : details,
                            iconName,
                            colorName,
                            groupPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Custom" : groupPath
                        )
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func iconLabel(for icon: String) -> String {
        switch icon {
        case "swift": "SwiftUI"
        case "externaldrive.connected.to.line.below": "Data"
        case "heart.text.square": "Wellbeing"
        case "book.pages": "Research"
        case "briefcase.fill": "Work"
        default: "Folder"
        }
    }
}

struct TaskCreationSheet: View {
    @Environment(\.dismiss) private var dismiss

    let projects: [ProjectEntity]
    let suggestedProject: ProjectEntity?
    let onCreate: (_ title: String, _ details: String, _ project: ProjectEntity?, _ priority: TaskPriority) -> Void

    @State private var title = ""
    @State private var details = ""
    @State private var priority: TaskPriority = .medium
    @State private var selectedProjectID = "none"

    var body: some View {
        NavigationStack {
            Form {
                Section("Основное") {
                    TextField("Название задачи", text: $title)
                    TextField("Описание", text: $details, axis: .vertical)

                    Picker("Приоритет", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Text(priority.title).tag(priority)
                        }
                    }
                }

                Section("Проект") {
                    Picker("Привязка", selection: $selectedProjectID) {
                        Text("Без проекта").tag("none")

                        ForEach(projects, id: \.id) { project in
                            Text(project.title).tag(project.id.uuidString)
                        }
                    }
                }
            }
            .navigationTitle("Новая задача")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        onCreate(
                            title,
                            details.isEmpty ? "Новая задача, созданная через форму." : details,
                            projects.first(where: { $0.id.uuidString == selectedProjectID }),
                            priority
                        )
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                selectedProjectID = suggestedProject?.id.uuidString ?? "none"
            }
        }
    }
}

struct NoteCreationSheet: View {
    @Environment(\.dismiss) private var dismiss

    let projects: [ProjectEntity]
    let suggestedProject: ProjectEntity?
    let onCreate: (_ title: String, _ markdownText: String, _ projectID: UUID?) -> Void

    @State private var title = "Новая заметка"
    @State private var markdownText = "# Новая заметка\n\nОпиши идею, решение или план."
    @State private var selectedProjectID = "none"

    var body: some View {
        NavigationStack {
            Form {
                Section("Основное") {
                    TextField("Название заметки", text: $title)
                    TextField("Markdown", text: $markdownText, axis: .vertical)
                        .lineLimit(8, reservesSpace: true)
                }

                Section("Проект") {
                    Picker("Связать с проектом", selection: $selectedProjectID) {
                        Text("Без проекта").tag("none")

                        ForEach(projects, id: \.id) { project in
                            Text(project.title).tag(project.id.uuidString)
                        }
                    }
                }
            }
            .navigationTitle("Новая заметка")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        let projectID = UUID(uuidString: selectedProjectID)
                        onCreate(title, markdownText, projectID)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                selectedProjectID = suggestedProject?.id.uuidString ?? "none"
            }
        }
    }
}
