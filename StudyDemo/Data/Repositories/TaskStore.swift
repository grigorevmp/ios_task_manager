import Combine
import CoreData
import Foundation
import SwiftUI

/// TaskStore играет роль repository/service слоя для UI.
/// View не ходят в Core Data напрямую, а просят store отдать уже подготовленные данные.
///
/// В более "взрослой" архитектуре его можно было бы разрезать на `TaskRepository`,
/// `ProjectRepository` и use-case слой. Для учебного проекта мы оставляем один store,
/// но расширяем его так, чтобы было видно:
/// - где живёт бизнес-логика задач
/// - где живёт логика проектов
/// - как один persistence context обслуживает несколько связанных сущностей
/// - как на базе тех же сущностей строятся аналитика и UI-представления
@MainActor
final class TaskStore: ObservableObject {
    private let viewContext: NSManagedObjectContext
    private let widgetSyncService: WidgetSyncService
    @Published private(set) var changeToken = 0

    init(viewContext: NSManagedObjectContext, widgetSyncService: WidgetSyncService) {
        self.viewContext = viewContext
        self.widgetSyncService = widgetSyncService
    }

    func ensureSeedDataIfNeeded() {
        guard allProjects().isEmpty || allTasks().isEmpty else { return }
        seedDemoData()
    }

    func resetToDemoData() {
        // Для учебного проекта важно уметь возвращаться в предсказуемое состояние.
        // Поэтому reset не "добавляет ещё один seed", а полностью очищает persistence
        // и заново собирает один демонстрационный dataset, покрывающий все экраны.
        for task in allTasks() {
            viewContext.delete(task)
        }

        for project in allProjects() {
            viewContext.delete(project)
        }

        saveAndPublish()
        seedDemoData()
    }

    func tasks(for selection: SidebarSelection, showsCompleted: Bool) -> [TaskEntity] {
        let filtered = filteredTasks(for: selection)
        return filtered.filter { showsCompleted || $0.status != .done }
    }

    func task(idString: String) -> TaskEntity? {
        guard let uuid = UUID(uuidString: idString) else { return nil }
        return allTasks().first(where: { $0.id == uuid })
    }

