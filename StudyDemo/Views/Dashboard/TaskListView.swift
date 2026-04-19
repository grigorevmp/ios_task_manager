import SwiftUI

struct TaskListView: View {
    @EnvironmentObject private var taskStore: TaskStore

    let selection: SidebarSelection
    @Binding var selectedTaskID: String
    @Binding var quickTaskTitle: String
    let showsCompleted: Bool
    @State private var isPresentingTaskSheet = false

    var body: some View {
        // Центральная колонка теперь собрана как dashboard-поток:
        // сверху идёт summary по выбранному фильтру, ниже быстрый capture новых задач,
        // а затем уже список карточек. Это снижает ощущение перегруза,
        // потому что пользователь сначала понимает контекст, а затем читает элементы.
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                taskSummaryCard
                quickCaptureCard

                if tasks.isEmpty {
                    ContentUnavailableView(
                        "Задач нет",
                        systemImage: "checkmark.circle",
                        description: Text("Создай новую задачу или переключись на другой фильтр.")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    LazyVStack(spacing: 14) {
                        ForEach(tasks, id: \.id) { task in
                            Button {
                                withAnimation(.snappy) {
                                    selectedTaskID = task.id.uuidString
                                }
                            } label: {
                                taskRow(task)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(task.status == .done ? "Вернуть в работу" : "Завершить") {
                                    taskStore.toggleCompletion(for: task)
                                }

                                Button(task.isFlagged ? "Снять флаг" : "Поставить флаг") {
                                    taskStore.toggleFlag(for: task)
                                }
                            }
                        }
                    }
                    // Анимация привязана к составу данных, а не к каждому дочернему полю,
                    // чтобы вставка, удаление и смена selection были консистентными.
                    .animation(.snappy(duration: 0.3), value: tasks.map(\.id))
                }
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(selection.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingTaskSheet = true
                } label: {
                    Label("Новая задача", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingTaskSheet) {
            TaskCreationSheet(
                projects: taskStore.allProjects(),
                suggestedProject: taskStore.suggestedProject(for: selection)
            ) { title, details, project, priority in
                if let task = taskStore.addTask(
                    title: title,
                    detailsText: details,
                    project: project,
                    priority: priority
                ) {
                    selectedTaskID = task.id.uuidString
                }
            }
        }
    }

    private var tasks: [TaskEntity] {
        taskStore.tasks(for: selection, showsCompleted: showsCompleted)
    }

    private var flaggedCount: Int {
        tasks.filter(\.isFlagged).count
    }

    private var inProgressCount: Int {
        tasks.filter { $0.status == .inProgress || $0.status == .review }.count
    }

    private var taskSummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(selection.title)
                        .font(.title2.bold())

                    Text(summaryDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Label("\(tasks.count)", systemImage: "list.bullet")
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.accentColor.opacity(0.12), in: Capsule())
            }

            HStack(spacing: 12) {
                SummaryChip(title: "В работе", value: "\(inProgressCount)", tint: .blue)
                SummaryChip(title: "С флагом", value: "\(flaggedCount)", tint: .orange)
                SummaryChip(title: "Готово", value: "\(tasks.filter { $0.status == .done }.count)", tint: .green)
            }
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var quickCaptureCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Быстрый захват")
                .font(.headline)

            Text("Добавляй задачу прямо в текущий контекст, не открывая модальную форму.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                TextField("Быстро добавить задачу", text: $quickTaskTitle)
                    .textFieldStyle(.roundedBorder)

                Button("Добавить") {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        taskStore.addQuickTask(title: quickTaskTitle, selection: selection)
                        selectedTaskID = taskStore.tasks(for: selection, showsCompleted: showsCompleted).last?.id.uuidString ?? selectedTaskID
                        quickTaskTitle = ""
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(quickTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(18)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func taskRow(_ task: TaskEntity) -> some View {
        let isSelected = selectedTaskID == task.id.uuidString

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(task.priority.color)
                    .frame(width: 12, height: 12)
                    .padding(.top, 5)

                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(.headline)
                        .strikethrough(task.status == .done)

                    Text(task.detailsText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Label(task.status.title, systemImage: task.status.systemImage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(task.status.tint)

                    if task.isFlagged {
                        Image(systemName: "flag.fill")
                            .foregroundStyle(.orange)
                    }
                }
            }

            HStack(spacing: 12) {
                rowMeta(text: task.resolvedProjectPath, systemImage: "folder")
                rowMeta(text: task.priority.title, systemImage: "exclamationmark.circle")

                if let dueDate = task.dueDate {
                    rowMeta(text: dueDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                }
            }

            ProgressView(value: task.progress)
                .tint(task.status.tint)
                .animation(.snappy(duration: 0.35), value: task.progress)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.12) : Color(uiColor: .secondarySystemBackground))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(isSelected ? Color.accentColor.opacity(0.32) : Color.clear, lineWidth: 1)
        }
        .scaleEffect(isSelected ? 1 : 0.995)
        .shadow(color: .black.opacity(isSelected ? 0.08 : 0.04), radius: isSelected ? 18 : 10, x: 0, y: 8)
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func rowMeta(text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }

    private var summaryDescription: String {
        switch selection {
        case .today:
            "Показываем только те задачи, которые требуют внимания сегодня."
        case .flagged:
            "Здесь собраны задачи, которые ты отметил как важные."
        case .done:
            "Архив завершённых задач для быстрого обзора результата."
        default:
            "Рабочий поток по выбранному контексту без лишнего визуального шума."
        }
    }
}

private struct SummaryChip: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline)
                .contentTransition(.numericText())

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
