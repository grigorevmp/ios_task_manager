import SwiftUI

struct AppStorageView: View {
    @AppStorage(AppPreferenceKeys.tintChoice) private var tintChoiceRaw = AppTintChoice.sunrise.rawValue
    @AppStorage(AppPreferenceKeys.boardDensity) private var boardDensity = 1.0
    @AppStorage(AppPreferenceKeys.showsCompleted) private var showsCompleted = true
    @AppStorage(AppPreferenceKeys.weeklyGoal) private var weeklyGoal = 240.0

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Picker("Tint", selection: $tintChoiceRaw) {
                ForEach(AppTintChoice.allCases) { choice in
                    Text(choice.title).tag(choice.rawValue)
                }
            }

            Toggle("Показывать завершённые задачи", isOn: $showsCompleted)

            VStack(alignment: .leading, spacing: 8) {
                Text("Плотность доски: \(boardDensity.formatted(.number.precision(.fractionLength(1))))")
                Slider(value: $boardDensity, in: 1...1.8)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Недельная цель: \(Int(weeklyGoal)) минут")
                Slider(value: $weeklyGoal, in: 120...480, step: 30)
            }

            Text("Все значения выше хранятся через AppStorage и автоматически переживают перезапуск приложения.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
