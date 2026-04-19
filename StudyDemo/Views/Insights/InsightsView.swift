import Charts
import SwiftUI

struct InsightsView: View {
    @EnvironmentObject private var taskStore: TaskStore
    @EnvironmentObject private var sessionStore: StudySessionStore
    @EnvironmentObject private var dashboardViewModel: DashboardViewModel
    @AppStorage(AppPreferenceKeys.weeklyGoal) private var weeklyGoal = 240.0
    @SceneStorage("insights.selectedProjectID") private var selectedProjectID = ""
    @StateObject private var viewModel = InsightsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Статистика выполнения")
                        .font(.largeTitle.bold())

                    ProgressView(
                        value: Double(viewModel.weeklyFocusMinutes),
                        total: max(weeklyGoal, 1)
                    ) {
                        Text("Фокус-минуты по завершённым задачам за 7 дней")
                    } currentValueLabel: {
                        Text("\(viewModel.weeklyFocusMinutes) / \(Int(weeklyGoal)) мин")
                    }

                    Text("График и прогресс ниже считаются по `TaskEntity.completedAt`: каждый закрытый task попадает в день своего завершения.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Picker("Проект", selection: selectedProjectBinding) {
                        Text("Все проекты").tag(String?.none)

                        ForEach(taskStore.allProjects(), id: \.id) { project in
                            Text(project.title).tag(Optional(project.id.uuidString))
                        }
                    }
                    .pickerStyle(.menu)
                }

                Chart(viewModel.chartPoints) { point in
                    BarMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Completed", point.completedTasks)
                    )
                    .foregroundStyle(.blue.gradient)

                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Focused Minutes", point.focusedMinutes)
                    )
                    .foregroundStyle(.orange)
                    .symbol(.circle)
                }
                .frame(height: 260)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }

                HStack(spacing: 12) {
                    InsightSummaryCard(
                        title: "Закрыто задач",
                        value: "\(viewModel.completedTasksCount)",
                        tint: .blue
                    )
                    InsightSummaryCard(
                        title: "Фокус-минуты",
                        value: "\(viewModel.weeklyFocusMinutes)",
                        tint: .orange
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Рекомендации после sync")
                            .font(.title3.bold())

                        Spacer()

                        Button("Обновить") {
                            Task {
                                await dashboardViewModel.refresh(taskStore: taskStore, sessionStore: sessionStore)
                            }
                        }
                    }

                    if dashboardViewModel.isSyncing {
                        ProgressView("Считаем рекомендации", value: dashboardViewModel.syncProgress)
                    } else {
                        ForEach(dashboardViewModel.recommendations, id: \.self) { item in
                            Label(item, systemImage: "sparkles")
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                }

                DisclosureGroup("Как читать эти графики") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("BarMark показывает, сколько задач было реально закрыто в конкретный день.")
                        Text("LineMark показывает оценку фокус-времени: суммируем pomodoro-оценки у закрытых в этот день задач.")
                        Text("Picker сверху фильтрует статистику по проекту, так что можно проверить и общий прогресс, и отдельный project-slice.")
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
        }
        .task {
            refreshInsights()
            if dashboardViewModel.recommendations.isEmpty {
                await dashboardViewModel.refresh(taskStore: taskStore, sessionStore: sessionStore)
            }
        }
        .onChange(of: selectedProjectID) { _, _ in
            refreshInsights()
        }
        .onChange(of: taskStore.changeToken) { _, _ in
            refreshInsights()
        }
        .navigationTitle("Insights")
    }

    private var selectedProjectBinding: Binding<String?> {
        Binding(
            get: { selectedProjectID.isEmpty ? nil : selectedProjectID },
            set: { selectedProjectID = $0 ?? "" }
        )
    }

    private func refreshInsights() {
        viewModel.refresh(taskStore: taskStore, selectedProjectID: selectedProjectID)
    }
}

private struct InsightSummaryCard: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
