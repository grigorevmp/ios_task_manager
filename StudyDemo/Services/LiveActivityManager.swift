#if canImport(ActivityKit) && os(iOS)
import ActivityKit
import Foundation

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var currentActivity: Activity<FocusTimerAttributes>?

    private init() {}

    func start(for task: TaskEntity) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        if let currentActivity {
            await end(activity: currentActivity)
        }

        let attributes = FocusTimerAttributes(
            taskTitle: task.title,
            projectName: task.projectPath
        )
        let content = ActivityContent(
            state: FocusTimerAttributes.ContentState(
                progress: task.progress,
                completedPomodoros: Int(task.completedPomodoros),
                totalPomodoros: Int(task.estimatedPomodoros)
            ),
            staleDate: .now.addingTimeInterval(60 * 30)
        )

        currentActivity = try? Activity.request(
            attributes: attributes,
            content: content,
            pushType: nil
        )
    }

    func update(for task: TaskEntity) async {
        guard let currentActivity else { return }

        let content = ActivityContent(
            state: FocusTimerAttributes.ContentState(
                progress: task.progress,
                completedPomodoros: Int(task.completedPomodoros),
                totalPomodoros: Int(task.estimatedPomodoros)
            ),
            staleDate: .now.addingTimeInterval(60 * 30)
        )

        await currentActivity.update(content)
    }

    func endCurrentActivity() async {
        guard let currentActivity else { return }
        await end(activity: currentActivity)
        self.currentActivity = nil
    }

    private func end(activity: Activity<FocusTimerAttributes>) async {
        let finalState = activity.content.state
        await activity.end(
            ActivityContent(state: finalState, staleDate: nil),
            dismissalPolicy: .immediate
        )
    }
}
#endif
