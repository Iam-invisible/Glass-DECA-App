#!/usr/bin/env python3
"""Structural checks on the seeded question bank.

Catches the mistakes that are easy to make at volume and invisible on a build:
a duplicate stable key (silently drops a question at seed time), a `why` array
that is not exactly four entries, a correctIndex out of range, and a rationale
list whose "Correct." line does not sit at the correct index.

It also gates the *shape* of the choices, which is a different class of bug and
was measured rather than guessed. The bank once answered B in 502 of 600
questions and put the longest choice on the right answer 85.9% of the time,
against a chance rate of 25% for both. A student could score in the eighties
without reading a question. Position is now dealt at random per presentation
(Models/ChoiceOrder.swift), so only length is left for this file to police:

  * no single question where the correct choice runs away from the field
  * no cluster where "pick the longest" beats chance by a wide margin
  * choices that are peers in length, so the eye has nothing to sort by

A distractor that is obviously a throwaway teaches nothing, and per the brief
the distractors are the teaching surface. These thresholds are the bar for
anything added to the bank.
"""
import re, sys, glob, os, statistics

ROOT = "/Users/shail/Desktop/LCVI DECA Study App/LCVI DECA Study App/Data/Questions"

STRING = re.compile(r'"(?:[^"\\]|\\.)*"')

# --- choice-shape thresholds -------------------------------------------------
# Chance is 25% for any rule based on shape alone. These allow real headroom
# above that, because some correct answers genuinely need a few more words —
# they are a ceiling on "obvious", not a demand that all four match to the byte.

MAX_LEAD = 25          # chars the correct choice may lead the longest distractor by
MAX_LONGEST_RATE = 0.40  # expected score of "always pick the longest", ties split
MAX_MEAN_RATIO = 1.25    # mean correct length / mean distractor length, per cluster

# MAX_LONGEST_RATE scores the strategy the way a student would actually run it,
# over every question rather than only those with a single longest choice, and
# splitting the credit when two tie. Measuring it conditionally instead reads
# high — the bank scored 85.9% that way against a true 80.5% — because it
# quietly drops the questions where the rule gives no answer.
#
# It will not reach 25%. Terminology questions have an irreducible floor: the
# four cells of a BCG matrix are "cash cow", "star", "question mark" and "dog",
# and padding those to equal length would wreck the question to beat a metric.
# The target is that length stops being worth betting on, not that every choice
# matches to the byte.

# Set once every cluster clears the bar. Until then the report prints and the
# thresholds do not fail the run, so the bank can be brought up to standard one
# cluster at a time without leaving the validator red in between.
ENFORCE_SHAPE = False


def split_top_level(body):
    """Split a Swift array literal body into top-level string entries."""
    return STRING.findall(body)


def unquote(s):
    return s[1:-1].replace('\\"', '"').replace('\\\\', '\\')

def main():
    total, keys, problems = 0, {}, []
    per_cluster = {}
    shapes = {}       # cluster file -> list of (key, choice lengths, correctIndex)

    for path in sorted(glob.glob(os.path.join(ROOT, "*.swift"))):
        src = open(path).read()
        name = os.path.basename(path)
        blocks = re.split(r'\n        q\("', src)[1:]
        per_cluster[name] = len(blocks)
        shapes[name] = []
        for b in blocks:
            total += 1
            key = b[:b.index('"')]
            if key in keys:
                problems.append(f"{name}: duplicate key {key} (also in {keys[key]})")
            keys[key] = name

            m = re.search(r'correct:\s*(\d+)', b)
            if not m:
                problems.append(f"{name}/{key}: no correct index")
                continue
            correct = int(m.group(1))
            if not 0 <= correct <= 3:
                problems.append(f"{name}/{key}: correct index {correct} out of range")

            wm = re.search(r'why: \[(.*?)\],\n\s+tags:', b, re.S)
            if not wm:
                problems.append(f"{name}/{key}: missing why array")
                continue
            entries = split_top_level(wm.group(1))
            if len(entries) != 4:
                problems.append(f"{name}/{key}: why has {len(entries)} entries, expected 4")
                continue
            # The rationale for the correct choice should announce itself.
            marked = [i for i, e in enumerate(entries) if e.startswith('"Correct.')]
            if marked != [correct]:
                problems.append(
                    f"{name}/{key}: 'Correct.' at {marked}, correctIndex is {correct}")

            # The four choices sit between the question text and `correct:`.
            head = split_top_level('q("' + b[:b.index('correct:')])
            if len(head) >= 6:
                shapes[name].append((key, [len(unquote(s)) for s in head[2:6]], correct))

    print("questions per file:")
    for k, v in per_cluster.items():
        print(f"  {v:4d}  {k}")
    print(f"total: {total}")
    print(f"unique keys: {len(keys)}")

    shape_problems = report_shape(shapes)

    if problems:
        print(f"\nPROBLEMS ({len(problems)}):")
        for p in problems:
            print("  " + p)
        sys.exit(1)
    if shape_problems and ENFORCE_SHAPE:
        print(f"\nSHAPE PROBLEMS ({len(shape_problems)}):")
        for p in shape_problems[:40]:
            print("  " + p)
        if len(shape_problems) > 40:
            print(f"  ... and {len(shape_problems) - 40} more")
        sys.exit(1)
    print("\nall structural checks passed")


