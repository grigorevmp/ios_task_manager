# StudyDemo

Учебный `SwiftUI`-проект в формате task manager.

Проект собран так, чтобы на одном кодбейсе можно было изучать:

- архитектуру слоёв `App / Domain / Data / Services / Views`
- `TabView`, `NavigationStack`, `NavigationSplitView`
- `List`, `OutlineGroup`, `DisclosureGroup`
- `Grid`, `LazyVGrid`, канбан-представление
- жесты, анимации и переходы
- `ProgressView`
- `Swift Charts`
- `Core Data`
- `SwiftData`
- наблюдаемое состояние
- `AppStorage` и `SceneStorage`
- `WidgetKit`
- `Live Activities`
- `Swift Concurrency` через `Task`, `async/await`, `actor`, `TaskGroup`

## С чего читать проект

1. [StudyDemoApp.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/StudyDemoApp.swift>)
2. [AppContainer.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/App/AppContainer.swift>)
3. [ContentView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/ContentView.swift>)
4. [PlannerWorkspaceView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Views/Dashboard/PlannerWorkspaceView.swift>)
5. [TaskStore.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Data/Repositories/TaskStore.swift>)
6. [StudySessionStore.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Data/Repositories/StudySessionStore.swift>)
7. [TaskSyncActor.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Services/TaskSyncActor.swift>)
8. [KanbanBoardView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Views/Board/KanbanBoardView.swift>)
9. [InsightsView.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemo/Views/Insights/InsightsView.swift>)
10. [StudyDemoWidgetsBundle.swift](</Volumes/Samsung SSD/ios/StudyDemo/StudyDemoWidgets/StudyDemoWidgetsBundle.swift>)

## Дополнительные материалы

- [FEATURE_CHECKLIST.md](/Volumes/Samsung SSD/ios/StudyDemo/FEATURE_CHECKLIST.md)
- [MIDDLE_LEVEL_GUIDE.md](/Volumes/Samsung SSD/ios/StudyDemo/MIDDLE_LEVEL_GUIDE.md)
