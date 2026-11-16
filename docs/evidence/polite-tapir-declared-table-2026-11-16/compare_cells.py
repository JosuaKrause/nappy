"""Compares a cells-probe run (CL/CE lines, the units' draws on the new tree) with the seed
measurement (SL/SE lines, main as it stood on 2026-11-09).

Usage: python3 -I compare_cells.py <seed probe output> <cells probe output> [--rows]
"""
import collections
import sys

ACTS = {1: 1, 2: 1, 3: 1, 4: 2, 5: 2, 6: 2, 7: 2, 8: 3, 9: 3, 10: 3, 11: 3, 12: 4, 13: 4, 14: 4}
VIEWS = ["on the route", "route-adjacent", "off the route"]
GROUNDS = ["street", "junction", "alley", "open"]


def read(path, loc_tag, ev_tag, loc_col):
    locs = collections.Counter()
    ev = collections.Counter()
    for line in open(path):
        p = line.split()
        if not p:
            continue
        if p[0] == loc_tag:
            locs[(int(p[1]), int(p[2]), p[3])] += int(p[loc_col])
        elif p[0] == ev_tag:
            ev[(int(p[1]), int(p[2]), p[3], p[4])] += int(p[5])
    return locs, ev


def rate(locs, ev, pred_l, pred_e):
    e = sum(n for k, n in ev.items() if pred_e(k))
    l = sum(n for k, n in locs.items() if pred_l(k))
    return (100.0 * e / l if l else 0.0), e, l


def main(seed_path, cells_path, rows):
    sl, se = read(seed_path, "SL", "SE", 5)
    cl, ce = read(cells_path, "CL", "CE", 5)
    days_new = sorted({k[0] for k in cl})
    days_seed = sorted({k[0] for k in sl})
    n_seed = 18
    # how many seeds the cells run had: street rooms per day vs the seed's
    print("days in the cells run: %s" % days_new)
    print("== per view: events per hundred draw locations, seed -> new (ratio); events a city-day")
    for v in range(3):
        rs, es, ls = rate(sl, se, lambda k: k[1] == v, lambda k: k[1] == v)
        rn, en, ln = rate(cl, ce, lambda k: k[1] == v, lambda k: k[1] == v)
        print("  %-15s %6.2f -> %6.2f  (x%.2f)   locations a city-day %7.1f -> %7.1f" % (
            VIEWS[v], rs, rn, rn / rs if rs else 0, ls / (n_seed * len(days_seed)), ln / (n_seed * len(days_new))))
    rs, es, ls = rate(sl, se, lambda k: True, lambda k: True)
    rn, en, ln = rate(cl, ce, lambda k: True, lambda k: True)
    print("  %-15s %6.2f -> %6.2f  (x%.2f)   events a city-day %6.1f -> %6.1f" % (
        "all", rs, rn, rn / rs, es / (n_seed * len(days_seed)), en / (n_seed * len(days_new))))
    print("== per view and ground, all days: seed -> new (ratio)")
    for v in range(3):
        for g in GROUNDS:
            rs, es, ls = rate(sl, se, lambda k: k[1] == v and k[2] == g, lambda k: k[1] == v and k[2] == g)
            rn, en, ln = rate(cl, ce, lambda k: k[1] == v and k[2] == g, lambda k: k[1] == v and k[2] == g)
            print("  %-15s %-9s %6.2f -> %6.2f  (x%.2f)  events %5d -> %5d" % (
                VIEWS[v], g, rs, rn, rn / rs if rs else 0, es, en))
    print("== per view, ground and act: new (seed)")
    for v in range(3):
        for g in GROUNDS:
            cells = []
            for a in range(1, 5):
                rs, _, _ = rate(sl, se, lambda k: k[1] == v and k[2] == g and ACTS[k[0]] == a,
                                lambda k: k[1] == v and k[2] == g and ACTS[k[0]] == a)
                rn, _, _ = rate(cl, ce, lambda k: k[1] == v and k[2] == g and ACTS[k[0]] == a,
                                lambda k: k[1] == v and k[2] == g and ACTS[k[0]] == a)
                cells.append("%5.1f (%5.1f)" % (rn, rs))
            print("  %-15s %-9s %s" % (VIEWS[v], g, "  ".join(cells)))
    print("== per day: events a city, seed -> new")
    for d in days_new:
        es = sum(n for k, n in se.items() if k[0] == d) / n_seed
        en = sum(n for k, n in ce.items() if k[0] == d) / n_seed
        print("  day %2d %6.1f -> %6.1f (x%.2f)" % (d, es, en, en / es if es else 0))
    if rows:
        print("== per row and ground: events a city-day on the row's days, seed -> new (ratio)")
        names = sorted({k[3] for k in se} | {k[3] for k in ce})
        for g in GROUNDS:
            print("  -- %s" % g)
            for r in names:
                ds = {k[0] for k in se if k[3] == r} | {k[0] for k in ce if k[3] == r}
                es = sum(n for k, n in se.items() if k[3] == r and k[2] == g) / (n_seed * len(ds))
                en = sum(n for k, n in ce.items() if k[3] == r and k[2] == g) / (n_seed * len(ds))
                if es or en:
                    print("     %-20s %7.3f -> %7.3f  (x%s)" % (r, es, en, "%.2f" % (en / es) if es else "inf"))
        print("== per row and view (all grounds): events a city-day on the row's days, seed -> new")
        for r in names:
            ds = {k[0] for k in se if k[3] == r} | {k[0] for k in ce if k[3] == r}
            line = []
            for v in range(3):
                es = sum(n for k, n in se.items() if k[3] == r and k[1] == v) / (n_seed * len(ds))
                en = sum(n for k, n in ce.items() if k[3] == r and k[1] == v) / (n_seed * len(ds))
                line.append("%6.2f->%6.2f" % (es, en))
            print("     %-20s %s" % (r, "   ".join(line)))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], "--rows" in sys.argv)
