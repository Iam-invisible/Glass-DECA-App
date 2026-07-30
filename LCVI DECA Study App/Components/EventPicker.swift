//
//  EventPicker.swift
//  LCVI DECA Study App
//
//  "Which event are you competing in?" — by code, the way students say it.
//
//  Typing a code is faster than scrolling sixty events, and it is how a
//  student already thinks about their season. The cost is that free text can
//  be wrong, so this validates against `DECAEvents`: anything the catalogue
//  cannot resolve is refused with a plain explanation and the field stays put
//  for another try. Suggestions appear as the student types so a half-
//  remembered code still lands.
//
//  Undecided is a first-class answer, not a cop-out — plenty of students pick
//  their event weeks after joining. It clears the stored code, and the app
//  simply behaves as though every component might apply.
//

import SwiftUI

struct EventPicker: View {
    /// The confirmed code, or "" for undecided.
    @Binding var eventCode: String
    /// Called when a real event is confirmed, so the caller can follow its
    /// cluster.
    var onConfirm: ((DECAEvent) -> Void)? = nil

    @State private var typed = ""
    @State private var rejected = false
    @FocusState private var focused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var suggestions: [DECAEvent] { DECAEvents.suggestions(for: typed) }
    private var confirmed: DECAEvent? { DECAEvents.event(forCode: eventCode) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let event = confirmed {
                confirmedCard(event)
            } else {
                entryField
                if !suggestions.isEmpty {
                    VStack(spacing: 6) {
                        ForEach(suggestions) { suggestion in
                            suggestionRow(suggestion)
                        }
                    }
                    .transition(.opacity)
                }
                if rejected && suggestions.isEmpty {
                    Label("That isn't an event code we recognise. Check the spelling, or pick Undecided for now.",
                          systemImage: "exclamationmark.triangle")
                        .font(.appCaption)
                        .foregroundStyle(Palette.danger)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity)
                }

                Button {
                    Haptics.tap()
                    eventCode = ""
                    typed = ""
                    rejected = false
                    focused = false
                } label: {
                    Text("I haven't decided yet")
                        .font(.appFootnote.weight(.medium))
                        .foregroundStyle(Palette.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                                .fill(Palette.cardSunken)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .animation(reduceMotion ? nil : Motion.snappy, value: suggestions.count)
        .animation(reduceMotion ? nil : Motion.snappy, value: eventCode)
        .animation(reduceMotion ? nil : Motion.quick, value: rejected)
    }

    // MARK: Entry

    private var entryField: some View {
        HStack(spacing: 10) {
            TextField("Event code — e.g. EIP, PMK, HTDM", text: $typed)
                .font(.appCallout)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .focused($focused)
                .submitLabel(.done)
                .onSubmit { confirm(typed) }
                .onChange(of: typed) { _ in rejected = false }

            if !typed.isEmpty {
                Button {
                    confirm(typed)
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Palette.accent)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Confirm event code")
            }
        }
        .padding(.horizontal, 13)
        .frame(minHeight: 50)
        .background(
            RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                .fill(Palette.cardSunken)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                .strokeBorder(rejected ? Palette.danger : Palette.stroke, lineWidth: 1)
        )
    }

    private func suggestionRow(_ event: DECAEvent) -> some View {
        Button {
            confirm(event.code)
        } label: {
            HStack(spacing: 11) {
                Text(event.code)
                    .font(.appCaptionBold)
                    .foregroundStyle(Palette.accent)
                    .frame(minWidth: 44, alignment: .leading)
                Text(event.name)
                    .font(.appFootnote)
                    .foregroundStyle(Palette.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 9)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Palette.cardSunken.opacity(0.7))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(event.code), \(event.name)")
    }

    // MARK: Confirmed

    /// Once an event is known the card states what the season actually looks
    /// like — including when the two levels differ, which is the whole reason
    /// the catalogue models them separately.
    private func confirmedCard(_ event: DECAEvent) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 9) {
                Text(event.code)
                    .font(.appCaptionBold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(event.cluster.tint))
                Text(event.name)
                    .font(.appCallout.weight(.medium))
                    .foregroundStyle(Palette.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }

            Text(event.formatSummary)
                .font(.appFootnote)
                .foregroundStyle(Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 7) {
                if event.hasAnyExam {
                    componentChip("Exam", "doc.text.fill", Palette.accent)
                }
                if event.hasAnyRoleplay {
                    componentChip("Roleplay", "person.wave.2.fill", Palette.gold)
                }
                if event.hasAnyPresentation {
                    componentChip("Presentation", "person.and.background.dotted", Palette.success)
                }
            }

            Button {
                Haptics.tap()
                eventCode = ""
                typed = ""
            } label: {
                Text("Change event")
                    .font(.appCaption.weight(.semibold))
                    .foregroundStyle(Palette.accent)
            }
            .buttonStyle(.plain)
            .padding(.top, 1)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
                .fill(event.cluster.tint.opacity(0.09))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
                .strokeBorder(event.cluster.tint.opacity(0.3), lineWidth: 1)
        )
        .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.97)))
    }

    private func componentChip(_ text: String, _ symbol: String, _ tint: Color) -> some View {
        Label(text, systemImage: symbol)
            .font(.appCaption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(tint.opacity(0.14)))
    }

    // MARK: Validation

    private func confirm(_ raw: String) {
        guard let event = DECAEvents.event(forCode: raw) else {
            Haptics.error()
            rejected = true
            return
        }
        Haptics.success()
        focused = false
        eventCode = event.code
        typed = ""
        rejected = false
        onConfirm?(event)
    }
}
