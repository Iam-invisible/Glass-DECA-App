//
//  StatusBarScrim.swift
//  LCVI DECA Study App
//
//  A short fade under the status bar so the clock, signal and battery stay
//  readable while content scrolls beneath them.
//
//  Once the root tabs started drawing their own titles, the system navigation
//  bar went away — and with it the opaque strip that used to sit behind the
//  status bar. Cards now scroll all the way up, so a dark card passing under
//  the time made it briefly unreadable, and the app looked like it had no top
//  edge at all.
//
//  This is a gradient of the canvas colour rather than a material. A blurred
//  strip across the full width would be recomputed every frame that anything
//  moves beneath it, which on an A11 is the same class of cost as the card
//  shadows that were making scrolling stutter. A gradient is a single cheap
//  fill and reads as the content receding rather than as a bar.
//
//  It ends fully transparent, so nothing is hidden — content is still visible
//  through it as it scrolls away, which is the point.
//
//  It also earns its place: at rest there is nothing under the status bar to
//  protect, so the scrim is invisible and the screen reads as one uninterrupted
//  surface. It fades in the moment content starts passing beneath. Detecting
//  that on iOS 16 means a preference probe — `onScrollGeometryChange` is
//  iOS 18 — so scrolling screens drop a zero-height `ScrollOffsetProbe` at the
//  top of their content and name their coordinate space with
//  `.reportsScrollOffset()`. Preferences travel up the tree, so the app root
//  hears it no matter which screen is showing.
//

import SwiftUI

// MARK: - Scroll reporting

enum ScrollOffsetKey: PreferenceKey {
    /// The name every scrolling screen gives its coordinate space.
    static let space = "app.scroll"
    /// Distance the content has travelled up. 0 at rest, negative scrolling.
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        // Screens publish one probe each, but a pushed screen can briefly
        // overlap its parent mid-transition. The smaller value is the one
        // that has scrolled further, which is the one worth protecting.
        value = min(value, nextValue())
    }
}

/// Reports where the content sits inside its scroll view.
///
/// Attach it with `.scrollOffsetProbe()` rather than dropping it into the
/// stack. It is zero-height, but a zero-height *child* still collects the
/// stack's spacing on both sides — as the first item in a
/// `VStack(spacing: 32)` it was pushing every screen's header down by a full
/// section gap, which is where the dead band under the status bar came from.
struct ScrollOffsetProbe: View {
    var body: some View {
        GeometryReader { geo in
            Color.clear.preference(
                key: ScrollOffsetKey.self,
                value: geo.frame(in: .named(ScrollOffsetKey.space)).minY
            )
        }
        .frame(height: 0)
        .accessibilityHidden(true)
    }
}

extension View {
    /// Names a `ScrollView`'s coordinate space so probes inside it resolve.
    func reportsScrollOffset() -> some View {
        coordinateSpace(name: ScrollOffsetKey.space)
    }

    /// Measures this stack's position without joining its layout. Apply to the
    /// content stack *before* its padding, so the probe sits exactly where a
    /// first child would have.
    func scrollOffsetProbe() -> some View {
        overlay(alignment: .top) { ScrollOffsetProbe() }
    }
}

// MARK: - Scrim

struct StatusBarScrim: View {
    /// How far past the status bar the fade runs before it reaches nothing.
    var falloff: CGFloat = 16
    /// Fades in once content is actually passing underneath.
    var isActive: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let inset = geo.safeAreaInsets.top
            LinearGradient(
                stops: [
                    // Solid across the status bar itself, then away quickly —
                    // an even fade over the whole height reads as a grey haze
                    // rather than as an edge.
                    .init(color: Palette.canvas, location: 0),
                    .init(color: Palette.canvas.opacity(0.96),
                          location: inset > 0 ? inset / (inset + falloff) : 0.55),
                    .init(color: Palette.canvas.opacity(0), location: 1)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: inset + falloff)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea(edges: .top)
            .opacity(isActive ? 1 : 0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.22), value: isActive)
        }
        // Purely decorative: it must never eat a tap meant for the content
        // underneath, and VoiceOver has no reason to know it exists.
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
