import Foundation

#if canImport(ActivityKit)
import ActivityKit

struct FocusTimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let progress: Double
        let completedPomodoros: Int
        let totalPomodoros: Int
    }

    let taskTitle: String
    let projectName: String
}
#endif
