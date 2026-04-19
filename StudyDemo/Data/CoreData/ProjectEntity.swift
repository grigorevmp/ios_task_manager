import CoreData
import SwiftUI

/// Отдельная сущность проекта нужна не только ради "папки с названием".
/// Она позволяет:
/// 1. хранить метаданные проекта отдельно от задач
/// 2. привязывать много задач к одному проекту
/// 3. строить отдельный Projects tab без ручного парсинга строк
/// 4. показывать senior-подход: проект и задача моделируются разными агрегатами
@objc(ProjectEntity)
public final class ProjectEntity: NSManagedObject, Identifiable {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProjectEntity> {
        NSFetchRequest<ProjectEntity>(entityName: "ProjectEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var detailsText: String
    @NSManaged public var iconName: String
    @NSManaged public var colorName: String
    @NSManaged public var fullPath: String
    @NSManaged public var createdAt: Date
    @NSManaged public var sortOrder: Double
    @NSManaged public var tasks: NSSet?
}

extension ProjectEntity {
    var taskArray: [TaskEntity] {
        let set = tasks as? Set<TaskEntity> ?? []
        return set.sorted { lhs, rhs in
            if lhs.status == rhs.status {
                return lhs.columnOrder < rhs.columnOrder
            }
            return lhs.createdAt < rhs.createdAt
        }
    }

    var openTasksCount: Int {
        taskArray.filter { $0.status != .done }.count
    }

    var completionRatio: Double {
        let tasks = taskArray
        guard !tasks.isEmpty else { return 0 }
        return Double(tasks.filter { $0.status == .done }.count) / Double(tasks.count)
    }

    var tintColor: Color {
        switch colorName {
        case "orange": .orange
        case "blue": .blue
        case "green": .green
        case "mint": .mint
        case "pink": .pink
        default: .gray
        }
    }
}
