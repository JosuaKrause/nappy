"""The two readings of the pass's row rule side by side: the seed tree, the branch (a row's share
compared among the rows a bag holds) and the other reading (a row's share read against the whole
seed, `pass_rows_against_the_whole_seed_not_applied.log`, applied in a throwaway copy).

Reads the seed probe's output (SL/SE/RD lines), the two cells runs (CL/CE lines) and the two
placement_rows runs (RD lines), and prints, events a city-day:
- for each named row, on the row's days: in a junction box, on a street, on her route, in the city;
- for each view and for the city, what the units place;
- the whole day with the moments, and day 1, days 9 to 11 and day 14 of what the units place.

Usage: python3 -I whole_seed_reading_table.py <seed> <branch cells> <whole-seed cells>
       <branch placement_rows> <whole-seed placement_rows>
"""
import collections
import sys

SEEDS = 18
VIEWS = ["on the route", "route-adjacent", "off the route"]
ROWS = ["charging_dog", "chatting_mother", "leaf_blower", "abduction",
        "delivery_van", "poster_crew", "reversing_lorry", "roadblock", "protest"]


def events(path, tag):
    ev = collections.Counter()
    for line in open(path):
        p = line.split()
        if p and p[0] == tag:
            ev[(int(p[1]), int(p[2]), p[3], p[4])] += int(p[5])
    return ev


def whole_day(path):
    placed, seeds = 0, 0
    for line in open(path):
        p = line.split()
        if p and p[0] == "RD":
            seeds += int(p[2])
            placed += int(p[3])
    return placed / seeds


def main(seed, branch, whole, branch_rows, whole_rows):
    runs = [("seed tree", events(seed, "SE")), ("branch", events(branch, "CE")),
            ("whole seed", events(whole, "CE"))]
    days = sorted({k[0] for _, ev in runs for k in ev})
    print("events a city-day on the row's days: seed tree / branch / whole-seed reading")
    print("  %-17s %-22s %-22s %-22s %-22s" % ("row", "junction box", "street", "her route", "city"))
    for r in ROWS:
        ds = {k[0] for _, ev in runs for k in ev if k[3] == r}
        cols = []
        for pred in (lambda k: k[2] == "junction", lambda k: k[2] == "street",
                     lambda k: k[1] == 0, lambda k: True):
            cols.append(" / ".join("%5.2f" % (sum(n for k, n in ev.items() if k[3] == r and pred(k))
                                               / (SEEDS * len(ds))) for _, ev in runs))
        print("  %-17s %-22s %-22s %-22s %-22s" % (r, *cols))
    print("what the units place, events a city-day: seed tree / branch / whole-seed reading")
    for v in range(3):
        print("  %-15s %s" % (VIEWS[v], " / ".join(
            "%5.1f" % (sum(n for k, n in ev.items() if k[1] == v) / (SEEDS * len(days))) for _, ev in runs)))
    print("  %-15s %s" % ("the city", " / ".join(
        "%5.1f" % (sum(ev.values()) / (SEEDS * len(days))) for _, ev in runs)))
    print("the whole day with the moments (placement_rows.gd), a city-day: seed tree / branch / whole-seed reading")
    print("  %5.1f / %5.1f / %5.1f" % (whole_day(seed), whole_day(branch_rows), whole_day(whole_rows)))
    print("what the units place a city, by day: seed tree / branch / whole-seed reading")
    for d in (1, 9, 10, 11, 14):
        print("  day %2d  %s" % (d, " / ".join(
            "%5.1f" % (sum(n for k, n in ev.items() if k[0] == d) / SEEDS) for _, ev in runs)))
    print("  day 14 over day 1  %s" % " / ".join(
        "x%.2f" % (sum(n for k, n in ev.items() if k[0] == 14) / sum(n for k, n in ev.items() if k[0] == 1))
        for _, ev in runs))


if __name__ == "__main__":
    main(*sys.argv[1:6])
