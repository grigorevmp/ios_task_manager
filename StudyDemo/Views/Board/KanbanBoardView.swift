import SwiftUI

struct KanbanBoardView: View {
    @EnvironmentObject private var taskStore: TaskStore
    @AppStorage(AppPreferenceKeys.boardDensity) private var boardDensity = 1.0
    @SceneStorage("board.selectedProjectID") private var selectedProjectID = ""
    @State private var selectedLaneStatus: TaskStatus?
    @State private var selectedTaskID = ""

    private var metricColumns: [GridItem] {
        // Верхний блок метрик должен ужиматься с 4 колонок на 2,
        // а не ломать заголовки в узкие вертикальные столбцы.
        [GridItem(.adaptive(minimum: 150, maximum: 240), spacing: 16)]
    }

    private var adaptiveColumns: [GridItem] {
        [GridItem(.adaptive(minimum: boardDensity < 1.2 ? 220 : 170), spacing: 16)]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                LazyVGrid(columns: metricColumns, spacing: 16) {
                    ForEach(taskStore.metrics(for: selectedProject)) { metric in
                        StatTileView(metric: metric)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Канбан через сетки и жесты")
                        .font(.title.bold())

                    Text("Доска строится из реальных задач Core Data. Можно смотреть все проекты сразу или выделить один project-срез.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Picker("Проект", selection: selectedProjectBinding) {
                        Text("Все проекты").tag(String?.none)

                        ForEach(taskStore.allProjects(), id: \.id) { project in
                            Text(project.title).tag(Optional(project.id.uuidString))
                        }
                    }
                    .pickerStyle(.menu)
                }

                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 18) {
                        ForEach(TaskStatus.boardOrder) { status in
                            lane(for: status)
                        }
                    }
                    .padding(.vertical, 4)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Adaptive grid для быстрых карточек")
                        .font(.title3.bold())

                    LazyVGrid(columns: adaptiveColumns, spacing: 16) {
                        ForEach(Array(taskStore.allTasks(in: selectedProject).prefix(4)), id: \.id) { task in
                            Button {
                                selectedTaskID = task.id.uuidString
                            } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    Label(task.status.title, systemImage: task.status.systemImage)
                                        .foregroundStyle(task.status.tint)

                                    Text(task.title)
                                        .font(.headline)

                                    Text(task.resolvedProjectTitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Kanban Board")
        .sheet(item: $selectedLaneStatus) { status in
            // Создание задачи из колонки сразу привязывает её к статусу lane.
            // Это убирает лишний шаг после создания и делает kanban настоящим
            // рабочим инструментом, а не только витриной существующих карточек.
            TaskCreationSheet(
                projects: taskStore.allProjects(),
                suggestedProject: selectedProject
            ) { title, details, project, priority in
                _ = taskStore.addTask(
                    title: title,
                    detailsText: details,
                    project: project,
                    status: status,
                    priority: priority
                )
            }
        }
        .sheet(item: selectedTaskBinding) { task in
            NavigationStack {
                TaskInspectorView(task: task)
            }
        }
        .background(
            LinearGradient(
                colors: [.orange.opacity(0.15), .mint.opacity(0.12), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private func lane(for status: TaskStatus) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(status.title, systemImage: status.systemImage)
                    .font(.headline)
                    .foregroundStyle(status.tint)

                Spacer()

                Text("\(taskStore.tasks(for: status, in: selectedProject).count)")
                    .font(.caption.bold())
                    .padding(8)
                    .background(status.tint.opacity(0.14), in: Capsule())

                Button {
                    selectedLaneStatus = status
                } label: {
                    Image(systemName: "plus")
                        .font(.caption.bold())
                        .padding(8)
                        .background(status.tint.opacity(0.14), in: Circle())
                }
                .buttonStyle(.plain)
            }

            LazyVGrid(columns: [GridItem(.flexible())], spacing: 12) {
                ForEach(taskStore.tasks(for: status, in: selectedProject), id: \.id) { task in
                    TaskCardView(
                        task: task,
                        onMove: { delta in
                            guard let newStatus = task.status.shifted(by: delta) else { return }
                            taskStore.move(task, to: newStatus)
                        },
                        onOpen: {
                            selectedTaskID = task.id.uuidString
                        }
                    )
                }
            }
        }
        .frame(width: 280, alignment: .top)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .animation(.snappy(duration: 0.3), value: taskStore.tasks(for: status, in: selectedProject).count)
    }

    private var selectedProject: ProjectEntity? {
        guard !selectedProjectID.isEmpty else { return nil }
        return taskStore.project(idString: selectedProjectID)
    }

    private var selectedProjectBinding: Binding<String?> {
        Binding(
            get: { selectedProjectID.isEmpty ? nil : selectedProjectID },
            set: { selectedProjectID = $0 ?? "" }
        )
    }

    private var selectedTaskBinding: Binding<TaskEntity?> {
        Binding(
            get: { taskStore.task(idString: selectedTaskID) },
            set: { selectedTaskID = $0?.id.uuidString ?? "" }
        )
    }
}
