import Combine
import Foundation
import SwiftData

@MainActor
final class StudySessionStore: ObservableObject {
    private let modelContext: ModelContext
    @Published private(set) var changeToken = 0

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func ensureSeedDataIfNeeded(using taskStore: TaskStore) {
        var descriptor = FetchDescriptor<StudySessionRecord>()
        descriptor.fetchLimit = 1

        guard (try? modelContext.fetchCount(descriptor)) == 0 else { return }
        seedDemoSessions(using: taskStore)
    }

    func resetToDemoData(using taskStore: TaskStore) {
        let descriptor = FetchDescriptor<StudySessionRecord>()
        let records = (try? modelContext.fetch(descriptor)) ?? []

        for record in records {
            modelContext.delete(record)
        }

        try? modelContext.save()
        changeToken += 1
        seedDemoSessions(using: taskStore)
    }

    func recentSessions(limit: Int = 7) -> [StudySessionRecord] {
        _ = changeToken

        let descriptor = FetchDescriptor<StudySessionRecord>()

        return ((try? modelContext.fetch(descriptor)) ?? [])
            .sorted { $0.date > $1.date }
            .prefix(limit)
            .map { $0 }
    }

    func recordSession(from task: TaskEntity) {
        let record = StudySessionRecord(
            date: .now,
            focusedMinutes: Int(max(task.estimatedPomodoros, 1)) * 25,
            completedTasks: task.status == .done ? 1 : 0,
            interruptions: task.priority == .critical ? 0 : Int.random(in: 0...2)
        )

        modelContext.insert(record)
        try? modelContext.save()
        changeToken += 1
    }

    func weeklyFocusedMinutes() -> Int {
        recentSessions().reduce(0) { $0 + $1.focusedMinutes }
    }

    func chartPoints() -> [StudyChartPoint] {
        recentSessions()
            .reversed()
            .map {
                StudyChartPoint(
                    date: $0.date,
                    focusedMinutes: $0.focusedMinutes,
                    completedTasks: $0.completedTasks
                )
            }
    }

    private func seedDemoSessions(using taskStore: TaskStore) {
        // SwiftData-сессии остаются в проекте как отдельный пример persistence,
        // но seed теперь строится из тех же completed tasks, что и графики.
        // Так оба storage-слоя показывают одну и ту же учебную историю пользователя.
        for point in taskStore.completionChartPoints(days: 7) {
            let record = StudySessionRecord(
                date: point.date,
                focusedMinutes: max(point.focusedMinutes, point.completedTasks * 25),
                completedTasks: point.completedTasks,
                interruptions: max(0, 3 - point.completedTasks)
            )
            modelContext.insert(record)
        }

        try? modelContext.save()
        changeToken += 1
    }
}

struct StudyChartPoint: Identifiable {
    let id = UUID()
    let date: Date
    let focusedMinutes: Int
    let completedTasks: Int
}
