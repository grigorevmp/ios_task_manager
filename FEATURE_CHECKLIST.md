# Проверка По Твоему Чеклисту

Ниже прямое сопоставление твоего запроса и того, где это реализовано.

## 1. Архитектура

Статус: есть

- `App` слой: [AppContainer.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/App/AppContainer.swift>)
- `Domain` слой: [NavigationModels.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Domain/NavigationModels.swift>), [TaskStatus.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Domain/TaskStatus.swift>), [TaskPriority.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Domain/TaskPriority.swift>)
- `Data` слой: [CoreDataStack.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Data/CoreData/CoreDataStack.swift>), [TaskStore.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Data/Repositories/TaskStore.swift>), [StudySessionStore.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Data/Repositories/StudySessionStore.swift>)
- `Services` слой: [TaskSyncActor.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Services/TaskSyncActor.swift>), [WidgetSyncService.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Services/WidgetSyncService.swift>), [LiveActivityManager.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Services/LiveActivityManager.swift>)
- `Views` слой: папка [Views](/Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Views)

## 2. Многопоточность / конкурентность

Статус: есть

- `actor`: [TaskSyncActor.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Services/TaskSyncActor.swift>)
- `Task`, `async/await`: [DashboardViewModel.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Services/DashboardViewModel.swift>)
- `TaskGroup`: [TaskSyncActor.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Services/TaskSyncActor.swift>)
- обновление `Live Activity` через async вызовы: [LiveActivityManager.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Services/LiveActivityManager.swift>)

## 3. Наблюдаемые объекты

Статус: есть

- `ObservableObject` + `@Published`: [TaskStore.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Data/Repositories/TaskStore.swift>), [StudySessionStore.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Data/Repositories/StudySessionStore.swift>), [DashboardViewModel.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Services/DashboardViewModel.swift>)

Примечание:

- это закрывает твой пункт про observable objects
- сейчас сделано через `ObservableObject`, а не через `@Observable`
- причина практическая: в локальной автоматической проверке `swift-plugin-server` ронял macro pipeline

## 4. AppStorage и SceneStorage

Статус: есть

- `AppStorage`: [AppStorageView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Views/Storage/AppStorageView.swift>), [ContentView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/ContentView.swift>), [InsightsView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Views/Insights/InsightsView.swift>)
- `SceneStorage`: [PlannerWorkspaceView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Views/Dashboard/PlannerWorkspaceView.swift>), [SceneStorageView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Views/Storage/SceneStorageView.swift>)

## 5. Navigation stack, split view и tabview

Статус: есть

- `TabView`: [ContentView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/ContentView.swift>)
- `NavigationStack`: [ContentView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/ContentView.swift>)
- `NavigationSplitView`: [PlannerWorkspaceView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Views/Dashboard/PlannerWorkspaceView.swift>)

## 6. List, Outline, DisclosureGroup

Статус: есть

- `List`: [TaskListView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Views/Dashboard/TaskListView.swift>), [PlannerWorkspaceView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Views/Dashboard/PlannerWorkspaceView.swift>)
- `OutlineGroup`: [PlannerWorkspaceView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Views/Dashboard/PlannerWorkspaceView.swift>)
- `DisclosureGroup`: [TaskDetailView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Views/Dashboard/TaskDetailView.swift>), [InsightsView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Views/Insights/InsightsView.swift>), [SettingsView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Views/Settings/SettingsView.swift>)

## 7. Различные сетки, канбан, жесты

Статус: есть

- `Grid`: [KanbanBoardView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Views/Board/KanbanBoardView.swift>), [TaskDetailView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Views/Dashboard/TaskDetailView.swift>)
- `LazyVGrid`: [KanbanBoardView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Views/Board/KanbanBoardView.swift>)
- жесты: [TaskCardView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Views/Components/TaskCardView.swift>)
- канбан-колонки: [KanbanBoardView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Views/Board/KanbanBoardView.swift>)

## 8. Анимации и переходы

Статус: есть

- `withAnimation`: [TaskStore.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Data/Repositories/TaskStore.swift>), [TaskDetailView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Views/Dashboard/TaskDetailView.swift>), [TaskCardView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Views/Components/TaskCardView.swift>)
- `.transition(...)`: [TaskCardView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Views/Components/TaskCardView.swift>), [InsightsView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Views/Insights/InsightsView.swift>)

## 9. ProgressView

Статус: есть

- [PlannerWorkspaceView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Views/Dashboard/PlannerWorkspaceView.swift>)
- [TaskListView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Views/Dashboard/TaskListView.swift>)
- [TaskDetailView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Views/Dashboard/TaskDetailView.swift>)
- [InsightsView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Views/Insights/InsightsView.swift>)
- [TaskOverviewWidget.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemoWidgets/TaskOverviewWidget.swift>)
- [FocusTimerLiveActivity.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemoWidgets/FocusTimerLiveActivity.swift>)

## 10. Графики через SwiftUI Charts

Статус: есть

- [InsightsView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Views/Insights/InsightsView.swift>)

## 11. Core Data и SwiftData

Статус: есть

- `Core Data`: [CoreDataStack.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Data/CoreData/CoreDataStack.swift>), [TaskEntity.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Data/CoreData/TaskEntity.swift>), [TaskStore.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Data/Repositories/TaskStore.swift>)
- `SwiftData`: [StudySessionRecord.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Data/SwiftData/StudySessionRecord.swift>), [StudySessionStore.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Data/Repositories/StudySessionStore.swift>)

## 12. WidgetKit

Статус: есть

- target: [StudyDemoWidgetsBundle.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemoWidgets/StudyDemoWidgetsBundle.swift>)
- widget: [TaskOverviewWidget.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemoWidgets/TaskOverviewWidget.swift>)
- shared model: [TaskWidgetSnapshot.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemoShared/TaskWidgetSnapshot.swift>)

## 13. Live Activities

Статус: есть

- activity manager: [LiveActivityManager.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Services/LiveActivityManager.swift>)
- shared attributes: [FocusTimerAttributes.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemoShared/FocusTimerAttributes.swift>)
- UI для activity: [FocusTimerLiveActivity.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemoWidgets/FocusTimerLiveActivity.swift>)

## 14. Комментарии, чтобы код было понятно читать

Статус: есть, но можно сделать ещё глубже

Что уже есть:

- комментарии в архитектурных и data/service-файлах
- поясняющие тексты прямо в UI
- демонстрационные `DisclosureGroup`

Что ещё можно усилить:

- добавить длинные комментарии “почему именно так” в каждом основном файле
- сделать отдельные markdown-конспекты по слоям
- добавить учебные задания и вопросы на самопроверку

## Итог

По функциональному чеклисту твой запрос закрыт.

По учебной глубине проект уже хороший для `junior+ / early middle`, но до полноценного `middle study pack` логично добавить:

- маршрут чтения проекта
- практические задания
- секцию “слабые места и trade-offs”
- секцию “как переписать это по-другому”
