import SwiftUI

struct SceneStorageView: View {
    @Binding var note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Этот блок оставлен внутри рабочего места как локальная scratchpad-зона.
            // Он не пытается быть полноценной системой заметок: его задача показать,
            // как `SceneStorage` хранит временный контекст отдельно для каждого окна/сцены,
            // что полезно для iPad-style multitasking и рабочих сценариев с несколькими окнами.
            Text("Быстрые заметки сцены")
                .font(.headline)

            TextEditor(text: $note)
                .frame(minHeight: 140)
                .padding(8)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .scrollContentBackground(.hidden)

            Text("Этот текст живёт внутри активной сцены. Если открыть несколько окон на iPad/macOS, у каждого окна будет свой экземпляр значения.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .animation(.snappy(duration: 0.25), value: note)
    }
}
