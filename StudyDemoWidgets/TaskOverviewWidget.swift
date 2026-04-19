import SwiftUI
import WidgetKit

struct TaskWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: TaskWidgetSnapshot
}

struct TaskWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> TaskWidgetEntry {
        TaskWidgetEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskWidgetEntry) -> Void) {
        completion(TaskWidgetEntry(date: .now, snapshot: loadSnapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskWidgetEntry>) -> Void) {
        let entry = TaskWidgetEntry(date: .now, snapshot: loadSnapshot())
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 20, to: .now) ?? .now.addingTimeInterval(1200)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func loadSnapshot() -> TaskWidgetSnapshot {
        let defaults = UserDefaults(suiteName: SharedAppGroup.identifier)
        guard
            let data = defaults?.data(forKey: SharedAppGroup.snapshotKey),
            let snapshot = try? JSONDecoder().decode(TaskWidgetSnapshot.self, from: data)
        else {
            return .placeholder
        }
        return snapshot
    }
}

struct TaskOverviewWidget: Widget {
    let kind = "TaskOverviewWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskWidgetProvider()) { entry in
            VStack(alignment: .leading, spacing: 12) {
                Text("Study Demo")
                    .font(.headline)

                Text("\(entry.snapshot.completedTasks)/\(entry.snapshot.totalTasks)")
                    .font(.system(size: 30, weight: .bold, design: .rounded))

                ProgressView(value: entry.snapshot.completionRate)

                Text("Следующая: \(entry.snapshot.nextTaskTitle)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(entry.snapshot.lastUpdated, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Task Overview")
        .description("Показывает прогресс учебного task manager.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
