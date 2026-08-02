//
//  RootView.swift
//  LCVI DECA Study App
//
//  App shell: onboarding gate, the three-pane tab bar, celebration overlays.
//
//  Three panes — Study, Progress, Settings — because the app has three jobs:
//  do the work, see how it's going, manage the machine. Mock Exams and
//  Roleplay kept their entire screens; they are pushed from Study's tiles
//  rather than owning tabs, which turns six cramped bar targets into three
//  comfortable ones.
//

import SwiftUI

enum AppTab: Int, CaseIterable, Identifiable {
    case study, progress, settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .study:    return "Study"
        case .progress: return "Progress"
        case .settings: return "Settings"
        }
    }

    var accessibilityTitle: String { title }

    var symbol: String {
        switch self {
        case .study:    return "book.fill"
        case .progress: return "chart.bar.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var tab: AppTab = .study
    /// +1 when moving to a tab on the right, -1 to the left. Set before the
    /// tab changes so the transition knows which way to travel.
    @State private var direction: CGFloat = 1
    /// True once any screen's content has moved under the status bar.
    @State private var scrolled = false

    var body: some View {
        Group {
            if store.showIntro {
                IntroView { store.showIntro = false }
                    .transition(.opacity)
            } else if !store.settings.hasAcceptedCurrentPrivacyPolicy {
                // After the intro so its choreography is never interrupted,
                // and before onboarding because onboarding's first act has the
                // student answering a real question — which is using the app.
                // A bump to PrivacyPolicy.version brings this back for
                // everyone, which is how a material change is re-consented.
                PrivacyConsentView { }
                    .transition(.opacity)
            } else if store.settings.hasOnboarded {
                main
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        // Sits at the very top of the hierarchy, before anything downstream
        // ignores the safe area, because that is the only place a
        // `GeometryReader` can still read the real status-bar inset. The intro
        // is exempt: it is a full-bleed scene with nothing scrolling under the
        // clock, and a bar across it would break the reveal.
        .overlay(alignment: .top) {
            if !store.showIntro { StatusBarScrim(isActive: scrolled) }
        }
        .onPreferenceChange(ScrollOffsetKey.self) { offset in
            // A couple of points of slack: rubber-banding and rounding both
            // wobble the offset at rest, and a scrim that flickers on a
            // stationary screen is worse than one that is always on.
            let now = offset < -3
            if now != scrolled { scrolled = now }
        }
        // A new tab starts at the top, so the scrim should not linger from
        // wherever the last one was left.
        .onChange(of: tab) { _ in scrolled = false }
        // This is a native app, not a web page — no scroll position bars.
        // `scrollIndicators` is environment-based, so one call covers every
        // descendant scroll view, including pushed and presented screens.
        .scrollIndicators(.hidden)
        // The system switch was redrawn between iOS 16 and 26. `ToggleStyle`
        // propagates through the environment, so setting it once here covers
        // every Toggle in the app — including ones written later, which is the
        // part a per-call-site fix would not survive.
        .toggleStyle(.app)
        .preferredColorScheme(store.settings.appearance.colorScheme)
        .animation(reduceMotion ? nil : Motion.gentle, value: store.settings.hasOnboarded)
        .animation(reduceMotion ? nil : Motion.gentle, value: store.showIntro)
        .onAppear { store.onAppear() }
        .onChange(of: store.requestedTab) { requested in
            guard let requested else { return }
            store.requestedTab = nil
            select(requested)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active { store.onForeground() }
            // .background rather than .inactive: inactive fires for the app
            // switcher and for control centre, and dropping a gigabyte of
            // weights every time someone swipes down would be worse than
            // holding them.
            if phase == .background { store.onBackground() }
        }
        .celebrationLayer()
    }

    private var main: some View {
        ZStack(alignment: .bottom) {
            Palette.canvas.ignoresSafeArea()

            ZStack {
                content
                    .id(tab)
                    .transition(pageTransition)
            }
            .environment(\.bottomBarInset, AppTabBar.contentHeight)

            AppTabBar(selection: tab, onSelect: select)
                .guideAnchor(.tabBar)
        }
        // Resolved here rather than inside any screen so the spotlight can
        // reach the tab bar and the Study content in the same pass.
        .overlayPreferenceValue(GuideAnchorKey.self) { anchors in
            GeometryReader { proxy in
                if store.showGuide {
                    GuideOverlay(anchors: anchors,
                                 proxy: proxy,
                                 onTarget: { store.guideFocus = $0 }) {
                        store.guideFocus = nil
                        store.showGuide = false
                        store.settings.hasSeenGuide = true
                    }
                }
            }
            // Full screen, so anchors resolve in the same space the
            // spotlight draws in — including under the status bar and
            // around the floating tab bar.
            .ignoresSafeArea()
        }
        .animation(reduceMotion ? nil : Motion.gentle, value: store.showGuide)
    }

    private var pageTransition: AnyTransition {
        // Reduce Motion gets a plain cross-fade rather than travel and depth.
        reduceMotion ? .opacity : .page(direction: direction)
    }

    private func select(_ item: AppTab) {
        guard item != tab else { return }
        Haptics.select()
        direction = item.rawValue > tab.rawValue ? 1 : -1
        withAnimation(reduceMotion ? .easeOut(duration: 0.16) : Motion.page) {
            tab = item
        }
    }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .study:
            StudyView()
        case .progress:
            ProgressDashboardView()
        case .settings:
            SettingsView()
        }
    }
}

// MARK: - Custom tab bar

/// A floating Liquid Glass tab bar.
///
/// Detached from the screen edges so app content shows through and around it.
/// On iOS 26 it uses the real `glassEffect` so the bar refracts whatever is
/// scrolling underneath; older systems (including iPhone 8 on iOS 16) fall back
/// to a translucent material in the same capsule, so the layout is identical.
struct AppTabBar: View {
    private static let capsuleHeight: CGFloat = 56

    /// Clearance measured from the **physical** bottom edge, not from the safe
    /// area — which is why the bar ignores the bottom inset below.
    ///
    /// It used to float 10pt above the safe-area bottom. On a home-indicator
    /// phone that inset is 34pt, so the bar actually sat 44pt off the edge with
    /// a band of dead space underneath it that no content could use. Measuring
    /// from the edge instead drops it to 16pt there. On a device with no
    /// indicator — iPhone 8 — the inset is 0, so the bar moves *up* by 6pt
    /// rather than down; that is the cost of one constant serving both, and
    /// 16pt is a normal resting place for a floating bar either way.
    ///
    /// 16 is a floor, not a preference. The home indicator occupies roughly the
    /// lowest 11pt and the system draws it over app content, so anything under
    /// about 14 puts the indicator line across the capsule.
    private static let bottomClearance: CGFloat = 16

    /// Height scrollable screens reserve, still measured from the safe-area
    /// bottom. Deliberately left at the old value: content is *meant* to flow
    /// under the translucent capsule, so this only has to keep the last row
    /// reachable, and it is now conservative on indicator phones rather than
    /// tight. Re-deriving it per device would mean reading the safe-area inset,
    /// which would put a second GeometryReader around `main` — exactly the
    /// coordinate-space mix-up that put the guide's spotlight in the wrong
    /// place once already.
    static let contentHeight: CGFloat = capsuleHeight + 10

    let selection: AppTab
    let onSelect: (AppTab) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var highlight

    var body: some View {
        bar
            .shadow(color: Palette.shadow.opacity(0.18), radius: 16, y: 6)
            .padding(.horizontal, 14)
            .padding(.bottom, Self.bottomClearance)
            .ignoresSafeArea(.container, edges: .bottom)
    }

    @ViewBuilder
    private var bar: some View {
        let row = HStack(spacing: 0) {
            ForEach(AppTab.allCases) { item in
                tabButton(item)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: Self.capsuleHeight)

        if #available(iOS 26.0, *) {
            // `.regular` rather than `.clear`: clear glass lets so much through
            // that content scrolling underneath collides with the tab labels.
            // Regular still refracts the background, just with enough diffusion
            // to keep the labels readable.
            row.glassEffect(.regular, in: .capsule)
        } else {
            row
                .background(.ultraThinMaterial, in: Capsule(style: .continuous))
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(Palette.stroke.opacity(0.7), lineWidth: 0.5)
                )
        }
    }

    private func tabButton(_ item: AppTab) -> some View {
        Button {
            onSelect(item)
        } label: {
            VStack(spacing: 3) {
                Image(systemName: item.symbol)
                    .font(.system(size: 17, weight: .semibold))
                    .scaleEffect(selection == item && !reduceMotion ? 1.06 : 1)
                Text(item.title)
                    .font(.appSans(10, weight: selection == item ? .semibold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(selection == item ? Palette.accent : Palette.textTertiary)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background {
                if selection == item {
                    Capsule(style: .continuous)
                        .fill(Palette.accent.opacity(0.14))
                        .matchedGeometryEffect(id: "tab.highlight", in: highlight)
                }
            }
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.accessibilityTitle)
        .accessibilityAddTraits(selection == item ? [.isSelected, .isButton] : .isButton)
    }
}
