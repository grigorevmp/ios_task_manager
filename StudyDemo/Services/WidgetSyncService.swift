import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

struct WidgetSyncService {
    func store(snapshot: TaskWidgetSnapshot) {
        let defaults = UserDefaults(suiteName: SharedAppGroup.identifier)
        let data = try? JSONEncoder().encode(snapshot)
        defaults?.set(data, forKey: SharedAppGroup.snapshotKey)

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
