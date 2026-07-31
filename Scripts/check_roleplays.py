#!/usr/bin/env python3
"""Structural checks on the seeded roleplay and Quick Think content.

Catches what the compiler cannot: a duplicate stable key (which silently drops
a scenario at seed time), a cluster whose scenarios all share one event format
(the thing this content was restructured to avoid), and Quick Think ids that
collide.
"""
import re, sys, glob, os, collections

ROOT = "/Users/shail/Desktop/LCVI DECA Study App/LCVI DECA Study App/Data/Roleplays"

def main():
    problems = []

    # --- roleplays -------------------------------------------------------
    keys, per_cluster = {}, collections.defaultdict(list)
    for path in sorted(glob.glob(os.path.join(ROOT, "SeedRoleplays+*.swift"))):
        src = open(path).read()
        name = os.path.basename(path)
        for m in re.finditer(r'rp\("([a-z0-9-]+)",\s*"([^"]+)",\s*\.(\w+),\s*\.(\w+),\s*\.(\w+),', src):
            key, title, cluster, fmt, diff = m.groups()
            if key in keys:
                problems.append(f"duplicate roleplay key {key} ({name} and {keys[key]})")
            keys[key] = name
            per_cluster[cluster].append((key, fmt, diff))

    print("roleplays per cluster:")
    for c, items in sorted(per_cluster.items()):
        fmts = collections.Counter(f for _, f, _ in items)
        print(f"  {len(items):3d}  {c:28s} {dict(fmts)}")
        if len(fmts) < 2 and c != "personalFinancialLiteracy":
            problems.append(f"{c}: only one event format ({list(fmts)}) — the point "
                            "of cluster x format authoring is more than one shape")
    print(f"total roleplays: {len(keys)}")

    # --- quick think -----------------------------------------------------
    qt_src = open(os.path.join(ROOT, "SeedQuickThink.swift")).read()
    qt_ids, qt_cluster = {}, collections.Counter()
    for m in re.finditer(r'\.init\(id:\s*"([^"]+)",\s*cluster:\s*\.(\w+)', qt_src):
        qid, cluster = m.groups()
        if qid in qt_ids:
            problems.append(f"duplicate Quick Think id {qid}")
        qt_ids[qid] = cluster
        qt_cluster[cluster] += 1

    print("\nquick think per cluster:")
    for c, n in sorted(qt_cluster.items()):
        print(f"  {n:3d}  {c}")
    print(f"total quick think: {len(qt_ids)}")

    # every prompt should end in a question or an instruction, not a topic
    for m in re.finditer(r'prompt:\s*"((?:[^"\\]|\\.)*)"', qt_src):
        p = m.group(1)
        if not p.rstrip().endswith(('.', '?', '!')):
            problems.append(f"Quick Think prompt does not end in punctuation: {p[:50]}…")

    if problems:
        print(f"\nPROBLEMS ({len(problems)}):")
        for p in problems:
            print("  " + p)
        sys.exit(1)
    print("\nall structural checks passed")

if __name__ == "__main__":
    main()
