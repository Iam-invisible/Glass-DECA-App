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
MAX_RANK_DEVIATION = 0.15  # how far the length-rank spread may sit from flat
MAX_MEAN_RATIO = 1.25    # mean correct length / mean distractor length, per cluster

# The gate is the *rank* of the correct answer by length — longest, second,
# third, shortest — which has to come out near 25% each. Gating on "how often
# is the correct answer the longest" alone is not enough, and getting that
# wrong is how this bank acquired its second tell while the first was being
# fixed: pushing one distractor past the correct answer drops the longest rate
# to 8% and parks the answer at second-longest 61% of the time. "Never the
# longest" is worth a free elimination, and "always in the middle" narrows four
# options to two, which is worse than the tell it replaced.
#
# The spread will not come out perfectly flat. Terminology questions have an
# irreducible floor: the four cells of a BCG matrix are "cash cow", "star",
# "question mark" and "dog", and padding those to equal length would wreck the
# question to beat a metric. The target is that length stops being worth
# betting on in any direction, not that every choice matches to the byte.

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


def rank_spread(rows):
    """Share of questions where the correct answer is the Nth longest choice.

    Returns four figures, longest first. A tie splits its credit across the
    ranks it spans, so four equal-length choices contribute 25% to each rank
    rather than pretending to an order the student cannot see. Flat is 25%
    across the board; each figure is also the expected score of the strategy
    "always pick the Nth longest".
    """
    if not rows:
        return [0.0] * 4
    spread = [0.0] * 4
    for _, lens, correct in rows:
        longer = sum(1 for L in lens if L > lens[correct])
        tied = sum(1 for L in lens if L == lens[correct])
        for rank in range(longer, longer + tied):
            spread[rank] += 1.0 / tied
    return [s / len(rows) for s in spread]


def worst_deviation(spread):
    """How far the most lopsided rank sits from an even 25%."""
    return max(abs(s - 0.25) for s in spread)


def report_shape(shapes):
    """Prints the choice-shape report and returns the list of violations."""
    problems = []
    print("\nchoice shape — can a student score without reading the question?")
    print("  share of questions where the correct answer is the Nth longest choice")
    print(f"  {'cluster':<18} {'longest':>8} {'2nd':>7} {'3rd':>7} {'shortest':>9}"
          f" {'off flat':>9} {'ratio':>7} {'lead':>6}")

    all_rows = [r for rows in shapes.values() for r in rows]
    for name, rows in sorted(shapes.items()):
        if not rows:
            continue
        cluster = name[len("SeedQuestions+"):-len(".swift")]

        spread = rank_spread(rows)
        deviation = worst_deviation(spread)

        cor = [lens[correct] for _, lens, correct in rows]
        wrong = [L for _, lens, correct in rows
                 for i, L in enumerate(lens) if i != correct]
        ratio = statistics.mean(cor) / statistics.mean(wrong) if wrong else 0.0

        leads = [(lens[correct] - max(L for i, L in enumerate(lens) if i != correct), key)
                 for key, lens, correct in rows]
        worst, worst_key = max(leads)

        flag = ""
        if deviation > MAX_RANK_DEVIATION:
            flag += " !spread"
            worst_rank = max(range(4), key=lambda r: abs(spread[r] - 0.25))
            label = ["longest", "2nd longest", "3rd longest", "shortest"][worst_rank]
            problems.append(f"{cluster}: correct answer is the {label} choice "
                            f"{spread[worst_rank]:.1%} of the time, should be near 25%")
        if ratio > MAX_MEAN_RATIO:
            flag += " !ratio"
            problems.append(f"{cluster}: correct choice averages {ratio:.2f}x the "
                            f"distractors, limit {MAX_MEAN_RATIO:.2f}x")
        print(f"  {cluster:<18} " + " ".join(f"{s:7.1%}" for s in spread)
              + f" {deviation:8.1%} {ratio:6.2f}x {worst:+5d}{flag}")

        for lead, key in leads:
            if lead > MAX_LEAD:
                problems.append(f"{cluster}/{key}: correct choice leads the field by "
                                f"{lead} chars, limit {MAX_LEAD}")

    if all_rows:
        over = sum(1 for _, lens, correct in all_rows
                   if lens[correct] - max(L for i, L in enumerate(lens) if i != correct) > MAX_LEAD)
        spread = rank_spread(all_rows)
        print(f"\n  whole bank: " + "  ".join(
            f"{label} {s:.1%}" for label, s in
            zip(["longest", "2nd", "3rd", "shortest"], spread)) + "   (flat = 25.0%)")
        print(f"  questions leading by more than {MAX_LEAD} chars: {over}")
        if not ENFORCE_SHAPE:
            print("  (reporting only — ENFORCE_SHAPE is off while the bank is "
                  "brought up to standard)")
    return problems

if __name__ == "__main__":
    main()
