import SwiftUI
import SwiftData
import CoreData

/// Центральный контейнер собирает зависимости в одном месте.
/// Это учебный аналог composition root из архитектурных схем.
///
/// Почему это уже ближе к senior-уровню:
/// 1. Инициализация инфраструктуры сосредоточена в одном месте, а не размазана по view.
/// 2. Каждый слой получает только те зависимости, которые ему действительно нужны.
/// 3. У приложения есть одна точка, где можно включить in-memory режим, подменить store
///    на mock или добавить новый сервис без переписывания UI.
@MainActor
final class AppContainer {
    let coreDataStack: CoreDataStack
    let modelContainer: ModelContainer
    let taskStore: TaskStore
    let sessionStore: StudySessionStore
    let noteStore: NoteStore
    let dashboardViewModel: DashboardViewModel

    private let widgetSyncService: WidgetSyncService
    private let inMemory: Bool
    private let demoDataVersion = 2
    private let demoDataVersionKey = "studyDemo.demoDataVersion"

    init(inMemory: Bool = false) {
        self.inMemory = inMemory

        let widgetSyncService = WidgetSyncService()
        let coreDataStack = CoreDataStack(inMemory: inMemory)
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        let modelContainer = try! ModelContainer(
            for: StudySessionRecord.self,
            NoteRecord.self,
            configurations: modelConfiguration
        )

        self.coreDataStack = coreDataStack
        self.modelContainer = modelContainer
        self.widgetSyncService = widgetSyncService
        self.taskStore = TaskStore(
            viewContext: coreDataStack.container.viewContext,
            widgetSyncService: widgetSyncService
        )
        self.sessionStore = StudySessionStore(
            modelContext: modelContainer.mainContext
        )
        self.noteStore = NoteStore(
            modelContext: modelContainer.mainContext
        )
        self.dashboardViewModel = DashboardViewModel()

        bootstrapDemoDataIfNeeded()
        refreshSharedSnapshot()
    }

    func handleScenePhase(_ phase: ScenePhase) {
        // Обновляем shared snapshot, когда приложение уходит в background.
        // Так виджет всегда читает наиболее свежую сводку.
        if phase == .background || phase == .inactive {
            refreshSharedSnapshot()
        }
    }

    func refreshSharedSnapshot() {
        widgetSyncService.store(snapshot: taskStore.makeWidgetSnapshot())
    }

    private func bootstrapDemoDataIfNeeded() {
        let defaults = UserDefaults.standard
        let shouldResetDemoData = inMemory || defaults.integer(forKey: demoDataVersionKey) != demoDataVersion

        if shouldResetDemoData {
            taskStore.resetToDemoData()
            sessionStore.resetToDemoData(using: taskStore)
            noteStore.resetToDemoData(taskStore: taskStore)
            defaults.set(demoDataVersion, forKey: demoDataVersionKey)
            return
        }

        taskStore.ensureSeedDataIfNeeded()
        sessionStore.ensureSeedDataIfNeeded(using: taskStore)
        noteStore.ensureSeedDataIfNeeded(taskStore: taskStore)
    }
}
