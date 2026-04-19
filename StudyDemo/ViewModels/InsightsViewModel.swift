import Combine
import Foundation

/// InsightsViewModel изолирует аналитические вычисления от `InsightsView`.
/// Благодаря этому экран читает уже готовые значения, а логика выборки
/// и фильтрации по проекту остаётся в одном месте.
@MainActor
final class InsightsViewModel: ObservableObject {
    @Published private(set) var chartPoints: [TaskCompletionChartPoint] = []
    @Published private(set) var weeklyFocusMinutes = 0
    @Published private(set) var completedTasksCount = 0
    @Published private(set) var selectedProject: ProjectEntity?

    func refresh(taskStore: TaskStore, selectedProjectID: String) {
        let project = taskStore.project(idString: selectedProjectID)
        selectedProject = project
        chartPoints = taskStore.completionChartPoints(days: 7, project: project)
        weeklyFocusMinutes = taskStore.completedFocusMinutes(days: 7, project: project)
        completedTasksCount = taskStore.completedTasksCount(days: 7, project: project)
    }
}
