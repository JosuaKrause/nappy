"""What walking the day's routes meets, by day and act (silver-ferret evidence).

Reads the `MET` lines of `probes/later_days_route_walk.gd` (one per city and day: the routes
walked, the seconds walked, the events' gross points as built, the distinct events whose field
reached her, and of those the ones whose row ends the day or pursues her) and prints, per day and
per act, summed over the cities: points a minute walked, events met a minute, events that end the
day or pursue her met a minute, and the same per route.

    python3 -I route_walk.py <later_days_route_walk.log>
"""

import sys
from collections import defaultdict

ACT_START = [1, 4, 8, 12]


def act_of(day: int) -> int:
    return max(i + 1 for i, start in enumerate(ACT_START) if day >= start)


def main() -> None:
    by_day: dict[int, list[float]] = defaultdict(lambda: [0.0] * 5)
    cities: set[str] = set()
    for line in open(sys.argv[1], encoding="utf-8"):
        p = line.split()
        if len(p) != 13 or p[0] != "MET":
            continue
        cities.add(p[1])
        row = by_day[int(p[2])]
        for i, key in enumerate(("routes", "seconds", "events_built", "met", "met_lethal")):
            row[i] += float(p[p.index(key) + 1])

    def show(label: str, r: list[float]) -> str:
        routes, seconds, points, met, lethal = r
        minutes = seconds / 60.0
        return "%s routes %d minutes %.1f | points %.1f a minute | met %.2f a minute, %.1f a " \
            "route | ends the day or pursues %.2f a minute, %.2f a route" % (
                label, routes, minutes, points / minutes, met / minutes, met / routes,
                lethal / minutes, lethal / routes)

    print("# %d cities: %s" % (len(cities), " ".join(sorted(cities))))
    for day in sorted(by_day):
        print(show("WALKDAY %2d" % day, by_day[day]))
    for act in range(1, 5):
        total = [0.0] * 5
        for day, r in by_day.items():
            if act_of(day) == act:
                total = [a + b for a, b in zip(total, r)]
        if total[0]:
            print(show("WALKACT %d" % act, total))


if __name__ == "__main__":
    main()
