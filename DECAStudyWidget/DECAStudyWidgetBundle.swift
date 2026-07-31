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
        OverviewWidget()
        StreakWidget()
        RemainingWidget()
        QuickLaunchWidget()
    }
}
