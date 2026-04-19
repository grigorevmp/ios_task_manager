import SwiftUI

struct TaskDetailView: View {
    @EnvironmentObject private var taskStore: TaskStore
    @EnvironmentObject private var sessionStore: StudySessionStore
    @EnvironmentObject private var noteStore: NoteStore

    let task: TaskEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            heroSection

            Text(task.detailsText)
                .font(.body)

            statGrid
            progressSection
            actionSection
            contextSection

            DisclosureGroup("Что происходит внутри") {
                VStack(alignment: .leading, spacing: 8) {
                    // Этот блок оставлен как встроенная документация прямо в UI.
                    // Он полезен для учебного проекта: пользователь может увидеть,
                    // какие архитектурные решения стоят за экраном, не открывая код.
                    Text("1. View не мутирует Core Data напрямую, а вызывает действия store-слоя.")
                    Text("2. Анимации привязаны к domain state: прогресс, completed/status и selection.")
                    Text("3. Detail не повторяет список задач, а даёт отдельный operational context: метрики, действия и связанные сущности.")
                }
                .font(.callout)
                .padding(.top, 8)
            }
        }
        .padding(24)
        .background(.background, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .animation(.snappy(duration: 0.3), value: task.progress)
        .animation(.snappy(duration: 0.3), value: task.statusRaw)
        .animation(.snappy(duration: 0.3), value: task.isFlagged)
    }

    private var heroSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 10) {
                Text(task.title)
                    .font(.largeTitle.bold())

                Label(task.resolvedProjectPath, systemImage: "folder")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Label(task.priority.title, systemImage: "exclamationmark.circle.fill")
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(task.priority.color.opacity(0.14), in: Capsule())
        }
    }

    private var statGrid: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 16) {
            GridRow {
                statCard(label: "Статус", value: task.status.title, tint: task.status.tint)
                statCard(label: "Pomodoro", value: "\(task.completedPomodoros)/\(task.estimatedPomodoros)", tint: .orange)
            }

            GridRow {
                statCard(label: "Дедлайн", value: task.dueDate?.formatted(date: .abbreviated, time: .omitted) ?? "Нет", tint: .blue)
                statCard(label: "Флаг", value: task.isFlagged ? "Да" : "Нет", tint: .pink)
            }
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Прогресс")
                    .font(.headline)

                Spacer()

                Text("\(Int(task.progress * 100))%")
                    .font(.headline)
                    .contentTransition(.numericText())
            }

            ProgressView(value: task.progress)
                .tint(task.status.tint)

            Text("Полоса прогресса и числовой процент анимируются от одного и того же значения `task.progress`, поэтому интерфейс остаётся синхронным даже при частых обновлениях.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var actionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Действия")
                .font(.headline)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    primaryActions
                }

                VStack(alignment: .leading, spacing: 10) {
                    primaryActions
                }
            }
        }
    }

    @ViewBuilder
    private var primaryActions: some View {
        Button(task.status == .done ? "Вернуть в работу" : "Завершить") {
            taskStore.toggleCompletion(for: task)
        }
        .buttonStyle(.borderedProminent)

        Button("+1 Pomodoro") {
            taskStore.incrementPomodoro(for: task)
            Task {
                #if canImport(ActivityKit) && os(iOS)
                await LiveActivityManager.shared.update(for: task)
                #endif
            }
        }
        .buttonStyle(.bordered)

        Button(task.isFlagged ? "Снять флаг" : "Поставить флаг") {
            taskStore.toggleFlag(for: task)
        }
        .buttonStyle(.bordered)

        Button("Study session") {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                sessionStore.recordSession(from: task)
            }
        }
        .buttonStyle(.bordered)

        Button("Создать note") {
            _ = noteStore.createNote(
                title: "Заметка: \(task.title)",
                markdownText: "# \(task.title)\n\n## Контекст\n\n\(task.detailsText)\n\n## Решение\n\n- [ ] Опиши решение\n- [ ] Добавь выводы",
                projectID: task.project?.id,
                taskID: task.id
            )
        }
        .buttonStyle(.bordered)

        Button("Live Activity") {
            Task {
                #if canImport(ActivityKit) && os(iOS)
                await LiveActivityManager.shared.start(for: task)
                #endif
            }
        }
        .buttonStyle(.bordered)
    }

    private var contextSection: some View {
        HStack(alignment: .top, spacing: 16) {
            statCard(label: "Связанные заметки", value: "\(linkedNotesCount)", tint: .purple)
            statCard(label: "Фокус за неделю", value: "\(sessionStore.weeklyFocusedMinutes()) мин", tint: .teal)
        }
    }

    private var linkedNotesCount: Int {
        noteStore.allNotes().filter { $0.taskID == task.id }.count
    }

    private func statCard(label: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .contentTransition(.numericText())
        }
        .padding(16)
        .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
