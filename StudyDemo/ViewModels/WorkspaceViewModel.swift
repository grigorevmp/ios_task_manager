import Combine
import Foundation

/// WorkspaceViewModel собирает derived state для рабочего места.
/// Он нужен не потому, что SwiftUI "не умеет" считать прямо во view,
/// а потому что для учебного senior-style проекта важно явно отделить:
/// - raw data access через store/repository слой
/// - экранную агрегацию и подготовку секций detail-pane
/// - само декларативное описание UI
@MainActor
final class WorkspaceViewModel: ObservableObject {
    @Published private(set) var contextTasks: [TaskEntity] = []
    @Published private(set) var relatedProjects: [ProjectEntity] = []
    @Published private(set) var relatedNotes: [NoteRecord] = []
    @Published private(set) var recentTasks: [TaskEntity] = []
    @Published private(set) var recentNotes: [NoteRecord] = []
    @Published private(set) var calendarDays: [WorkspaceCalendarDay] = []
    @Published private(set) var selectedDayTasks: [TaskEntity] = []
    @Published private(set) var calendarMonthTitle = ""

    @Published private(set) var selectedTask: TaskEntity?
    @Published private(set) var selectedTaskProjects: [ProjectEntity] = []
    @Published private(set) var siblingTasks: [TaskEntity] = []
    @Published private(set) var selectedTaskNotes: [NoteRecord] = []

    func refresh(
        taskStore: TaskStore,
        noteStore: NoteStore,
        selection: SidebarSelection,
        showsCompleted: Bool,
        selectedTaskID: String,
        selectedDate: Date
    ) {
        contextTasks = taskStore.relatedTasks(for: selection, showsCompleted: showsCompleted)
        relatedProjects = taskStore.relatedProjects(for: selection, showsCompleted: showsCompleted)
        relatedNotes = notesForContext(
            noteStore: noteStore,
            tasks: contextTasks,
            projects: relatedProjects
        )
        let fallbackTasks = taskStore.allTasks().filter { $0.status != .done }
        recentTasks = makeRecentTasks(
            from: contextTasks.isEmpty ? fallbackTasks : contextTasks,
            fallback: fallbackTasks
        )
        recentNotes = makeRecentNotes(
            from: relatedNotes,
            fallback: noteStore.allNotes()
        )
        calendarDays = makeCalendarDays(
            sourceTasks: contextTasks.isEmpty ? fallbackTasks : contextTasks,
            monthDate: selectedDate
        )
        selectedDayTasks = tasksForSelectedDay(
            selectedDate,
            tasks: contextTasks.isEmpty ? fallbackTasks : contextTasks
        )
        calendarMonthTitle = selectedDate.formatted(.dateTime.month(.wide).year())

        if let task = taskStore.task(idString: selectedTaskID) {
            selectedTask = task
            selectedTaskProjects = taskStore.relatedProjects(for: task)
            siblingTasks = taskStore.relatedTasks(for: task)
            selectedTaskNotes = noteStore.notes(for: task)
        } else {
            selectedTask = nil
            selectedTaskProjects = []
            siblingTasks = []
            selectedTaskNotes = []
        }
    }

    private func makeRecentTasks(from tasks: [TaskEntity], fallback: [TaskEntity]) -> [TaskEntity] {
        let source = tasks.isEmpty ? fallback : tasks

        let sorted = source.sorted { lhs, rhs in
            let lhsIsUrgent = lhs.isFlagged || Calendar.current.isDateInToday(lhs.dueDate ?? .distantFuture)
            let rhsIsUrgent = rhs.isFlagged || Calendar.current.isDateInToday(rhs.dueDate ?? .distantFuture)

            if lhsIsUrgent != rhsIsUrgent {
                return lhsIsUrgent && !rhsIsUrgent
            }

            if lhs.status != rhs.status {
                return lhs.status != .done && rhs.status == .done
            }

            return (lhs.dueDate ?? .distantFuture) < (rhs.dueDate ?? .distantFuture)
        }

        return Array(sorted.prefix(5))
    }

    private func makeRecentNotes(from notes: [NoteRecord], fallback: [NoteRecord]) -> [NoteRecord] {
        let source = notes.isEmpty ? fallback : notes

        return source.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }

            return lhs.updatedAt > rhs.updatedAt
        }
        .prefix(4)
        .map { $0 }
    }

    private func makeCalendarDays(sourceTasks: [TaskEntity], monthDate: Date) -> [WorkspaceCalendarDay] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthDate) else { return [] }

        let monthStart = monthInterval.start
        let monthStartWeekday = calendar.component(.weekday, from: monthStart)
        let daysFromPreviousMonth = (monthStartWeekday - calendar.firstWeekday + 7) % 7
        let gridStart = calendar.date(byAdding: .day, value: -daysFromPreviousMonth, to: monthStart) ?? monthStart

        let tasksByDay = Dictionary(grouping: sourceTasks.filter { $0.dueDate != nil }) { task in
            calendar.startOfDay(for: task.dueDate ?? .now)
        }

        return (0..<42).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: gridStart) else { return nil }
            let dayStart = calendar.startOfDay(for: date)
            let tasks = tasksByDay[dayStart] ?? []

            return WorkspaceCalendarDay(
                date: dayStart,
                isInDisplayedMonth: calendar.isDate(dayStart, equalTo: monthStart, toGranularity: .month),
                isToday: calendar.isDateInToday(dayStart),
                dueTasksCount: tasks.count
            )
        }
    }

    private func tasksForSelectedDay(_ selectedDate: Date, tasks: [TaskEntity]) -> [TaskEntity] {
        let calendar = Calendar.current

        return tasks
            .filter { task in
                guard let dueDate = task.dueDate else { return false }
                return calendar.isDate(dueDate, inSameDayAs: selectedDate)
            }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    private func notesForContext(
        noteStore: NoteStore,
        tasks: [TaskEntity],
        projects: [ProjectEntity]
    ) -> [NoteRecord] {
        let taskIDs = Set(tasks.map(\.id))
        let projectIDs = Set(projects.map(\.id))

        return noteStore.allNotes().filter { note in
            if let taskID = note.taskID, taskIDs.contains(taskID) {
                return true
            }

            if let projectID = note.projectID, projectIDs.contains(projectID) {
                return true
            }

            return false
        }
    }
}

struct WorkspaceCalendarDay: Identifiable {
    let date: Date
    let isInDisplayedMonth: Bool
    let isToday: Bool
    let dueTasksCount: Int

    var id: Date { date }
}
