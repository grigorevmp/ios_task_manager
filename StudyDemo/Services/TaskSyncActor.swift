import Foundation

struct TaskSyncPayload: Sendable {
    let title: String
    let status: TaskStatus
    let priority: TaskPriority
    let isFlagged: Bool
    let remainingPomodoros: Int
}

struct SyncReport: Sendable {
    let recommendations: [String]
    let remoteTaskCount: Int
}

/// Actor сериализует доступ к состоянию "сервиса".
/// Это хороший способ показать Swift Concurrency на реальном объекте, а не на абстрактном примере.
actor TaskSyncActor {
    private var syncCounter = 0

    func sync(tasks: [TaskSyncPayload], weeklyFocusMinutes: Int) async -> SyncReport {
        syncCounter += 1

        // Имитируем сеть/долгую операцию.
        try? await Task.sleep(for: .milliseconds(500))

        let recommendations = await withTaskGroup(of: String?.self, returning: [String].self) { group in
            group.addTask {
                tasks
                    .filter { $0.isFlagged && $0.status != .done }
                    .sorted { $0.priority.rawValue > $1.priority.rawValue }
                    .first
                    .map { "Сначала закрой важную задачу: \($0.title)." }
            }

            group.addTask {
                if weeklyFocusMinutes < 180 {
                    return "Недельная цель по фокусу пока недобрана, запланируй ещё одну 25-минутную сессию."
                }
                return "Фокус-цель почти закрыта, можно переключиться на review-задачи."
            }

            group.addTask {
                tasks
                    .filter { $0.remainingPomodoros >= 3 }
                    .first
                    .map { "Разбей крупную задачу '\($0.title)' на подшаги, чтобы доска выглядела честнее." }
            }

            var result: [String] = []
            for await suggestion in group {
                if let suggestion {
                    result.append(suggestion)
                }
            }
            return result
        }

        return SyncReport(recommendations: recommendations, remoteTaskCount: tasks.count + syncCounter)
    }
}
