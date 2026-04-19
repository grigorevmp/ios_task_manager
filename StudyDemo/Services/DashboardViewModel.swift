import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var isSyncing = false
    @Published var syncProgress = 0.0
    @Published var lastSyncDescription = "Синхронизация ещё не запускалась"
    @Published var recommendations: [String] = []

    private let syncActor = TaskSyncActor()

    func refresh(taskStore: TaskStore, sessionStore: StudySessionStore) async {
        guard !isSyncing else { return }

        isSyncing = true
        syncProgress = 0.1

        let payload = taskStore.makeSyncPayload()
        let weeklyMinutes = sessionStore.weeklyFocusedMinutes()

        async let reportTask = syncActor.sync(tasks: payload, weeklyFocusMinutes: weeklyMinutes)

        // Прогресс тут учебный: UI не знает деталей сети, но всё равно умеет
        // показывать плавное состояние загрузки.
        for step in [0.25, 0.45, 0.7, 0.9] {
            try? await Task.sleep(for: .milliseconds(120))
            syncProgress = step
        }

        let report = await reportTask
        recommendations = report.recommendations
        lastSyncDescription = "Синхронизировано \(report.remoteTaskCount) записей • \(Date.now.formatted(date: .omitted, time: .shortened))"
        syncProgress = 1
        isSyncing = false
    }
}
