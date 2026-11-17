"""The one pass: reads the seed measurement, a cells run made on a table, and that table, and
writes the table scaled once.

- A view whose events per hundred draw locations are off from the seed's by more than a tenth
  has each of its cells multiplied by (the seed's rate in that cell / the run's rate in that
  cell), to two figures, at most CAP. A cell with fewer than MIN_EVENTS events in the seed takes
  the ratio of its view and ground over all acts; where that too has fewer, it is left.
- A row whose share of a ground's events (on the row's days) is off from the seed's by more than
  a factor of two has its weight on that ground multiplied by (seed share / run share), to two
  figures.

A row's share is read against the whole seed, <seed>, every row it counts included: the reading
applied. Given <row seed>, the seed of the rows a unit draws (when the seed's cells count rows no
unit draws, whose events the cells hand to the rest), a row's share is read from it instead, so
that it is compared among the rows a bag holds on both sides: the other reading, printed and not
applied (`pass_rows_among_the_rows_a_bag_holds_not_applied.log`).

Usage: python3 -I one_pass.py <seed> <cells run> <table in.json> <table out.json> [<row seed>]
"""
import collections, json, sys
from math import floor, log10

ACTS = {1: 1, 2: 1, 3: 1, 4: 2, 5: 2, 6: 2, 7: 2, 8: 3, 9: 3, 10: 3, 11: 3, 12: 4, 13: 4, 14: 4}
GROUNDS = ["street", "junction", "alley", "open"]
VIEWS = ["on the route", "route-adjacent", "off the route"]
CAP = 50.0
MIN_EVENTS = 100
VIEW_TOLERANCE = 0.10
ROW_FACTOR = 2.0

def two(x):
    if x == 0:
        return 0.0
    return round(x, 1 - int(floor(log10(abs(x)))))

def read(path, loc_tag, ev_tag):
    locs, ev = collections.Counter(), collections.Counter()
    for line in open(path):
        p = line.split()
        if not p:
            continue
        if p[0] == loc_tag:
            locs[(int(p[1]), int(p[2]), p[3])] += int(p[5])
        elif p[0] == ev_tag:
            ev[(int(p[1]), int(p[2]), p[3], p[4])] += int(p[5])
    return locs, ev

def rate(locs, ev, pl, pe):
    e = sum(n for k, n in ev.items() if pe(k))
    l = sum(n for k, n in locs.items() if pl(k))
    return (100.0 * e / l if l else 0.0), e

sl, se = read(sys.argv[1], "SL", "SE")
cl, ce = read(sys.argv[2], "CL", "CE")
table = json.load(open(sys.argv[3]))
out = json.loads(json.dumps(table))
for v in range(3):
    rs, _ = rate(sl, se, lambda k: k[1] == v, lambda k: k[1] == v)
    rn, _ = rate(cl, ce, lambda k: k[1] == v, lambda k: k[1] == v)
    off = abs(rn / rs - 1.0) > VIEW_TOLERANCE
    print("%-15s seed %.2f run %.2f (x%.2f): %s" % (VIEWS[v], rs, rn, rn / rs, "scaled" if off else "left"))
    if not off:
        continue
    for gi, g in enumerate(GROUNDS):
        gs, ges = rate(sl, se, lambda k: k[1] == v and k[2] == g, lambda k: k[1] == v and k[2] == g)
        gn, _ = rate(cl, ce, lambda k: k[1] == v and k[2] == g, lambda k: k[1] == v and k[2] == g)
        for a in range(1, 5):
            cs, ces = rate(sl, se, lambda k: k[1] == v and k[2] == g and ACTS[k[0]] == a,
                           lambda k: k[1] == v and k[2] == g and ACTS[k[0]] == a)
            cn, _ = rate(cl, ce, lambda k: k[1] == v and k[2] == g and ACTS[k[0]] == a,
                         lambda k: k[1] == v and k[2] == g and ACTS[k[0]] == a)
            if ces >= MIN_EVENTS and cn > 0:
                ratio = cs / cn
            elif ges >= MIN_EVENTS and gn > 0:
                ratio = gs / gn
            else:
                ratio = 1.0
            old = table["density"][str(v)][str(gi)][a - 1]
            out["density"][str(v)][str(gi)][a - 1] = min(CAP, two(old * ratio))
        print("   %-9s %s -> %s" % (g, table["density"][str(v)][str(gi)], out["density"][str(v)][str(gi)]))

def shares(ev, tag_days, r, g):
    days = tag_days
    s_r = sum(n for k, n in ev.items() if k[3] == r and k[2] == g)
    s_all = sum(n for k, n in ev.items() if k[2] == g and k[0] in days)
    return s_r / s_all if s_all else 0.0

if len(sys.argv) > 5:
    _, se = read(sys.argv[5], "SL", "SE")
rows = sorted({k[3] for k in se} | {k[3] for k in ce})
for gi, g in enumerate(GROUNDS):
    for r in rows:
        days = {k[0] for k in list(se) + list(ce) if k[3] == r}
        ss, ns = shares(se, days, r, g), shares(ce, days, r, g)
        if ss == 0 or ns == 0:
            continue
        ratio = ss / ns
        if ratio > ROW_FACTOR or ratio < 1.0 / ROW_FACTOR:
            old = float(table["ground"].get(r, {}).get(str(gi), 1.0))
            out["ground"].setdefault(r, {})[str(gi)] = two(old * ratio)
            print("row %-20s on %-9s share %.3f -> %.3f: weight there %s -> %s" % (r, g, ss, ns, old, two(old * ratio)))
json.dump(out, open(sys.argv[4], "w"), indent=1)
