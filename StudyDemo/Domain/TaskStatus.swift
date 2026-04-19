import SwiftUI

enum TaskStatus: String, CaseIterable, Identifiable {
    case backlog
    case today
    case inProgress
    case review
    case done

    var id: String { rawValue }

    var title: String {
        switch self {
        case .backlog: "Backlog"
        case .today: "Today"
        case .inProgress: "In Progress"
        case .review: "Review"
        case .done: "Done"
        }
    }

    var systemImage: String {
        switch self {
        case .backlog: "tray"
        case .today: "calendar"
        case .inProgress: "timer"
        case .review: "checklist"
        case .done: "checkmark.seal.fill"
        }
    }

    var tint: Color {
        switch self {
        case .backlog: .gray
        case .today: .indigo
        case .inProgress: .orange
        case .review: .mint
        case .done: .green
        }
    }

    static let boardOrder: [TaskStatus] = [.backlog, .today, .inProgress, .review, .done]

    func shifted(by delta: Int) -> TaskStatus? {
        guard let index = Self.boardOrder.firstIndex(of: self) else { return nil }
        let newIndex = index + delta
        guard Self.boardOrder.indices.contains(newIndex) else { return nil }
        return Self.boardOrder[newIndex]
    }
}
