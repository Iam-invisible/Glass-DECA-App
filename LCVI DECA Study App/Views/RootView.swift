//
//  RootView.swift
//  LCVI DECA Study App
//
//  App shell: onboarding gate, custom six-item tab bar, celebration overlays.
//  A custom bar is used instead of TabView so all six destinations stay
//  reachable on an iPhone 8-sized screen without iOS collapsing them into
//  a "More" list.
//

import SwiftUI

enum AppTab: Int, CaseIterable, Identifiable {
    case today, practice, mock, roleplay, progress, settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .today:    return "Today"
        case .practice: return "Practice"
        case .mock:     return "Exams"
        case .roleplay: return "Roleplay"
        case .progress: return "Progress"
        case .settings: return "Settings"
        }
    }

    var accessibilityTitle: String {
        self == .mock ? "Mock Exams" : title
    }

    var symbol: String {
        switch self {
        case .today:    return "sun.max.fill"
        case .practice: return "list.bullet.rectangle.portrait.fill"
        case .mock:     return "doc.text.fill"
        case .roleplay: return "person.wave.2.fill"
        case .progress: return "chart.bar.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var tab: AppTab = .today
    /// +1 when moving to a tab on the right, -1 to the left. Set before the
    /// tab changes so the transition knows which way to travel.
    @State private var direction: CGFloat = 1

    var body: some View {
        Group {
            if store.showIntro {
                IntroView { store.showIntro = false }
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
            if !store.showIntro { StatusBarScrim() }
        }
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
        .onChange(of: scenePhase) { phase in
            if phase == .active { store.onForeground() }
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
        }
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
        case .today:
            // Routed through `select` so the cards on Today animate the same
            // way as tapping the bar.
            TodayView(switchTab: select)
        case .practice:
            PracticeView()
        case .mock:
            MockExamsView()
        case .roleplay:
            RoleplayView()
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
    private static let floatGap: CGFloat = 10

    /// Height scrollable screens must reserve: the capsule plus the gap it
    /// floats above the safe-area bottom.
    static let contentHeight: CGFloat = capsuleHeight + floatGap

    let selection: AppTab
    let onSelect: (AppTab) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var highlight

    var body: some View {
        bar
            .shadow(color: Palette.shadow.opacity(0.18), radius: 16, y: 6)
            .padding(.horizontal, 14)
            .padding(.bottom, Self.floatGap)
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
