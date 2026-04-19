import SwiftUI
import WidgetKit

@main
struct StudyDemoWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TaskOverviewWidget()
        #if canImport(ActivityKit)
        FocusTimerLiveActivity()
        #endif
    }
}
