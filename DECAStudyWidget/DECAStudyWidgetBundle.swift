//
//  DECAStudyWidgetBundle.swift
//  DECAStudyWidget
//

import SwiftUI
import WidgetKit

@main
struct DECAStudyWidgetBundle: WidgetBundle {
    var body: some Widget {
        DailyProgressWidget()
        StreakWidget()
        RemainingWidget()
        QuickLaunchWidget()
    }
}
