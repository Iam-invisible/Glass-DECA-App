#!/usr/bin/env python3
"""Structural checks on the widget tip corpus.

A tip has one job: be readable on a lock-screen rectangle at a glance. That
constrains it more than the question bank is constrained, and none of it is
something a compiler can see.

  * a count per cluster, so no cluster quietly ends up with forty
  * a length window — long enough to say something, short enough to fit
  * no duplicates, within a cluster or across the whole corpus, because a
    seeded permutation showing the same sentence twice in one cycle looks
    like a bug in the shuffle rather than a repeated line
  * no unescaped quotes or stray interpolation that would change what ships
"""
import re, sys, glob, os
from collections import Counter

ROOT = "/Users/shail/Desktop/LCVI DECA Study App/DECAStudyWidget/Tips"

# The lock-screen accessoryRectangular family is the tightest surface these
# appear on. Past roughly 150 characters it either truncates or shrinks to a
# size nobody reads at arm's length; under 40 it is a fragment, not a fact.
MIN_LEN, MAX_LEN = 40, 155
TARGET_PER_CLUSTER = 100
TOLERANCE = 4      # "about 100" — a cluster may land a few either side

STRING = re.compile(r'"((?:[^"\\]|\\.)*)"')


def main():
    files = sorted(glob.glob(os.path.join(ROOT, "WidgetTips+*.swift")))
    if not files:
        print("no tip files found — is ROOT right?")
        sys.exit(1)

    problems, per_cluster, everything = [], {}, []

    for path in files:
        name = os.path.basename(path)
        src = open(path, encoding="utf-8").read()
        body = src[src.index("["):src.rindex("]")] if "[" in src else ""
        tips = [m.group(1) for m in STRING.finditer(body)]
        cluster = name[len("WidgetTips+"):-len(".swift")]
        per_cluster[cluster] = tips
        everything.extend((cluster, t) for t in tips)

        if abs(len(tips) - TARGET_PER_CLUSTER) > TOLERANCE:
            problems.append(f"{cluster}: {len(tips)} tips, expected "
                            f"{TARGET_PER_CLUSTER}±{TOLERANCE}")

        for tip in tips:
            shown = tip.replace('\\"', '"')
            if len(shown) < MIN_LEN:
                problems.append(f"{cluster}: {len(shown)} chars, too short — {shown[:60]}")
            if len(shown) > MAX_LEN:
                problems.append(f"{cluster}: {len(shown)} chars, too long — {shown[:60]}…")
            if "\\(" in tip:
                problems.append(f"{cluster}: string interpolation in a tip — {shown[:60]}")
            if shown.strip() != shown:
                problems.append(f"{cluster}: leading or trailing space — {shown[:60]}")

        dupes = [t for t, n in Counter(tips).items() if n > 1]
        for d in dupes:
            problems.append(f"{cluster}: duplicated within the cluster — {d[:60]}")

    across = Counter(t for _, t in everything)
    for tip, n in across.items():
        if n > 1:
            where = sorted({c for c, t in everything if t == tip})
            if len(where) > 1:
                problems.append(f"duplicated across {', '.join(where)} — {tip[:60]}")

    print("tips per cluster:")
    for cluster, tips in sorted(per_cluster.items()):
        lengths = [len(t.replace('\\"', '"')) for t in tips]
        print(f"  {len(tips):4d}  {cluster:<18} "
              f"length {min(lengths)}–{max(lengths)}, mean {sum(lengths)//len(lengths)}")
    print(f"total: {sum(len(v) for v in per_cluster.values())}")
    print(f"unique: {len(across)}")

    if problems:
        print(f"\nPROBLEMS ({len(problems)}):")
        for p in problems[:40]:
            print("  " + p)
        if len(problems) > 40:
            print(f"  ... and {len(problems) - 40} more")
        sys.exit(1)
    print("\nall structural checks passed")


if __name__ == "__main__":
    main()
