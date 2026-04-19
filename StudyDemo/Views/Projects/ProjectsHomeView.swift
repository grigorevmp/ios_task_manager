import SwiftUI

/// ProjectsHomeView — отдельная учебная зона, посвящённая связи "проект -> задачи -> заметки".
/// Здесь intentionally используется split navigation, потому что такой layout хорошо показывает:
/// - master/detail мышление
/// - работу с выбором сущности
/// - переиспользование store-слоя между несколькими экранами
struct ProjectsHomeView: View {
    @EnvironmentObject private var taskStore: TaskStore
    @EnvironmentObject private var noteStore: NoteStore

    @SceneStorage("projects.selectedProjectID") private var selectedProjectID = ""

    @State private var isPresentingProjectSheet = false
    @State private var isPresentingTaskSheet = false
    @State private var isPresentingNoteSheet = false
    @State private var selectedTaskID = ""
    @State private var selectedNoteID = ""
    @State private var noteDisplayMode: NoteDisplayMode = .preview

    var body: some View {
        NavigationSplitView {
            projectSidebar
        } detail: {
            projectDetail
        }
        .navigationSplitViewStyle(.balanced)
        .onAppear(perform: ensureValidSelection)
        .onChange(of: taskStore.changeToken) { _, _ in
            ensureValidSelection()
        }
        .sheet(isPresented: $isPresentingProjectSheet) {
            ProjectCreationSheet { title, details, iconName, colorName, groupPath in
                if let project = taskStore.createProject(
                    title: title,
                    detailsText: details,
                    iconName: iconName,
                    colorName: colorName,
                    groupPath: groupPath
                ) {
                    selectedProjectID = project.id.uuidString
                }
            }
        }
        .sheet(isPresented: $isPresentingTaskSheet) {
            TaskCreationSheet(
                projects: taskStore.allProjects(),
                suggestedProject: selectedProject
            ) { title, details, project, priority in
                _ = taskStore.addTask(
                    title: title,
                    detailsText: details,
                    project: project,
                    priority: priority
                )
            }
        }
        .sheet(isPresented: $isPresentingNoteSheet) {
            NoteCreationSheet(
                projects: taskStore.allProjects(),
                suggestedProject: selectedProject
            ) { title, markdownText, projectID in
                _ = noteStore.createNote(
                    title: title,
                    markdownText: markdownText,
                    projectID: projectID
                )
            }
        }
        .sheet(item: selectedTaskBinding) { task in
            NavigationStack {
                TaskInspectorView(task: task)
            }
        }
        .sheet(item: selectedNoteBinding) { note in
            NavigationStack {
                NoteInspectorView(note: note, displayMode: $noteDisplayMode)
            }
        }
    }

    private var projectSidebar: some View {
        List(selection: selectedProjectBinding) {
            Section("Все проекты") {
                ForEach(taskStore.allProjects(), id: \.id) { project in
                    Label(project.title, systemImage: project.iconName)
                        .tag(project.id.uuidString)
                }
            }
        }
        .navigationTitle("Проекты")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingProjectSheet = true
                } label: {
                    Label("Новый проект", systemImage: "folder.badge.plus")
                }
            }
        }
    }

    private var projectDetail: some View {
        Group {
            if let project = taskStore.project(idString: selectedProjectID) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        ProjectHeroCard(project: project)

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Задачи проекта")
                                    .font(.title2.bold())

                                Spacer()

                                Button("Новая задача") {
                                    isPresentingTaskSheet = true
                                }
                            }

                            if taskStore.tasks(for: project).isEmpty {
                                ContentUnavailableView(
                                    "В проекте пока нет задач",
                                    systemImage: "checklist",
                                    description: Text("Создай первую задачу, и она сразу появится в этой секции и на главной.")
                                )
                            } else {
                                ForEach(taskStore.tasks(for: project), id: \.id) { task in
                                    Button {
                                        selectedTaskID = task.id.uuidString
                                    } label: {
                                        HStack(alignment: .top, spacing: 12) {
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(task.title)
                                                    .font(.headline)
                                                Text(task.detailsText)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                ProgressView(value: task.progress)
                                            }

                                            Spacer()

                                            Label(task.status.title, systemImage: task.status.systemImage)
                                                .font(.caption)
                                                .foregroundStyle(task.status.tint)
                                        }
                                        .padding()
                                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Связанные заметки")
                                    .font(.title3.bold())
                                Spacer()
                                Button("Новая заметка") {
                                    isPresentingNoteSheet = true
                                }
                            }

                            if noteStore.notes(for: project).isEmpty {
                                ContentUnavailableView(
                                    "Пока нет заметок",
                                    systemImage: "note.text",
                                    description: Text("Созданные заметки будут видны здесь и во вкладке заметок.")
                                )
                            } else {
                                ForEach(noteStore.notes(for: project), id: \.persistentModelID) { note in
                                    Button {
                                        selectedNoteID = noteStore.persistentModelIDHash(for: note).uuidString
                                    } label: {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(note.title)
                                                .font(.headline)
                                            Text(note.markdownText)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(4)
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(project.tintColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding()
                }
                .background(Color(uiColor: .systemGroupedBackground))
            } else {
                VStack(spacing: 18) {
                    ContentUnavailableView(
                        "Выбери проект",
                        systemImage: "folder",
                        description: Text("Этот tab показывает отдельный слой работы с проектами и привязку задач/заметок к ним.")
                    )

                    Button("Создать новый проект") {
                        isPresentingProjectSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private var selectedProject: ProjectEntity? {
        taskStore.project(idString: selectedProjectID)
    }

    private var selectedProjectBinding: Binding<String?> {
        Binding(
            get: { selectedProjectID.isEmpty ? nil : selectedProjectID },
            set: { selectedProjectID = $0 ?? "" }
        )
    }

    private func ensureValidSelection() {
        let projects = taskStore.allProjects()

        // Во вкладке проектов пользователь должен сначала видеть список,
        // а detail открывать только после явного выбора. Поэтому мы не выбираем
        // первый проект автоматически при входе на экран: автоселект оставляем
        // только для сценария создания нового проекта, где selection выставляется явно.
        guard !projects.isEmpty else {
            selectedProjectID = ""
            return
        }

        if taskStore.project(idString: selectedProjectID) == nil {
            selectedProjectID = ""
        }
    }

    private var selectedTaskBinding: Binding<TaskEntity?> {
        Binding(
            get: { taskStore.task(idString: selectedTaskID) },
            set: { selectedTaskID = $0?.id.uuidString ?? "" }
        )
    }

    private var selectedNoteBinding: Binding<NoteRecord?> {
        Binding(
            get: { noteStore.note(idString: selectedNoteID) },
            set: { selectedNoteID = $0.map(noteStore.persistentModelIDHash(for:)).map(\.uuidString) ?? "" }
        )
    }
}

private struct ProjectHeroCard: View {
    let project: ProjectEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(project.title, systemImage: project.iconName)
                    .font(.largeTitle.bold())
                Spacer()
                Text("\(project.openTasksCount) open")
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(project.tintColor.opacity(0.15), in: Capsule())
            }

            Text(project.detailsText)
                .foregroundStyle(.secondary)

            ProgressView(value: project.completionRatio) {
                Text("Готовность проекта")
            }

            Text(project.fullPath)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .background(project.tintColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}
