import SwiftUI

struct ContentView: View {
    @SceneStorage("root.selectedTab") private var selectedTabRaw = RootTab.workspace.rawValue
    @AppStorage(AppPreferenceKeys.tintChoice) private var tintChoiceRaw = AppTintChoice.sunrise.rawValue

    var body: some View {
        // Верхний TabView теперь разбит по учебным сценариям.
        // Отдельные табы удобны и пользователю, и для чтения кода:
        // каждая вкладка демонстрирует свой набор API и ответственность.
        TabView(selection: selectedTabBinding) {
            PlannerWorkspaceView()
                .tabItem {
                    Label("Рабочее место", systemImage: "list.bullet.rectangle.portrait")
                }
                .tag(RootTab.workspace)

            ProjectsHomeView()
            .tabItem {
                Label("Проекты", systemImage: "folder.badge.gearshape")
            }
            .tag(RootTab.projects)

            NotesHomeView()
            .tabItem {
                Label("Заметки", systemImage: "note.text")
            }
            .tag(RootTab.notes)

            NavigationStack {
                KanbanBoardView()
            }
            .tabItem {
                Label("Канбан", systemImage: "square.grid.3x2.fill")
            }
            .tag(RootTab.board)

            NavigationStack {
                InsightsView()
            }
            .tabItem {
                Label("Графики", systemImage: "chart.xyaxis.line")
            }
            .tag(RootTab.insights)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Хранилище", systemImage: "externaldrive.fill.badge.person.crop")
            }
            .tag(RootTab.settings)
        }
        .tint(AppTintChoice(rawValue: tintChoiceRaw)?.color ?? .orange)
    }

    private var selectedTabBinding: Binding<RootTab> {
        Binding(
            get: { RootTab(rawValue: selectedTabRaw) ?? .workspace },
            set: { selectedTabRaw = $0.rawValue }
        )
    }
}
