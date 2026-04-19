import SwiftUI

enum RootTab: String, Hashable {
    case workspace
    case projects
    case notes
    case board
    case insights
    case settings
}

/// SidebarSelection нарочно сделан enum без динамики.
/// Для учебного проекта так проще увидеть, как selection связывается со списком и фильтрацией.
enum SidebarSelection: String, CaseIterable, Identifiable {
    case inbox
    case today
    case flagged
    case inProgress
    case done
    case projectSwiftUI
    case projectData
    case projectWellbeing
    case projectResearch

    var id: String { rawValue }

    var title: String {
        switch self {
        case .inbox: "Входящие"
        case .today: "На сегодня"
        case .flagged: "Важное"
        case .inProgress: "В работе"
        case .done: "Готово"
        case .projectSwiftUI: "SwiftUI Basics"
        case .projectData: "Data Layer"
        case .projectWellbeing: "Wellbeing"
        case .projectResearch: "Research"
        }
    }

    var systemImage: String {
        switch self {
        case .inbox: "tray.full"
        case .today: "sun.max"
        case .flagged: "flag.fill"
        case .inProgress: "bolt.horizontal.circle"
        case .done: "checkmark.circle.fill"
        case .projectSwiftUI: "swift"
        case .projectData: "cylinder.split.1x2"
        case .projectWellbeing: "heart.text.square"
        case .projectResearch: "book.pages"
        }
    }

    static let smartLists: [SidebarSelection] = [.inbox, .today, .flagged, .inProgress, .done]
}

struct ProjectNode: Identifiable, Hashable {
    let id: String
    let title: String
    let selection: SidebarSelection?
    let children: [ProjectNode]?

    static let studyTree: [ProjectNode] = [
        ProjectNode(
            id: "study-app",
            title: "Study App",
            selection: nil,
            children: [
                ProjectNode(id: "swiftui", title: "SwiftUI Basics", selection: .projectSwiftUI, children: nil),
                ProjectNode(id: "data", title: "Data Layer", selection: .projectData, children: nil),
            ]
        ),
        ProjectNode(
            id: "personal",
            title: "Personal",
            selection: nil,
            children: [
                ProjectNode(id: "wellbeing", title: "Wellbeing", selection: .projectWellbeing, children: nil),
                ProjectNode(id: "research", title: "Research", selection: .projectResearch, children: nil),
            ]
        ),
    ]
}
