import Foundation
import SwiftData

/// SwiftData используем параллельно с Core Data.
/// Так можно показать, как выглядят обе технологии в одном учебном проекте.
@Model
final class StudySessionRecord {
    var date: Date
    var focusedMinutes: Int
    var completedTasks: Int
    var interruptions: Int

    init(date: Date, focusedMinutes: Int, completedTasks: Int, interruptions: Int) {
        self.date = date
        self.focusedMinutes = focusedMinutes
        self.completedTasks = completedTasks
        self.interruptions = interruptions
    }
}
