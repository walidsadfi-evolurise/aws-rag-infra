#!/usr/bin/env python3
"""Approximate `terraform fmt -check` alignment rule: within a run of consecutive
single-line `key = value` attributes at the same indent, the `=` signs line up.
Used locally where the terraform binary is unavailable; CI runs the real thing."""
import re, sys, pathlib

ATTR = re.compile(r"^(\s*)([A-Za-z_][\w\-]*|\"[^\"]+\")\s*=\s*(.*)$")
bad = 0
for f in sorted(pathlib.Path(sys.argv[1]).rglob("*.tf")):
    lines = f.read_text().splitlines()
    run: list[tuple[int, str, str]] = []
    def flush():
        global bad
        if len(run) < 2:
            return
        width = max(len(k) for _, k, _ in run)
        for ln, k, raw in run:
            expected = re.sub(r"^(\s*)(\S+)\s*=", lambda m: f"{m.group(1)}{m.group(2).ljust(width)} =", raw, count=1)
            if expected != raw:
                bad += 1
                print(f"{f}:{ln}: misaligned (expected {expected.strip()!r})")
    indent = None
    for i, line in enumerate(lines, 1):
        m = ATTR.match(line)
        single = m and not re.search(r"[\[\{\(]\s*$", line) and not line.rstrip().endswith("<<-EOT")
        if single and (indent is None or m.group(1) == indent):
            indent = m.group(1); run.append((i, m.group(2), line)); continue
        flush(); run = []; indent = None
        if single:
            indent = m.group(1); run.append((i, m.group(2), line))
    flush()
print("misaligned lines:", bad)
sys.exit(1 if bad else 0)
