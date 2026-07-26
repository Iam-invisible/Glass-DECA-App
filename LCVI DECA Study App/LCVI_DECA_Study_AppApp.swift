//
//  LCVI_DECA_Study_AppApp.swift
//  LCVI DECA Study App
//
//  Offline-first DECA Ontario study companion.
//  No sign-in, no network, no analytics — everything lives on this device.
//

import SwiftUI

@main
struct LCVI_DECA_Study_AppApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .tint(Palette.accent)
                .onOpenURL { url in
                    // Widget deep links: decastudy://practice, decastudy://cram
                    switch url.host?.lowercased() {
                    case "practice": store.pendingDeepLink = .dailyPractice
                    case "cram":     store.pendingDeepLink = .examCram
                    default:         break
                    }
                }
        }
    }
}
