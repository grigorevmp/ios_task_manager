import Foundation
import SwiftData

/// NoteRecord живёт в SwiftData, потому что заметки в учебном приложении хорошо показывают
/// "современный" declarative-подход к локальному хранению:
/// - простая модель
/// - нет ручного NSManagedObject
/// - удобно строить editor/preview сценарии
///
/// При этом мы всё равно связываем заметку с проектом или задачей через id,
/// чтобы продемонстрировать интеграцию между разными persistence-слоями.
@Model
final class NoteRecord {
    var title: String
    var markdownText: String
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
    var projectID: UUID?
    var taskID: UUID?

    init(
        title: String,
        markdownText: String,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isPinned: Bool = false,
        projectID: UUID? = nil,
        taskID: UUID? = nil
    ) {
        self.title = title
        self.markdownText = markdownText
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPinned = isPinned
        self.projectID = projectID
        self.taskID = taskID
    }
}
