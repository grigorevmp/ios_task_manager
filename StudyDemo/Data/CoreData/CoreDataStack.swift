import CoreData

/// CoreDataStack собран вручную, без `.xcdatamodeld`.
/// Это полезно как учебный пример: видно, что Core Data хранит именно метаданные модели.
final class CoreDataStack {
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let model = Self.makeModel()
        container = NSPersistentContainer(name: "StudyDemoModel", managedObjectModel: model)

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        // Автоматическая lightweight migration нужна, чтобы при развитии учебного проекта
        // можно было добавлять новые optional-поля и сущности без ручной миграции на каждом шаге.
        container.persistentStoreDescriptions.first?.shouldMigrateStoreAutomatically = true
        container.persistentStoreDescriptions.first?.shouldInferMappingModelAutomatically = true

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Failed to load Core Data store: \(error)")
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    func saveIfNeeded() {
        guard container.viewContext.hasChanges else { return }
        try? container.viewContext.save()
    }

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let taskEntity = NSEntityDescription()
        taskEntity.name = "TaskEntity"
        taskEntity.managedObjectClassName = NSStringFromClass(TaskEntity.self)

        let projectEntity = NSEntityDescription()
        projectEntity.name = "ProjectEntity"
        projectEntity.managedObjectClassName = NSStringFromClass(ProjectEntity.self)

        let taskProperties: [NSPropertyDescription] = [
            makeAttribute(name: "id", type: .UUIDAttributeType),
            makeAttribute(name: "title", type: .stringAttributeType),
            makeAttribute(name: "detailsText", type: .stringAttributeType),
            makeAttribute(name: "createdAt", type: .dateAttributeType),
            makeAttribute(name: "dueDate", type: .dateAttributeType, isOptional: true),
            // `completedAt` нужен для построения реальной аналитики по дням:
            // графики теперь считают не "моковые study sessions", а фактические закрытия задач.
            makeAttribute(name: "completedAt", type: .dateAttributeType, isOptional: true),
            makeAttribute(name: "priorityRaw", type: .integer16AttributeType),
            makeAttribute(name: "statusRaw", type: .stringAttributeType),
            makeAttribute(name: "estimatedPomodoros", type: .integer16AttributeType),
            makeAttribute(name: "completedPomodoros", type: .integer16AttributeType),
            makeAttribute(name: "isFlagged", type: .booleanAttributeType),
            makeAttribute(name: "projectPath", type: .stringAttributeType),
            makeAttribute(name: "columnOrder", type: .doubleAttributeType),
        ]

        let projectProperties: [NSPropertyDescription] = [
            makeAttribute(name: "id", type: .UUIDAttributeType),
            makeAttribute(name: "title", type: .stringAttributeType),
            makeAttribute(name: "detailsText", type: .stringAttributeType),
            makeAttribute(name: "iconName", type: .stringAttributeType),
            makeAttribute(name: "colorName", type: .stringAttributeType),
            makeAttribute(name: "fullPath", type: .stringAttributeType),
            makeAttribute(name: "createdAt", type: .dateAttributeType),
            makeAttribute(name: "sortOrder", type: .doubleAttributeType),
        ]

        let projectRelationship = NSRelationshipDescription()
        projectRelationship.name = "project"
        projectRelationship.destinationEntity = projectEntity
        projectRelationship.minCount = 0
        projectRelationship.maxCount = 1
        projectRelationship.deleteRule = .nullifyDeleteRule

        let tasksRelationship = NSRelationshipDescription()
        tasksRelationship.name = "tasks"
        tasksRelationship.destinationEntity = taskEntity
        tasksRelationship.minCount = 0
        tasksRelationship.maxCount = 0
        tasksRelationship.deleteRule = .nullifyDeleteRule

        projectRelationship.inverseRelationship = tasksRelationship
        tasksRelationship.inverseRelationship = projectRelationship

        taskEntity.properties = taskProperties + [projectRelationship]
        projectEntity.properties = projectProperties + [tasksRelationship]

        model.entities = [taskEntity, projectEntity]
        return model
    }

    private static func makeAttribute(
        name: String,
        type: NSAttributeType,
        isOptional: Bool = false
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = isOptional
        return attribute
    }
}
