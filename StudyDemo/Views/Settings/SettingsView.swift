import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section("AppStorage") {
                AppStorageView()
            }

            Section("SceneStorage") {
                Text("SceneStorage используется в split-view экране: заметка и выбранный sidebar-элемент переживают пересоздание сцены.")
                    .foregroundStyle(.secondary)
            }

            Section("Архитектура") {
                DisclosureGroup("Почему проект разделён на App / Domain / Data / Services / Views") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("App: composition root, где собираются зависимости.")
                        Text("Domain: enum и модели, которые описывают поведение.")
                        Text("Data: Core Data для задач/проектов и SwiftData для сессий/заметок.")
                        Text("Services: concurrency actor, виджет-синхронизация и live activity.")
                        Text("Views: изолированный UI-слой с reusable-компонентами и отдельными учебными табами.")
                    }
                    .padding(.top, 6)
                }
            }
        }
        .navigationTitle("Settings & Theory")
    }
}
