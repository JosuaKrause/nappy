"""Reads the seed probe's SL/SE lines and prints the declared table's seed.

Usage: python3 -I seed_table.py <seed probe output>
"""
import collections
import sys

ACTS = {1: 1, 2: 1, 3: 1, 4: 2, 5: 2, 6: 2, 7: 2, 8: 3, 9: 3, 10: 3, 11: 3, 12: 4, 13: 4, 14: 4}
WALLS = {"cafe_tables", "delivery_van", "market_stall", "leaf_blower", "construction",
         "ice_cream_van", "reversing_lorry", "charging_dog", "abduction", "alley_robbery",
         "military_convoy"}
WALL_SHARE_FROM = 9
WALL_SHARE = 0.5
VIEWS = ["on the route", "route-adjacent", "off the route"]
GROUNDS = ["street", "junction", "alley", "open"]
SEEDS = 18


def two(x):
    if x == 0:
        return "0"
    from math import floor, log10
    digits = 1 - int(floor(log10(abs(x))))
    r = round(x, digits)
    return ("%g" % r)


def main(path):
    locs = collections.Counter()      # (day, view, ground) -> open
    avail = collections.Counter()
    ev = collections.Counter()        # (day, view, ground, row) -> count
    for line in open(path):
        p = line.split()
        if not p:
            continue
        if p[0] == "SL":
            locs[(int(p[1]), int(p[2]), p[3])] += int(p[5])
            avail[(int(p[1]), int(p[2]), p[3])] += int(p[4])
        elif p[0] == "SE":
            ev[(int(p[1]), int(p[2]), p[3], p[4])] += int(p[5])

    def full(day, row, n):
        return n / WALL_SHARE if (day >= WALL_SHARE_FROM and row in WALLS) else n

    print("== draw locations per city-day, by ground (open / available), all days")
    for g in GROUNDS:
        o = sum(n for (d, v, gg), n in locs.items() if gg == g)
        a = sum(n for (d, v, gg), n in avail.items() if gg == g)
        print("  %-9s %7.1f / %7.1f" % (g, o / (14 * SEEDS), a / (14 * SEEDS)))
    print("== draw locations per city-day by view and ground, per act")
    for v in range(3):
        for g in GROUNDS:
            row = []
            for a in range(1, 5):
                days = [d for d in ACTS if ACTS[d] == a]
                row.append(sum(locs[(d, v, g)] for d in days) / (len(days) * SEEDS))
            print("  %-15s %-9s %s" % (VIEWS[v], g, " ".join("%7.1f" % x for x in row)))

    print("== events per hundred draw locations, AS PLAYED: view, ground, acts I-IV | all")
    played = {}
    for v in range(3):
        for g in GROUNDS:
            row = []
            for a in range(1, 5):
                days = [d for d in ACTS if ACTS[d] == a]
                e = sum(n for (d, vv, gg, r), n in ev.items() if vv == v and gg == g and d in days)
                l = sum(locs[(d, v, g)] for d in days)
                row.append(100.0 * e / l if l else 0.0)
            e = sum(n for (d, vv, gg, r), n in ev.items() if vv == v and gg == g)
            l = sum(locs[(d, v, g)] for d in ACTS)
            print("  %-15s %-9s %s | %6.2f  (%d events, %d locations)" % (
                VIEWS[v], g, " ".join("%6.2f" % x for x in row), 100.0 * e / l if l else 0, e, l))
    print("== the seed: events per hundred draw locations at FULL wall share, two figures")
    seed = {}
    for v in range(3):
        for g in GROUNDS:
            row = []
            for a in range(1, 5):
                days = [d for d in ACTS if ACTS[d] == a]
                e = sum(full(d, r, n) for (d, vv, gg, r), n in ev.items()
                        if vv == v and gg == g and d in days)
                l = sum(locs[(d, v, g)] for d in days)
                row.append(100.0 * e / l if l else 0.0)
            seed[(v, g)] = row
            print("  %-15s %-9s %s      raw %s" % (VIEWS[v], g, " ".join("%6s" % two(x) for x in row),
                                              " ".join("%6.2f" % x for x in row)))
    print("== per view, as played: events / hundred draw locations (the scaling pass's target)")
    for v in range(3):
        e = sum(n for (d, vv, gg, r), n in ev.items() if vv == v)
        l = sum(n for (d, vv, gg), n in locs.items() if vv == v)
        print("  %-15s %6.2f  (%d events over %d locations; %.1f events a city-day)" % (
            VIEWS[v], 100.0 * e / l, e, l, e / (14 * SEEDS)))
    print("== per day: events drawn per city, as played")
    for d in range(1, 15):
        e = sum(n for (dd, vv, gg, r), n in ev.items() if dd == d)
        print("  day %2d %6.1f" % (d, e / SEEDS))

    print("== rows by ground: events a city-day on the days the row is drawn (full wall share)")
    rows = sorted({r for (d, v, g, r) in ev})
    days_of = {r: sorted({d for (d, v, g, rr) in ev if rr == r}) for r in rows}
    print("  %-20s days  %s" % ("row", " ".join("%9s" % g for g in GROUNDS)))
    rate = {}
    for r in rows:
        nd = len(days_of[r])
        line = []
        for g in GROUNDS:
            e = sum(full(d, rr, n) for (d, v, gg, rr), n in ev.items() if rr == r and gg == g)
            rate[(r, g)] = e / (nd * SEEDS)
            line.append(rate[(r, g)])
        print("  %-20s %2d-%2d %s" % (r, days_of[r][0], days_of[r][-1], " ".join("%9.3f" % x for x in line)))
    print("== rows by ground and view, events over the whole sample (as played)")
    for g in GROUNDS:
        print("  -- %s" % g)
        for r in rows:
            c = [sum(n for (d, v, gg, rr), n in ev.items() if rr == r and gg == g and v == vv) for vv in range(3)]
            if sum(c):
                print("     %-20s %6d %6d %6d" % (r, c[0], c[1], c[2]))
    return rate, days_of


if __name__ == "__main__":
    main(sys.argv[1])
