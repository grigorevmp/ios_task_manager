import SwiftUI

enum TaskPriority: Int16, CaseIterable, Identifiable {
    case low = 0
    case medium = 1
    case high = 2
    case critical = 3

    var id: Int16 { rawValue }

    var title: String {
        switch self {
        case .low: "Низкий"
        case .medium: "Средний"
        case .high: "Высокий"
        case .critical: "Критичный"
        }
    }

    var color: Color {
        switch self {
        case .low: .green
        case .medium: .blue
        case .high: .orange
        case .critical: .red
        }
    }
}
