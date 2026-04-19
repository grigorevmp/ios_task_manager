import CoreData
import SwiftUI

/// TaskEntity отвечает только за persistence-представление задачи.
/// Бизнес-смысловые вычисления вынесены в extension ниже, чтобы Core Data свойства
/// не смешивались с derived-logic в одной куче.
@objc(TaskEntity)
public final class TaskEntity: NSManagedObject, Identifiable {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TaskEntity> {
        NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var detailsText: String
    @NSManaged public var createdAt: Date
    @NSManaged public var dueDate: Date?
    @NSManaged public var completedAt: Date?
    @NSManaged public var priorityRaw: Int16
    @NSManaged public var statusRaw: String
    @NSManaged public var estimatedPomodoros: Int16
    @NSManaged public var completedPomodoros: Int16
    @NSManaged public var isFlagged: Bool
    @NSManaged public var projectPath: String
    @NSManaged public var columnOrder: Double
    @NSManaged public var project: ProjectEntity?
}

extension TaskEntity {
    var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityRaw) ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }

    var status: TaskStatus {
        get { TaskStatus(rawValue: statusRaw) ?? .backlog }
        set { statusRaw = newValue.rawValue }
    }

    var progress: Double {
        guard estimatedPomodoros > 0 else { return 0 }
        return min(Double(completedPomodoros) / Double(estimatedPomodoros), 1)
    }

    var subtitle: String {
        "\(resolvedProjectPath) • \(priority.title)"
    }

    var resolvedProjectPath: String {
        project?.fullPath ?? projectPath
    }

    var resolvedProjectTitle: String {
        project?.title ?? resolvedProjectPath.components(separatedBy: "/").last ?? resolvedProjectPath
    }
}
