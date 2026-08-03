//
//  CustomizeView.swift
//  LCVI DECA Study App
//
//  The hamster, and the shop underneath it.
//
//  The hamster occupies the first screenful on its own and the shop begins
//  below the fold, so opening the tab shows you what you have rather than what
//  you could buy. That ordering is deliberate: a shop that greets you is a
//  storefront, and this is meant to be a reward for studying.
//
//  Coins are only ever earned — see `Cosmetics.swift` for the rates and for
//  why nothing here is purchasable with money.
//

import SwiftUI

struct CustomizeView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var shopTab: ShopTab = .hamster
    @State private var slot: CosmeticSlot = .hair
    @State private var appKind: AppCosmeticKind = .icon
    @State private var deniedItem: String?

    private var settings: UserSettings { store.settings }

    enum ShopTab: String, CaseIterable, Identifiable {
        case hamster, app
        var id: String { rawValue }
        var title: String {
            switch self {
            case .hamster: return "Hamster"
            case .app:     return "App"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Metrics.sectionSpacing) {
                    ScrollOffsetProbe()
                    header.appearIn(0)
                    stage.appearIn(1)
                    shop.appearIn(2)
                }
                .padding(.horizontal, Metrics.gutter)
                .padding(.top, 6)
                .padding(.bottom, 24)
            }
            .reportsScrollOffset()
            .appCanvas()
            .rootScreenChrome()
        }
    }

    // MARK: - Header

    private var header: some View {
        ScreenHeader("Customize",
                     eyebrow: "\(settings.coins) coins",
                     eyebrowSymbol: "circle.hexagongrid.fill",
                     eyebrowTint: Palette.gold,
                     subtitle: "Earned by studying. Nothing here costs money.")
    }

    // MARK: - Stage

    /// The hamster, sized to take most of a screen so the shop starts below the
    /// fold. Scroll down to find it — which is the whole layout brief.
    private var stage: some View {
        VStack(spacing: Metrics.stackSpacing) {
            HamsterAvatar(equipped: settings.equippedCosmetics)
                .frame(maxWidth: 300)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)

            if settings.equippedCosmetics.isEmpty {
                Text("Nothing on yet. The shop is just below.")
                    .font(.appFootnote)
                    .foregroundStyle(Palette.textSecondary)
            } else {
                wornRow
            }
        }
        .appCard(padding: 16)
    }

    /// What's currently worn, each chip tappable to take it off. Removing an
    /// item any other way would need a control per slot in the shop.
    private var wornRow: some View {
        let worn = CosmeticSlot.allCases.compactMap { slot in
            settings.equipped(slot).map { (slot, $0) }
        }
        return FlowRow(spacing: 8) {
            ForEach(worn, id: \.1.id) { pair in
                Button {
                    Haptics.tap()
                    withAnimation(reduceMotion ? nil : Motion.snappy) {
                        settings.unequip(pair.0)
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text(pair.1.name).font(.appCaptionBold)
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(Palette.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Palette.cardSunken))
                }
                .buttonStyle(PressableButtonStyle(haptic: false))
                .accessibilityLabel("Remove \(pair.1.name)")
            }
        }
    }

    // MARK: - Shop

    private var shop: some View {
        VStack(alignment: .leading, spacing: Metrics.headerGap) {
            SectionHeader(title: "Shop",
                          subtitle: "Tap to buy. Tap again to take it off.")

            AppSegmentedPicker("Shop section",
                               selection: $shopTab,
                               options: ShopTab.allCases,
                               label: \.title)

            switch shopTab {
            case .hamster: hamsterShop
            case .app:     appShop
            }
        }
    }

    private var hamsterShop: some View {
        VStack(alignment: .leading, spacing: Metrics.stackSpacing) {
            slotPicker
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10)],
                      spacing: 10) {
                ForEach(CosmeticCatalogue.items(in: slot)) { item in
                    cosmeticTile(item)
                }
            }
        }
    }

    private var slotPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CosmeticSlot.allCases) { s in
                    Button {
                        Haptics.select()
                        withAnimation(reduceMotion ? nil : Motion.snappy) { slot = s }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: s.symbol)
                                .font(.system(size: 11, weight: .semibold))
                            Text(s.title).font(.appCaptionBold)
                        }
                        .foregroundStyle(slot == s ? Palette.card : Palette.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(slot == s ? Palette.accent : Palette.cardSunken)
                        )
                    }
                    .buttonStyle(PressableButtonStyle(haptic: false))
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func cosmeticTile(_ item: CosmeticItem) -> some View {
        let owned = settings.owns(item)
        let equipped = settings.equipped(item.slot)?.id == item.id
        let affordable = settings.coins >= item.price
        let denied = deniedItem == item.id

        return Button {
            Haptics.tap()
            if owned {
                withAnimation(reduceMotion ? nil : Motion.snappy) { settings.toggleEquip(item) }
            } else if settings.buy(item) {
                SoundEffects.celebration()
            } else {
                flashDenied(item.id)
            }
        } label: {
            VStack(spacing: 8) {
                // A live preview of this one item on the hamster, so the tile
                // shows the thing itself rather than an icon standing in for it.
                HamsterAvatar(equipped: [item.slot: item], compact: true)
                    .frame(height: 84)

                Text(item.name)
                    .font(.appCaptionBold)
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                priceLabel(owned: owned, equipped: equipped,
                           price: item.price, affordable: affordable)
            }
            .frame(maxWidth: .infinity)
            .padding(11)
            .background(
                RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
                    .fill(equipped ? Palette.accent.opacity(0.12) : Palette.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
                    .strokeBorder(equipped ? Palette.accent.opacity(0.55)
                                           : Palette.stroke.opacity(0.8),
                                  lineWidth: equipped ? 1.5 : 1)
            )
            .opacity(owned || affordable ? 1 : 0.55)
            .offset(x: denied ? 6 : 0)
        }
        .buttonStyle(PressableButtonStyle(scale: 0.97, haptic: false))
        .accessibilityLabel(accessibilityLabel(item, owned: owned, equipped: equipped))
    }

    private func accessibilityLabel(_ item: CosmeticItem, owned: Bool, equipped: Bool) -> String {
        if equipped { return "\(item.name), worn. Tap to take off." }
        if owned    { return "\(item.name), owned. Tap to wear." }
        return "\(item.name), \(item.price) coins."
    }

    // MARK: App shop

    private var appShop: some View {
        VStack(alignment: .leading, spacing: Metrics.stackSpacing) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(AppCosmeticKind.allCases) { k in
                        Button {
                            Haptics.select()
                            withAnimation(reduceMotion ? nil : Motion.snappy) { appKind = k }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: k.symbol)
                                    .font(.system(size: 11, weight: .semibold))
                                Text(k.title).font(.appCaptionBold)
                            }
                            .foregroundStyle(appKind == k ? Palette.card : Palette.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(appKind == k ? Palette.accent : Palette.cardSunken)
                            )
                        }
                        .buttonStyle(PressableButtonStyle(haptic: false))
                    }
                }
                .padding(.horizontal, 2)
            }

            VStack(spacing: 10) {
                ForEach(AppCosmeticCatalogue.items(of: appKind)) { item in
                    appTile(item)
                }
            }

            if appKind == .icon {
                Text("Changing the icon asks for permission the first time. iOS shows the alert itself.")
                    .font(.appCaption)
                    .foregroundStyle(Palette.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func appTile(_ item: AppCosmeticItem) -> some View {
        let owned = settings.owns(item)
        let selected = settings.isSelected(item)
        let affordable = settings.coins >= item.price
        let denied = deniedItem == item.id

        return Button {
            Haptics.tap()
            if owned {
                settings.select(item)
                if item.kind == .icon { applyIcon(item) }
            } else if settings.buy(item) {
                SoundEffects.celebration()
                if item.kind == .icon { applyIcon(item) }
            } else {
                flashDenied(item.id)
            }
        } label: {
            HStack(spacing: 13) {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Color(hex: item.previewHex))
                    .frame(width: 46, height: 46)
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .strokeBorder(.white.opacity(0.25), lineWidth: 0.5)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(.appBodyMedium)
                        .foregroundStyle(Palette.textPrimary)
                    Text(item.detail)
                        .font(.appCaption)
                        .foregroundStyle(Palette.textTertiary)
                }

                Spacer(minLength: 0)

                priceLabel(owned: owned, equipped: selected,
                           price: item.price, affordable: affordable)
            }
            .padding(13)
            .background(
                RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
                    .fill(selected ? Palette.accent.opacity(0.12) : Palette.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
                    .strokeBorder(selected ? Palette.accent.opacity(0.55)
                                           : Palette.stroke.opacity(0.8),
                                  lineWidth: selected ? 1.5 : 1)
            )
            .opacity(owned || affordable ? 1 : 0.55)
            .offset(x: denied ? 6 : 0)
        }
        .buttonStyle(PressableButtonStyle(scale: 0.99, haptic: false))
    }

    // MARK: - Shared bits

    @ViewBuilder
    private func priceLabel(owned: Bool, equipped: Bool, price: Int, affordable: Bool) -> some View {
        if equipped {
            Label("On", systemImage: "checkmark")
                .font(.appCaptionBold)
                .foregroundStyle(Palette.accent)
        } else if owned {
            Text("Owned")
                .font(.appCaptionBold)
                .foregroundStyle(Palette.textTertiary)
        } else {
            HStack(spacing: 4) {
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 10, weight: .bold))
                Text("\(price)").font(.appCaptionBold).monospacedDigit()
            }
            .foregroundStyle(affordable ? Palette.gold : Palette.textTertiary)
        }
    }

    /// A nudge rather than an alert. Not being able to afford something is not
    /// an error worth a modal — the price is right there and the balance is in
    /// the header.
    private func flashDenied(_ id: String) {
        Haptics.warning()
        withAnimation(reduceMotion ? nil : .default) { deniedItem = id }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            withAnimation(reduceMotion ? nil : .default) { deniedItem = nil }
        }
    }

    /// Alternate icons need the names in `CFBundleAlternateIcons` and the files
    /// in the bundle. A failure here is silent on purpose: iOS refuses on some
    /// configurations, and a student who bought a skin should not be shown a
    /// system error for it.
    private func applyIcon(_ item: AppCosmeticItem) {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        let name: String? = item.isDefault ? nil : item.id
        UIApplication.shared.setAlternateIconName(name) { _ in }
    }
}

// MARK: - Flow layout

/// Wraps chips onto as many lines as they need. `LazyVGrid` cannot do this —
/// it wants fixed columns, and these are text-width.
struct FlowRow<Content: View>: View {
    var spacing: CGFloat = 8
    @ViewBuilder var content: Content

    var body: some View {
        if #available(iOS 16.0, *) {
            FlowLayout(spacing: spacing) { content }
        } else {
            HStack(spacing: spacing) { content }
        }
    }
}

@available(iOS 16.0, *)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, lineHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0; y += lineHeight + spacing; lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: width == .infinity ? x : width, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, lineHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX; y += lineHeight + spacing; lineHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
