import SwiftUI

/// Превью специально построено на стандартном `AttributedString(markdown:)`,
/// чтобы не прятать магию в стороннюю библиотеку.
/// Это делает пример более честным для обучения: видно, что базовый markdown preview
/// можно собрать штатными средствами Apple.
struct MarkdownPreviewView: View {
    let markdownText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let attributed = try? AttributedString(
                markdown: markdownText,
                options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .full)
            ) {
                Text(attributed)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ContentUnavailableView(
                    "Markdown не распознан",
                    systemImage: "exclamationmark.bubble",
                    description: Text("Проверь синтаксис заметки или убери повреждённый блок.")
                )
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