    func allTasks() -> [TaskEntity] {
        _ = changeToken

        let request = TaskEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TaskEntity.columnOrder, ascending: true),
            NSSortDescriptor(keyPath: \TaskEntity.createdAt, ascending: true),
        ]

        return (try? viewContext.fetch(request)) ?? []
    }

    func allTasks(in project: ProjectEntity?) -> [TaskEntity] {
        guard let project else { return allTasks() }
        return tasks(for: project)
    }

    func allProjects() -> [ProjectEntity] {
        _ = changeToken

        let request = ProjectEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \ProjectEntity.sortOrder, ascending: true),
            NSSortDescriptor(keyPath: \ProjectEntity.createdAt, ascending: true),
        ]

        return (try? viewContext.fetch(request)) ?? []
    }

    func project(idString: String) -> ProjectEntity? {
        guard let uuid = UUID(uuidString: idString) else { return nil }
        return allProjects().first(where: { $0.id == uuid })
    }

    func tasks(for project: ProjectEntity, includeCompleted: Bool = true) -> [TaskEntity] {
        let tasks = project.taskArray
        return includeCompleted ? tasks : tasks.filter { $0.status != .done }
    }

    func tasks(for status: TaskStatus, in project: ProjectEntity? = nil) -> [TaskEntity] {
        allTasks(in: project)
            .filter { $0.status == status }
            .sorted { lhs, rhs in
                if lhs.columnOrder == rhs.columnOrder {
                    return lhs.createdAt < rhs.createdAt
                }
                return lhs.columnOrder < rhs.columnOrder
            }
    }

    func relatedProjects(for selection: SidebarSelection, showsCompleted: Bool) -> [ProjectEntity] {
        switch selection {
        case .projectSwiftUI, .projectData, .projectWellbeing, .projectResearch:
            let pathPrefix = selectionProjectPath(for: selection)
            return allProjects().filter { $0.fullPath.hasPrefix(pathPrefix) }
        default:
            let tasks = tasks(for: selection, showsCompleted: showsCompleted)
            return deduplicatedProjects(from: tasks.compactMap(\.project))
        }
    }

    func relatedTasks(
        for selection: SidebarSelection,
        showsCompleted: Bool,
        limit: Int = 5
    ) -> [TaskEntity] {
        Array(tasks(for: selection, showsCompleted: showsCompleted).prefix(limit))
    }

    func relatedProjects(for task: TaskEntity) -> [ProjectEntity] {
        guard let project = task.project else { return [] }
        return [project]
    }

    func relatedTasks(for task: TaskEntity, limit: Int = 4) -> [TaskEntity] {
        guard let project = task.project else { return [] }

        return tasks(for: project)
            .filter { $0.id != task.id }
            .prefix(limit)
            .map { $0 }
    }

    func toggleCompletion(for task: TaskEntity) {
        withAnimation(.snappy) {
            if task.status == .done {
                task.status = .today
                task.completedAt = nil
                task.completedPomodoros = min(task.completedPomodoros, max(task.estimatedPomodoros - 1, 0))
            } else {
                task.status = .done
                task.completedAt = .now
                task.completedPomodoros = task.estimatedPomodoros
            }

            saveAndPublish()
        }
    }

    func move(_ task: TaskEntity, to status: TaskStatus) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            task.status = status
            task.columnOrder = Double(tasks(for: status, in: task.project).count + 1)

            if status == .done {
                task.completedAt = task.completedAt ?? .now
                task.completedPomodoros = task.estimatedPomodoros
            } else {
                task.completedAt = nil
            }

            saveAndPublish()
        }
    }

    func incrementPomodoro(for task: TaskEntity) {
        task.completedPomodoros = min(task.completedPomodoros + 1, task.estimatedPomodoros)

        if task.completedPomodoros == task.estimatedPomodoros {
            task.status = .done
            task.completedAt = .now
        }

        saveAndPublish()
    }

    func toggleFlag(for task: TaskEntity) {
        task.isFlagged.toggle()
        saveAndPublish()
    }

    func addQuickTask(title: String, selection: SidebarSelection) {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let suggestedProject = suggestedProject(for: selection)
        let suggestedStatus: TaskStatus = switch selection {
        case .done:
            .done
        case .inProgress:
            .inProgress
        default:
            .today
        }

        _ = addTask(
            title: title,
            detailsText: "Быстрая задача, добавленная из учебного рабочего места.",
            project: suggestedProject,
            dueDate: .now,
            status: suggestedStatus,
            priority: .medium,
            isFlagged: selection == .flagged
        )
    }

    func createProject(
        title: String,
        detailsText: String,
        iconName: String,
        colorName: String,
        groupPath: String = "Custom"
    ) -> ProjectEntity? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return nil }

        let project = ProjectEntity(context: viewContext)
        project.id = UUID()
        project.title = trimmedTitle
        project.detailsText = detailsText
        project.iconName = iconName
        project.colorName = colorName
        project.createdAt = .now
        project.sortOrder = Double(allProjects().count + 1)
        project.fullPath = "\(groupPath)/\(trimmedTitle)"

        saveAndPublish()
        return project
    }

    func addTask(
        title: String,
        detailsText: String,
        project: ProjectEntity?,
        dueDate: Date? = .now,
        status: TaskStatus = .today,
        priority: TaskPriority = .medium,
        isFlagged: Bool = false
    ) -> TaskEntity? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return nil }

        let task = TaskEntity(context: viewContext)
        task.id = UUID()
        task.title = trimmedTitle
        task.detailsText = detailsText
        task.createdAt = .now
        task.dueDate = dueDate
        task.completedAt = status == .done ? .now : nil
        task.priority = priority
        task.status = status
        task.estimatedPomodoros = 2
        task.completedPomodoros = status == .done ? 2 : 0
        task.isFlagged = isFlagged
        task.columnOrder = Double(tasks(for: status, in: project).count + 1)
        task.project = project
        task.projectPath = project?.fullPath ?? "Inbox/No Project"

        saveAndPublish()
        return task
    }

    func suggestedProject(for selection: SidebarSelection) -> ProjectEntity? {
        let path = selectionProjectPath(for: selection)
        return allProjects().first(where: { $0.fullPath == path })
    }

    func metrics(for project: ProjectEntity? = nil) -> [OverviewMetric] {
        let tasks = allTasks(in: project)
        return [
            OverviewMetric(title: "Всего задач", value: "\(tasks.count)", systemImage: "checklist", tint: .blue),
            OverviewMetric(title: "В работе", value: "\(tasks.filter { $0.status == .inProgress || $0.status == .review }.count)", systemImage: "bolt", tint: .orange),
            OverviewMetric(title: "Завершено", value: "\(tasks.filter { $0.status == .done }.count)", systemImage: "checkmark.circle", tint: .green),
            OverviewMetric(title: "С флагом", value: "\(tasks.filter(\.isFlagged).count)", systemImage: "flag.fill", tint: .red),
        ]
    }

    func completionRatio(for project: ProjectEntity? = nil) -> Double {
        let tasks = allTasks(in: project)
        guard !tasks.isEmpty else { return 0 }
        let completedCount = tasks.filter { $0.status == .done }.count
        return Double(completedCount) / Double(tasks.count)
    }

    func completionChartPoints(days: Int = 7, project: ProjectEntity? = nil) -> [TaskCompletionChartPoint] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: .now)
        let completedTasks = allTasks(in: project).filter { $0.status == .done }

        let grouped = Dictionary(grouping: completedTasks) { task in
            calendar.startOfDay(for: task.completedAt ?? task.createdAt)
        }

        return (0..<days).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: todayStart) else { return nil }

            let tasksForDay = grouped[day] ?? []
            let focusedMinutes = tasksForDay.reduce(0) { partialResult, task in
                partialResult + Int(task.estimatedPomodoros) * 25
            }

            return TaskCompletionChartPoint(
                date: day,
                completedTasks: tasksForDay.count,
                focusedMinutes: focusedMinutes
            )
        }
    }

    func completedTasksCount(days: Int = 7, project: ProjectEntity? = nil) -> Int {
        completionChartPoints(days: days, project: project)
            .reduce(0) { $0 + $1.completedTasks }
    }

    func completedFocusMinutes(days: Int = 7, project: ProjectEntity? = nil) -> Int {
        completionChartPoints(days: days, project: project)
            .reduce(0) { $0 + $1.focusedMinutes }
    }

    func makeSyncPayload() -> [TaskSyncPayload] {
        allTasks().map {
            TaskSyncPayload(
                title: $0.title,
                status: $0.status,
                priority: $0.priority,
                isFlagged: $0.isFlagged,
                remainingPomodoros: Int(max($0.estimatedPomodoros - $0.completedPomodoros, 0))
            )
        }
    }

    func makeWidgetSnapshot() -> TaskWidgetSnapshot {
        let tasks = allTasks()
        let nextTask = tasks
            .filter { $0.status != .done }
            .sorted { lhs, rhs in
                (lhs.dueDate ?? .distantFuture) < (rhs.dueDate ?? .distantFuture)
            }
            .first

        return TaskWidgetSnapshot(
            totalTasks: tasks.count,
            completedTasks: tasks.filter { $0.status == .done }.count,
            focusMinutesThisWeek: completedFocusMinutes(days: 7),
            nextTaskTitle: nextTask?.title ?? "Все задачи закрыты",
            lastUpdated: .now
        )
    }

    private func filteredTasks(for selection: SidebarSelection) -> [TaskEntity] {
        let tasks = allTasks()

        return tasks.filter { task in
            switch selection {
            case .inbox:
                return task.status != .done
            case .today:
                guard let dueDate = task.dueDate else { return false }
                return Calendar.current.isDateInToday(dueDate) && task.status != .done
            case .flagged:
                return task.isFlagged
            case .inProgress:
                return task.status == .inProgress || task.status == .review
            case .done:
                return task.status == .done
            case .projectSwiftUI, .projectData, .projectWellbeing, .projectResearch:
                return task.resolvedProjectPath.hasPrefix(selectionProjectPath(for: selection))
            }
        }
    }

    private func selectionProjectPath(for selection: SidebarSelection) -> String {
        switch selection {
        case .projectSwiftUI:
            "Study App/SwiftUI Basics"
        case .projectData:
            "Study App/Data Layer"
        case .projectWellbeing:
            "Personal/Wellbeing"
        case .projectResearch:
            "Personal/Research"
        default:
            "Study App/SwiftUI Basics"
        }
    }

    private func seedDemoData() {
        let calendar = Calendar.current
        let today = Date()

        let projectSpecs: [(title: String, details: String, icon: String, color: String, fullPath: String, sortOrder: Double)] = [
            (
                "SwiftUI Basics",
                "Основной учебный проект по навигации, layout, состоянию, анимациям и reusable view-компонентам.",
                "swift",
                "orange",
                "Study App/SwiftUI Basics",
                0
            ),
            (
                "Data Layer",
                "Зона про Core Data, SwiftData, репозитории, demo bootstrap и подготовку аналитики.",
                "externaldrive.connected.to.line.below",
                "blue",
                "Study App/Data Layer",
                1
            ),
            (
                "Wellbeing",
                "Личные задачи и routines. Нужен, чтобы показать, что архитектура работает не только для одной domain-группы.",
                "heart.text.square",
                "green",
                "Personal/Wellbeing",
                2
            ),
            (
                "Research",
                "Исследовательские темы, статьи и markdown notes, привязанные к проектам и задачам.",
                "book.pages",
                "pink",
                "Personal/Research",
                3
            ),
        ]

        var projectsByPath: [String: ProjectEntity] = [:]

        for spec in projectSpecs {
            let project = ProjectEntity(context: viewContext)
            project.id = UUID()
            project.title = spec.title
            project.detailsText = spec.details
            project.iconName = spec.icon
            project.colorName = spec.color
            project.fullPath = spec.fullPath
            project.createdAt = today
            project.sortOrder = spec.sortOrder
            projectsByPath[spec.fullPath] = project
        }

        let taskSpecs: [DemoTaskSeed] = [
            DemoTaskSeed(
                title: "Собрать NavigationSplitView workspace",
                details: "Свяжи sidebar, content и detail так, чтобы список задач и контекст проекта жили в одном рабочем месте.",
                status: .today,
                priority: .high,
                estimatedPomodoros: 4,
                completedPomodoros: 1,
                isFlagged: true,
                projectPath: "Study App/SwiftUI Basics",
                dueDayOffset: 0,
                createdDayOffset: 3
            ),
            DemoTaskSeed(
                title: "Связать TaskDetail с related context",
                details: "При выборе задачи detail должен показывать не только саму карточку, но и её проект и соседние задачи.",
                status: .inProgress,
                priority: .critical,
                estimatedPomodoros: 3,
                completedPomodoros: 2,
                isFlagged: true,
                projectPath: "Study App/SwiftUI Basics",
                dueDayOffset: 1,
                createdDayOffset: 4
            ),
            DemoTaskSeed(
                title: "Подготовить live activity demo",
                details: "Покажи задачу, которую можно использовать для фокус-сессии и обновления Live Activity.",
                status: .done,
                priority: .high,
                estimatedPomodoros: 3,
                completedPomodoros: 3,
                isFlagged: false,
                projectPath: "Study App/SwiftUI Basics",
                dueDayOffset: 0,
                createdDayOffset: 5,
                completedDayOffset: 0
            ),
            DemoTaskSeed(
                title: "Написать senior-level комментарии к слоям",
                details: "Комментарии должны объяснять причины решений, а не пересказывать синтаксис.",
                status: .done,
                priority: .critical,
                estimatedPomodoros: 2,
                completedPomodoros: 2,
                isFlagged: false,
                projectPath: "Study App/SwiftUI Basics",
                dueDayOffset: -1,
                createdDayOffset: 8,
                completedDayOffset: 6
            ),
            DemoTaskSeed(
                title: "Реализовать completion analytics",
                details: "Графики должны считаться из реальных `TaskEntity.completedAt`, а не из абстрактных заглушек.",
                status: .today,
                priority: .high,
                estimatedPomodoros: 3,
                completedPomodoros: 1,
                isFlagged: true,
                projectPath: "Study App/Data Layer",
                dueDayOffset: 0,
                createdDayOffset: 2
            ),
            DemoTaskSeed(
                title: "Добавить completedAt в Core Data модель",
                details: "Нужна дата фактического завершения, чтобы строить статистику по дням и показывать историю движения задач.",
                status: .done,
                priority: .high,
                estimatedPomodoros: 2,
                completedPomodoros: 2,
                isFlagged: false,
                projectPath: "Study App/Data Layer",
                dueDayOffset: -1,
                createdDayOffset: 6,
                completedDayOffset: 1
            ),
            DemoTaskSeed(
                title: "Синхронизировать SwiftData sessions с completed tasks",
                details: "Сделай так, чтобы demo-сессии отражали те же дни, в которые реально закрывались задачи.",
                status: .done,
                priority: .medium,
                estimatedPomodoros: 2,
                completedPomodoros: 2,
                isFlagged: false,
                projectPath: "Study App/Data Layer",
                dueDayOffset: -2,
                createdDayOffset: 7,
                completedDayOffset: 3
            ),
            DemoTaskSeed(
                title: "Подготовить wellbeing weekly review",
                details: "Нужен отдельный личный поток задач, чтобы рабочее место показывало несколько project-групп.",
                status: .backlog,
                priority: .medium,
                estimatedPomodoros: 2,
                completedPomodoros: 0,
                isFlagged: false,
                projectPath: "Personal/Wellbeing",
                dueDayOffset: 2,
                createdDayOffset: 1
            ),
            DemoTaskSeed(
                title: "Закрыть тренировочный чеклист",
                details: "Готовая личная задача нужна для демонстрации completed history и прогресса по проекту.",
                status: .done,
                priority: .low,
                estimatedPomodoros: 1,
                completedPomodoros: 1,
                isFlagged: false,
                projectPath: "Personal/Wellbeing",
                dueDayOffset: -3,
                createdDayOffset: 5,
                completedDayOffset: 5
            ),
            DemoTaskSeed(
                title: "Разобрать статью про Observation",
                details: "Исследовательская задача должна жить в отдельном проекте, но попадать в канбан и рабочее место наравне с остальными.",
                status: .review,
                priority: .medium,
                estimatedPomodoros: 2,
                completedPomodoros: 1,
                isFlagged: false,
                projectPath: "Personal/Research",
                dueDayOffset: 1,
                createdDayOffset: 2
            ),
            DemoTaskSeed(
                title: "Написать заметку про markdown pipeline",
                details: "Эта задача нужна, чтобы связать исследования с заметками и показать cross-storage navigation.",
                status: .backlog,
                priority: .low,
                estimatedPomodoros: 1,
                completedPomodoros: 0,
                isFlagged: false,
                projectPath: "Personal/Research",
                dueDayOffset: 3,
                createdDayOffset: 0
            ),
            DemoTaskSeed(
                title: "Закрыть research summary",
                details: "Готовая исследовательская задача создаёт ещё одну точку на графике completion statistics.",
                status: .done,
                priority: .medium,
                estimatedPomodoros: 1,
                completedPomodoros: 1,
                isFlagged: false,
                projectPath: "Personal/Research",
                dueDayOffset: -2,
                createdDayOffset: 4,
                completedDayOffset: 2
            ),
        ]

        var boardOrderByStatus: [TaskStatus: Int] = [:]

        for seed in taskSpecs {
            let task = TaskEntity(context: viewContext)
            task.id = UUID()
            task.title = seed.title
            task.detailsText = seed.details
            task.status = seed.status
            task.priority = seed.priority
            task.estimatedPomodoros = seed.estimatedPomodoros
            task.completedPomodoros = seed.completedPomodoros
            task.isFlagged = seed.isFlagged
            task.projectPath = seed.projectPath
            task.project = projectsByPath[seed.projectPath]
            task.createdAt = calendar.date(byAdding: .day, value: -seed.createdDayOffset, to: today) ?? today
            task.dueDate = calendar.date(byAdding: .day, value: seed.dueDayOffset, to: today)
            task.completedAt = seed.completedDayOffset.flatMap {
                calendar.date(byAdding: .day, value: -$0, to: today)
            }
            task.columnOrder = Double(boardOrderByStatus[seed.status, default: 0])
            boardOrderByStatus[seed.status, default: 0] += 1
        }

        saveAndPublish()
    }

    private func deduplicatedProjects(from projects: [ProjectEntity]) -> [ProjectEntity] {
        var seenIDs = Set<UUID>()
        return projects
            .filter { seenIDs.insert($0.id).inserted }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private func saveAndPublish() {
        try? viewContext.save()
        changeToken += 1
        widgetSyncService.store(snapshot: makeWidgetSnapshot())
    }
}

