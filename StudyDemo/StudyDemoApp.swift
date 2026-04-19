import SwiftUI
import SwiftData

@main
struct StudyDemoApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(container.taskStore)
                .environmentObject(container.sessionStore)
                .environmentObject(container.noteStore)
                .environmentObject(container.dashboardViewModel)
                .modelContainer(container.modelContainer)
        }
        .onChange(of: scenePhase) { _, newPhase in
            Task { @MainActor in
                container.handleScenePhase(newPhase)
            }
        }
    }
}
