//
//  ChoiceRationaleList.swift
//  LCVI DECA Study App
//
//  Why each option is right or wrong, option by option.
//
//  The single `explanation` field says why the correct answer is correct. That
//  is the smaller half of the work: on a cluster exam the distractors are the
//  lesson, because each one is a plausible concept a student has confused with
//  the right one. "Penetration pricing" as a wrong answer is only useful if the
//  student is told it means the opposite of skimming.
//
//  Renders nothing when a question carries no rationales — a student's own
//  imported bank never will, and this has to stay silent rather than nag.
//

import SwiftUI

struct ChoiceRationaleList: View {
    let question: QuestionData
    /// The student's answer, so their own wrong pick can be called out rather
    /// than sitting anonymously among the other three.
    var selectedIndex: Int?

    var body: some View {
        if question.hasChoiceRationales {
            VStack(alignment: .leading, spacing: 9) {
                Label("Every option", systemImage: "list.bullet.rectangle")
                    .font(.appCaptionBold)
                    .foregroundStyle(Palette.textSecondary)

                ForEach(Array(question.choices.enumerated()), id: \.offset) { index, choice in
                    if let rationale = question.rationale(for: index) {
                        row(index: index, choice: choice, rationale: rationale)
                    }
                }
            }
        }
    }

    private func row(index: Int, choice: String, rationale: String) -> some View {
        let isCorrect = index == question.correctIndex
        let isChosen = index == selectedIndex
        let tint: Color = isCorrect ? Palette.success : (isChosen ? Palette.danger : Palette.textTertiary)

        return HStack(alignment: .top, spacing: 9) {
            Text(AnswerLetter(rawValue: index)?.label ?? "?")
                .font(.appCaptionBold)
                .foregroundStyle(tint)
                .frame(width: 21, height: 21)
                .background(
                    Circle().fill(tint.opacity(0.14))
                )
                .overlay(
                    Circle().strokeBorder(tint.opacity(0.35), lineWidth: 0.5)
                )

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(choice)
                        .font(.appFootnote.weight(.semibold))
                        .foregroundStyle(Palette.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    if isCorrect {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Palette.success)
                    } else if isChosen {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Palette.danger)
                    }
                }

                Text(rationale)
                    .font(.appFootnote)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 9)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(isCorrect ? Palette.successSoft.opacity(0.6)
                      : (isChosen ? Palette.dangerSoft.opacity(0.55) : Color.clear))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(AnswerLetter(rawValue: index)?.label ?? "") \(choice). \(isCorrect ? "Correct." : "Incorrect.")")
        .accessibilityValue(rationale)
    }
}