private struct DemoTaskSeed {
    let title: String
    let details: String
    let status: TaskStatus
    let priority: TaskPriority
    let estimatedPomodoros: Int16
    let completedPomodoros: Int16
    let isFlagged: Bool
    let projectPath: String
    let dueDayOffset: Int
    let createdDayOffset: Int
    let completedDayOffset: Int?

    init(
        title: String,
        details: String,
        status: TaskStatus,
        priority: TaskPriority,
        estimatedPomodoros: Int16,
        completedPomodoros: Int16,
        isFlagged: Bool,
        projectPath: String,
        dueDayOffset: Int,
        createdDayOffset: Int,
        completedDayOffset: Int? = nil
    ) {
        self.title = title
        self.details = details
        self.status = status
        self.priority = priority
        self.estimatedPomodoros = estimatedPomodoros
        self.completedPomodoros = completedPomodoros
        self.isFlagged = isFlagged
        self.projectPath = projectPath
        self.dueDayOffset = dueDayOffset
        self.createdDayOffset = createdDayOffset
        self.completedDayOffset = completedDayOffset
    }
}

struct OverviewMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let systemImage: String
    let tint: Color
}

struct TaskCompletionChartPoint: Identifiable {
    let date: Date
    let completedTasks: Int
    let focusedMinutes: Int

    var id: Date { date }
}
