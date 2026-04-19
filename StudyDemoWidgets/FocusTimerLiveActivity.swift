#if canImport(ActivityKit)
import ActivityKit
import SwiftUI
import WidgetKit

struct FocusTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusTimerAttributes.self) { context in
            VStack(alignment: .leading, spacing: 10) {
                Text(context.attributes.taskTitle)
                    .font(.headline)

                Text(context.attributes.projectName)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ProgressView(value: context.state.progress)

                Text("\(context.state.completedPomodoros) из \(context.state.totalPomodoros) pomodoro")
                    .font(.caption)
            }
            .padding()
            .activityBackgroundTint(.orange.opacity(0.16))
            .activitySystemActionForegroundColor(.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "timer")
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading) {
                        Text(context.attributes.taskTitle)
                        ProgressView(value: context.state.progress)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.completedPomodoros)/\(context.state.totalPomodoros)")
                        .monospacedDigit()
                }
            } compactLeading: {
                Image(systemName: "timer")
            } compactTrailing: {
                Text("\(Int(context.state.progress * 100))%")
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "timer")
            }
        }
    }
}
#endif
