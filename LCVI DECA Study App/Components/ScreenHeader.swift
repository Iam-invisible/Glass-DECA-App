//
//  ScreenHeader.swift
//  LCVI DECA Study App
//
//  The title block every root tab opens with.
//
//  Two problems, one answer. The app's display face is now a high-contrast
//  serif, and a system large title can't use it — `navigationTitle` renders in
//  San Francisco, so five of the six tabs opened in a typeface the rest of the
//  app doesn't use. And the navigation bar is OS-drawn, so iOS 16 and iOS 26
//  draw it differently: it was the largest remaining source of the
//  cross-version inconsistency the custom controls exist to fix.
//
//  Drawing the title ourselves and hiding the bar solves both at once. Pushed
//  screens keep their normal inline bars, because those carry the back button
//  and should behave exactly as the OS expects.
//
//  A header is a title and, where it earns its place, one line of subtitle.
//  There used to be an eyebrow above the title carrying scope — the cluster,
//  "All clusters", an attempt count — and it was removed everywhere: it was a
//  third line of chrome above the thing you actually came to read, and none of
//  it was information a student needed on arrival.
//
//  `event` is the one exception, and it is a different thing wearing the same
//  slot. Scope described the screen; the event is what the student is training
//  for, and Study and Progress are the two screens that exist to answer "how
//  am I doing at it". Nothing else passes it — a shop or a settings screen has
//  no more claim on that line than it had on the old one.
//

import SwiftUI

struct ScreenHeader<Accessory: View>: View {
    let title: String

    var subtitle: String? = nil

    /// The student's competitive event, shown above the title. Study and
    /// Progress only — see the note at the top of this file.
    var event: EventTag? = nil

    @ViewBuilder var accessory: () -> Accessory

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                // Guarded here rather than wrapped in a container that is
                // always built, so a header without an event does not collect
                // the stack's spacing on both sides of nothing (§8.28).
                if let event {
                    event.padding(.bottom, 1)
                }

                Text(title)
                    .font(.appLargeTitle)
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitle {
                    Text(subtitle)
                        .font(.appFootnote)
                        .foregroundStyle(Palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
            accessory()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 2)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

extension ScreenHeader where Accessory == EmptyView {
    init(_ title: String, subtitle: String? = nil, event: EventTag? = nil) {
        self.init(title: title, subtitle: subtitle, event: event) { EmptyView() }
    }
}

extension View {
    /// Hides the system navigation bar on a root tab, which now draws its own
    /// title with `ScreenHeader`. Never apply this to a pushed screen — those
    /// need the bar for the back button.
    func rootScreenChrome() -> some View {
        toolbar(.hidden, for: .navigationBar)
    }
}
