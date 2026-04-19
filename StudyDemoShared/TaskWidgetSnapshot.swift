import Foundation

struct TaskWidgetSnapshot: Codable, Sendable {
    let totalTasks: Int
    let completedTasks: Int
    let focusMinutesThisWeek: Int
    let nextTaskTitle: String
    let lastUpdated: Date

    var completionRate: Double {
        guard totalTasks > 0 else { return 0 }
        return Double(completedTasks) / Double(totalTasks)
    }

    static let placeholder = TaskWidgetSnapshot(
        totalTasks: 8,
        completedTasks: 3,
        focusMinutesThisWeek: 210,
        nextTaskTitle: "Собрать Dashboard на SwiftUI",
        lastUpdated: .now
    )
}
