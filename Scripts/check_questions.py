#!/usr/bin/env python3
"""Structural checks on the seeded question bank.

Catches the mistakes that are easy to make at volume and invisible on a build:
a duplicate stable key (silently drops a question at seed time), a `why` array
that is not exactly four entries, a correctIndex out of range, and a rationale
list whose "Correct." line does not sit at the correct index.
"""
import re, sys, glob, os

ROOT = "/Users/shail/Desktop/LCVI DECA Study App/LCVI DECA Study App/Data/Questions"

STRING = re.compile(r'"(?:[^"\\]|\\.)*"')

def split_top_level(body):
    """Split a Swift array literal body into top-level string entries."""
    return STRING.findall(body)

def main():
    total, keys, problems = 0, {}, []
    per_cluster = {}

    for path in sorted(glob.glob(os.path.join(ROOT, "*.swift"))):
        src = open(path).read()
        name = os.path.basename(path)
        blocks = re.split(r'\n        q\("', src)[1:]
        per_cluster[name] = len(blocks)
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

    print("questions per file:")
    for k, v in per_cluster.items():
        print(f"  {v:4d}  {k}")
    print(f"total: {total}")
    print(f"unique keys: {len(keys)}")
    if problems:
        print(f"\nPROBLEMS ({len(problems)}):")
        for p in problems:
            print("  " + p)
        sys.exit(1)
    print("\nall structural checks passed")

if __name__ == "__main__":
    main()
