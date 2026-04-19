import SwiftUI

enum AppPreferenceKeys {
    static let tintChoice = "settings.tintChoice"
    static let boardDensity = "settings.boardDensity"
    static let showsCompleted = "settings.showsCompleted"
    static let weeklyGoal = "settings.weeklyGoal"
}

enum AppTintChoice: String, CaseIterable, Identifiable {
    case sunrise
    case forest
    case ocean

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sunrise: "Sunrise"
        case .forest: "Forest"
        case .ocean: "Ocean"
        }
    }

    var color: Color {
        switch self {
        case .sunrise: .orange
        case .forest: .green
        case .ocean: .blue
        }
    }
}
