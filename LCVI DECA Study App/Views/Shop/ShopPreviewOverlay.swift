//
//  ShopPreviewOverlay.swift
//  LCVI DECA Study App
//
//  Tap an item, see what it actually does, then decide.
//
//  The shop used to buy on a single tap against a coloured square standing in
//  for the thing — a swatch for an icon you had never seen, a swatch for a
//  sound you had never heard. That is asking someone to spend a week of
//  studying on a guess. Every preview here shows the real artefact: the icon
//  as it will appear on the home screen, the theme applied to real controls,
//  the intro's own lettering, and the sound played out loud.
//
//  Structure mirrors `CoinGuideOverlay` — translucent scrim over the whole app
//  with a card on top — because this is the same kind of interruption and
//  should feel like the same thing.
//

import SwiftUI

struct ShopPreviewOverlay: View {
    let item: AppCosmeticItem
    let owned: Bool
    let selected: Bool
    let coins: Int
    let onBuy: () -> Void
    let onUse: () -> Void
    let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    @State private var denied = false
    @State private var shake: CGFloat = 0

    private var affordable: Bool { coins >= item.price }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Palette.shadow.opacity(0.28))
                .ignoresSafeArea()
                .onTapGesture { close() }
                .accessibilityLabel("Close")
                .accessibilityAddTraits(.isButton)

            card
                .padding(.horizontal, Metrics.gutter)
                .scaleEffect(shown || reduceMotion ? 1 : 0.94)
                .opacity(shown ? 1 : 0)
                .modifier(RefusalShake(progress: denied ? shake : 0))
        }
        .onAppear { withAnimation(reduceMotion ? nil : Motion.bouncy) { shown = true } }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: Metrics.stackSpacing) {
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.appTitle)
                    .foregroundStyle(Palette.textPrimary)
                Text(item.detail)
                    .font(.appFootnote)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ShopPreview(item: item)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                        .fill(Palette.cardSunken)
                )

            action
        }
        .appCard(padding: 18)
    }

    @ViewBuilder
    private var action: some View {
        if owned, item.kind == .companion {
            // A switch, not a status. Every other category answers "which one",
            // where an off state means nothing; the companion answers "at all",
            // and a student revising is allowed to want the screen quiet
            // without buying their way back in afterwards.
            //
            // The card deliberately stays open. The bunny lives outside this
            // sheet, so closing on tap would hide the one thing that just
            // changed and make a second tap a fresh trip through the shop.
            VStack(spacing: 9) {
                Button { onUse() } label: {
                    label(selected ? "Turn off" : "Turn on",
                          symbol: selected ? "moon.zzz.fill" : "sparkles",
                          tint: selected ? Palette.textSecondary : Palette.accent,
                          filled: !selected)
                }
                .buttonStyle(PressableButtonStyle(haptic: false))

                Text(selected ? "On every screen, reacting to how you're doing."
                              : "Off. Turn it back on any time — it stays bought.")
                    .font(.appCaption)
                    .foregroundStyle(Palette.textTertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else if selected {
            label("In use", symbol: "checkmark", tint: Palette.textTertiary, filled: false)
        } else if owned {
            Button { onUse(); close() } label: {
                label("Use this", symbol: "arrow.up.forward", tint: Palette.accent, filled: true)
            }
            .buttonStyle(PressableButtonStyle(haptic: false))
        } else {
            Button {
                guard affordable else { return refuse() }
                onBuy()
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "circle.hexagongrid.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("Buy for \(item.price)")
                        .font(.appHeadline)
                        .monospacedDigit()
                }
                .foregroundStyle(affordable ? Palette.card : Palette.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Capsule().fill(affordable ? Palette.accent : Palette.cardSunken))
            }
            .buttonStyle(PressableButtonStyle(haptic: false))

            if !affordable {
                // The gap, not just the price. "You need 240 more" is
                // actionable in a way that a greyed-out button is not.
                Text("You need \(item.price - coins) more. Answer questions to earn them.")
                    .font(.appCaption)
                    .foregroundStyle(Palette.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func label(_ text: String, symbol: String, tint: Color, filled: Bool) -> some View {
        HStack(spacing: 7) {
            Image(systemName: symbol).font(.system(size: 13, weight: .bold))
            Text(text).font(.appHeadline)
        }
        .foregroundStyle(filled ? Palette.card : tint)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 13)
        .background(Capsule().fill(filled ? tint : Palette.cardSunken))
    }

    private func refuse() {
        Haptics.warning()
        guard !reduceMotion else { return }
        denied = true
        shake = 0
        withAnimation(.linear(duration: 0.55)) { shake = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { denied = false }
    }

    private func close() {
        Haptics.tap()
        withAnimation(reduceMotion ? nil : Motion.quick) { shown = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16, execute: onClose)
    }
}

// MARK: - The preview itself

/// One real sample per category. Nothing here is a stand-in.
struct ShopPreview: View {
    let item: AppCosmeticItem

    /// Bumped to replay the intro reveal. A counter rather than a flag, because
    /// the animation has to restart even when it is already sitting at the end.
    @State private var introPlays = 0

    var body: some View {
        switch item.kind {
        case .icon:      iconPreview
        case .theme:     themePreview
        case .intro:     introPreview
        case .sound:     soundPreview
        case .companion: companionPreview
        }
    }

    // MARK: Icons

    @ViewBuilder
    private var iconPreview: some View {
        if item.isPack {
            HStack(spacing: 12) {
                ForEach(item.unlocks, id: \.self) { id in
                    AppIconTile(id: id, side: 62)
                }
            }
        } else {
            VStack(spacing: 9) {
                AppIconTile(id: item.id, side: 96)
                Text("Glass")
                    .font(.appSans(11, weight: .medium))
                    .foregroundStyle(Palette.textSecondary)
            }
        }
    }

    // MARK: Themes

    /// The accent on the controls it actually recolours, so the choice is made
    /// against a button and a ring rather than against a paint chip.
    private var themePreview: some View {
        let theme = AccentTheme(itemID: item.id)
        return HStack(spacing: 16) {
            ZStack {
                Circle()
                    .strokeBorder(Palette.card, lineWidth: 7)
                    .frame(width: 54, height: 54)
                Circle()
                    .trim(from: 0, to: 0.68)
                    .stroke(theme.accent, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 54, height: 54)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Practice")
                    .font(.appCaptionBold)
                    .foregroundStyle(Palette.card)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(theme.accent))
                Text("Review Due")
                    .font(.appCaption)
                    .foregroundStyle(theme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(theme.accentSoft))
            }
        }
    }

    // MARK: Intros

    /// The reveal, playing.
    ///
    /// This used to be the wordmark sitting still with a sentence underneath
    /// saying what it would do if you bought it. An intro is a motion, so a
    /// still of one is half an answer — and it is the one thing in the shop a
    /// student cannot see anywhere else, since the real thing plays once at
    /// launch before they own it.
    private var introPreview: some View {
        let script = item.id == "intro.script"
        return VStack(spacing: 12) {
            IntroReveal(isScript: script, playToken: introPlays)

            Button {
                Haptics.tap()
                introPlays += 1
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Play again")
                        .font(.appBodyMedium)
                }
                .foregroundStyle(Palette.accent)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Capsule().fill(Palette.accentSoft))
            }
            .buttonStyle(PressableButtonStyle(haptic: false))

            Text(script ? "Written out, then flooded as glass."
                        : "Traced, then filled as glass.")
                .font(.appCaption)
                .foregroundStyle(Palette.textTertiary)
        }
    }

    // MARK: Sounds

    private var soundPreview: some View {
        VStack(spacing: 10) {
            Button {
                Haptics.tap()
                SoundEffects.preview(pack: item.id)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Hear it")
                        .font(.appBodyMedium)
                }
                .foregroundStyle(Palette.accent)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Capsule().fill(Palette.accentSoft))
            }
            .buttonStyle(PressableButtonStyle(haptic: false))
            Text("Plays the correct-answer tone")
                .font(.appCaption)
                .foregroundStyle(Palette.textTertiary)
        }
    }

    // MARK: Companion

    private var companionPreview: some View {
        HStack(spacing: 14) {
            ForEach([BunnyMood.happy, .starstruck, .thinking, .no], id: \.self) { mood in
                if let ui = UIImage(named: mood.imageName) {
                    Image(uiImage: ui).resizable().scaledToFit().frame(height: 46)
                }
            }
        }
    }
}

// MARK: - Icon tile

/// A real app icon, masked the way iOS masks it.
///
/// The default has no alternate file — the asset catalog owns it — so its
/// image is looked up through the name the build wrote into
/// `CFBundlePrimaryIcon`, which is the only place that name exists.
struct AppIconTile: View {
    let id: String
    var side: CGFloat = 62

    var body: some View {
        Group {
            if let ui = Self.image(for: id) {
                Image(uiImage: ui).resizable().scaledToFill()
            } else {
                Rectangle().fill(Palette.cardSunken)
            }
        }
        .frame(width: side, height: side)
        // 22.37% of the width is Apple's continuous-corner icon mask.
        .clipShape(RoundedRectangle(cornerRadius: side * 0.2237, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: side * 0.2237, style: .continuous)
                .strokeBorder(.white.opacity(0.16), lineWidth: 0.5)
        )
    }

    static func image(for id: String) -> UIImage? {
        guard id != "icon.default" else { return primaryIcon() }
        return UIImage(named: id)
    }

    private static func primaryIcon() -> UIImage? {
        guard let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let files = primary["CFBundleIconFiles"] as? [String],
              let name = files.last else { return nil }
        return UIImage(named: name)
    }
}
