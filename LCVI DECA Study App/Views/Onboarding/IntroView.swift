//
//  IntroView.swift
//  LCVI DECA Study App
//
//  Picks which launch reveal to play. Both are kept: the handwritten one is
//  the default, and the original etched one stays selectable in Settings.
//

import SwiftUI

struct IntroView: View {
    var onFinish: () -> Void

    @EnvironmentObject private var store: AppStore

    var body: some View {
        switch style {
        case .script:  IntroScriptView(onFinish: onFinish)
        case .classic: IntroClassicView(onFinish: onFinish)
        }
    }

    /// The handwritten reveal needs Sacramento to be registered. If the font
    /// ever fails to load there are no glyphs to write, so fall back rather
    /// than opening the app on an empty screen.
    private var style: IntroStyle {
        WordGlyphs.glassScript.glyphs.isEmpty ? .classic : store.settings.introStyle
    }
}