def longest_pick_score(rows):
    """Expected accuracy of 'always pick the longest choice'.

    Scored over every question, not only those with a single longest choice,
    and splitting the credit across a tie the way guessing between them would.
    """
    if not rows:
        return 0.0
    expected = 0.0
    for _, lens, correct in rows:
        top = max(lens)
        tied = [i for i, L in enumerate(lens) if L == top]
        if correct in tied:
            expected += 1.0 / len(tied)
    return expected / len(rows)


def report_shape(shapes):
    """Prints the choice-shape report and returns the list of violations."""
    problems = []
    print("\nchoice shape — can a student score without reading?")
    print(f"  {'cluster':<20} {'longest wins':>13} {'len ratio':>10} {'worst lead':>11}")

    all_rows = [r for rows in shapes.values() for r in rows]
    for name, rows in sorted(shapes.items()):
        if not rows:
            continue
        cluster = name[len("SeedQuestions+"):-len(".swift")]

        rate = longest_pick_score(rows)

        cor = [lens[correct] for _, lens, correct in rows]
        wrong = [L for _, lens, correct in rows
                 for i, L in enumerate(lens) if i != correct]
        ratio = statistics.mean(cor) / statistics.mean(wrong) if wrong else 0.0

        leads = [(lens[correct] - max(L for i, L in enumerate(lens) if i != correct), key)
                 for key, lens, correct in rows]
        worst, worst_key = max(leads)

        flag = ""
        if rate > MAX_LONGEST_RATE:
            flag += " !rate"
            problems.append(f"{cluster}: 'pick the longest' wins {rate:.1%}, "
                            f"limit {MAX_LONGEST_RATE:.0%}")
        if ratio > MAX_MEAN_RATIO:
            flag += " !ratio"
            problems.append(f"{cluster}: correct choice averages {ratio:.2f}x the "
                            f"distractors, limit {MAX_MEAN_RATIO:.2f}x")
        print(f"  {cluster:<20} {rate:12.1%} {ratio:9.2f}x "
              f"{worst:+8d} {worst_key}{flag}")

        for lead, key in leads:
            if lead > MAX_LEAD:
                problems.append(f"{cluster}/{key}: correct choice leads the field by "
                                f"{lead} chars, limit {MAX_LEAD}")

    if all_rows:
        over = sum(1 for _, lens, correct in all_rows
                   if lens[correct] - max(L for i, L in enumerate(lens) if i != correct) > MAX_LEAD)
        print(f"\n  whole bank: 'always pick the longest' scores "
              f"{longest_pick_score(all_rows):.1%}  (chance 25.0%)")
        print(f"  questions leading by more than {MAX_LEAD} chars: {over}")
        if not ENFORCE_SHAPE:
            print("  (reporting only — ENFORCE_SHAPE is off while the bank is "
                  "brought up to standard)")
    return problems

if __name__ == "__main__":
    main()
