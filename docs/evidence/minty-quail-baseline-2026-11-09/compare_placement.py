"""The remeasure list for grassy-magpie, generated from placement_rows.gd logs (main and head per sample).

Rule: a cell is a count summed over the sample's cities; z = (head - main) / sqrt(head + main).
(b) lists every cell with |z| > 2 pooled over all samples; (c) every cell with |z| > 2 on at least
two samples with the same sign. Cells: row x kind of ground, row x view, row x day, view x day,
walls and friction x view x day, walls and friction x view, and the day's whole count.
"""
import math, collections
import os
HERE = os.path.dirname(os.path.abspath(__file__))
SAMPLES = [
    ("90210+31i", 18, os.path.join(HERE, "raw/placement_rows_before.log"), os.path.join(HERE, "raw/placement_rows_today.log")),
]
VIEWS = ["on her route", "route-adjacent", "off the route"]
ROLE = {}
for line in open(os.path.join(HERE, "raw/placement_roles.log")):
    f = line.split()
    if f and f[0] == "ROLE":
        ROLE[(int(f[1]), f[2])] = {1: "walls", 2: "friction"}.get(int(f[3]))
def cells(path):
    c = collections.Counter()
    for line in open(path):
        f = line.split()
        if not f:
            continue
        if f[0] == "RD":
            d = int(f[1]); c[("the day's whole count", "", "day %d" % d, 1)] += int(f[3])
        elif f[0] == "RV":
            d, row, v, n = int(f[1]), f[2], int(f[3]), int(f[4])
            c[("row by view", row, VIEWS[v], 14)] += n
            c[("_row by view and day", row, "%s day %d" % (VIEWS[v], d), 1)] += n
            c[("row by day", row, "day %d" % d, 1)] += n
            c[("view by day", VIEWS[v], "day %d" % d, 1)] += n
            role = ROLE.get((d, row))
            if role:
                c[("%s by view and day" % role, VIEWS[v], "day %d" % d, 1)] += n
                c[("%s by view" % role, VIEWS[v], "all days", 14)] += n
        elif f[0] == "RK":
            d, row, k, n = int(f[1]), f[2], f[3], int(f[4])
            c[("row by kind of ground", row, k, 14)] += n
    return c
data = []
for name, n, m, h in SAMPLES:
    data.append((name, n, cells(m), cells(h)))
N = sum(d[1] for d in data)
keys = set()
for _, _, a, b in data:
    keys |= set(a) | set(b)
def z(a, b):
    return (b - a) / math.sqrt(a + b) if a + b else 0.0
def fig(a, b, n, days):
    pct = "%+.0f%%" % (100.0 * (b - a) / a) if a else "new"
    return "%.2f → %.2f (%s, z %+.1f)" % (a / n / days, b / n / days, pct, z(a, b))
pooled, repeated = [], []
for key in keys:
    fam, what, where, days = key
    if fam.startswith("_"):
        continue
    A = sum(d[2][key] for d in data); B = sum(d[3][key] for d in data)
    per = [(name, d2[key], d3[key], n) for name, n, d2, d3 in data]
    zs = [z(a, b) for _, a, b, _ in per]
    line = "%s: %s%s, %s; z per sample %s" % (fam, what + " " if what else "", where, fig(A, B, N, days),
            " / ".join("%+.1f" % x for x in zs))
    if abs(z(A, B)) > 2:
        pooled.append((abs(z(A, B)), line))
    if sum(1 for x in zs if x > 2) >= 2 or sum(1 for x in zs if x < -2) >= 2:
        repeated.append((max(abs(x) for x in zs), line))
def patrol_days():
    out = []
    for d in range(4, 15):
        key = ("_row by view and day", "police_patrol", "on her route day %d" % d, 1)
        A = sum(x[2][key] for x in data); B = sum(x[3][key] for x in data)
        out.append("day %d %.2f → %.2f" % (d, A / N, B / N))
    return ", ".join(out)
ON_PURPOSE = [
    "Day 13's roadblocks are the roadblock phase's alone; the fill's day-13 roadblocks are gone, and the task swaps more often for it.",
    "The moments she is owed are a fixed count per day (EventScheduler.MOMENTS_PER_DAY, 23 to 32), where the fill's rolls made them vary by city.",
    "The gatehouse day's share scales every wall-role row's cap as well as its weight, the cap's fraction rounded up or down on its own stream.",
    "A junction box is one location, the whole box (its corners, its carriageway and its crossings).",
]
UNSEEN = [
    "Dawn planning time: +38% inside EventScheduler.build_day() (167 s → 232 s over 14 cities × 14 days) and +24% for the whole probe run, the reviewer's paired measurement at a04fa7589; remeasured in 3b, where _judge() goes.",
    "test_checkpoints' bound on what the doors' gap costs the day is loosened from 0.9 to 0.8 of the events placed without it.",
    "The probe plans at heat 0, with no region doors and nothing standing, so a row's share at heat (the police patrol's raised share among them) is not measured.",
]
PATROL = patrol_days()
print("(b) Outside 2σ pooled over all %d cities (%s), events per city per day, before → today:" % (N, ", ".join("%s (%d)" % (d[0], d[1]) for d in data)))
for _, line in sorted(pooled, key=lambda x: (x[1].split(":")[0], -x[0])):
    print("- " + line)
print()
print("(c) Outside 2σ on at least two samples with the same sign (z per sample in the order of (b)):")
for _, line in sorted(repeated, key=lambda x: (x[1].split(":")[0], -x[0])):
    print("- " + line)
print()
print("Summary, pooled over all %d cities:" % N)
for fam in ["walls by view", "friction by view"]:
    for v in VIEWS:
        key = (fam, v, "all days", 14)
        A = sum(d[2][key] for d in data); B = sum(d[3][key] for d in data)
        print("- %s, %s: %s" % (fam, v, fig(A, B, N, 14)))
for fam, label in [("row by kind of ground", "each row per kind of ground"), ("row by view", "each row per view")]:
    ch = []
    for key in keys:
        if key[0] != fam:
            continue
        A = sum(d[2][key] for d in data); B = sum(d[3][key] for d in data)
        if A:
            ch.append((100.0 * (B - A) / A, key, abs(z(A, B)) > 2))
        elif B:
            ch.append((float("inf"), key, abs(z(A, B)) > 2))
    ch.sort()
    inside = [c for c in ch if not c[2]]
    print("- %s: %d cells, every cell main or head has, from %+.0f%% (%s %s) to %+.0f%% (%s %s); within 2σ, from %+.0f%% to %+.0f%%" % (label, len(ch),
            ch[0][0], ch[0][1][1], ch[0][1][2], ch[-1][0], ch[-1][1][1], ch[-1][1][2], inside[0][0], inside[-1][0]))
print()
print("Cells compared: %d. Outside 2σ pooled: %d. Outside on two samples or more, same sign: %d." % (sum(1 for k in keys if not k[0].startswith("_")), len(pooled), len(repeated)))
