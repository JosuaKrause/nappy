"""Her route's draw locations and what the units place on them, by act (silver-ferret evidence).

Reads the `CL` and `CE` lines of `tests/probes/placement_cells.gd` and prints, for each view,
kind of ground and act, the draw locations a city-day, the events the units placed there a
city-day and the events for every hundred draw locations, beside the declared table's cell
(`PlacementDensity.EVENTS_PER_HUNDRED` as the measured tree has it, copied below).

    python3 -I route_cells.py [--cell VIEW GROUND ACT VALUE] <placement_cells.log> [seeds]

`--cell` prints one cell as a run with that cell changed had it (view and ground by index, the
act 1 to 4), so the cell column stays true for such a run.
"""

import sys
from collections import defaultdict

ACT_START = [1, 4, 8, 12]
GROUNDS = ["street", "junction", "alley", "open"]
VIEWS = ["on her route", "route-adjacent", "off the route"]
# PlacementDensity.EVENTS_PER_HUNDRED on the measured tree, [view][ground][act - 1].
CELLS = [
    [[7.5, 11.0, 14.0, 16.0], [24.0, 36.0, 35.0, 46.0], [0.0, 0.0, 0.0, 0.0],
     [46.0, 50.0, 50.0, 50.0]],
    [[6.0, 6.7, 8.1, 9.5], [2.5, 2.5, 2.5, 2.5], [5.0, 4.9, 6.6, 6.1],
     [40.0, 47.0, 50.0, 50.0]],
    [[4.4, 6.6, 9.8, 11.0], [7.0, 13.0, 20.0, 35.0], [5.4, 4.7, 12.0, 9.7],
     [35.0, 50.0, 50.0, 50.0]],
]


def act_of(day: int) -> int:
    return max(i + 1 for i, start in enumerate(ACT_START) if day >= start)


def main() -> None:
    args = sys.argv[1:]
    if args[:1] == ["--cell"]:
        view, ground, act, value = args[1:5]
        CELLS[int(view)][int(ground)][int(act) - 1] = float(value)
        args = args[5:]
    seeds = int(args[1]) if len(args) > 1 else 18
    room: dict[tuple[int, int, str], int] = defaultdict(int)
    events: dict[tuple[int, int, str], int] = defaultdict(int)
    days_in: dict[int, set[int]] = defaultdict(set)
    for line in open(args[0], encoding="utf-8"):
        p = line.split()
        if len(p) == 6 and p[0] == "CL":
            act = act_of(int(p[1]))
            days_in[act].add(int(p[1]))
            room[(act, int(p[2]), p[3])] += int(p[5])
        elif len(p) == 6 and p[0] == "CE":
            events[(act_of(int(p[1])), int(p[2]), p[3])] += int(p[5])
    for view, name in enumerate(VIEWS):
        print("# %s: draw locations a city-day | events a city-day | per hundred | cell" % name)
        for act in range(1, 5):
            city_days = seeds * len(days_in[act])
            cells = []
            total_room = 0
            total_events = 0
            for g, ground in enumerate(GROUNDS):
                r = room[(act, view, ground)]
                e = events[(act, view, ground)]
                total_room += r
                total_events += e
                cells.append("%s %.1f | %.2f | %.2f | %.1f" % (
                    ground, r / city_days, e / city_days, 100 * e / r if r else 0.0,
                    CELLS[view][g][act - 1]))
            print("CELLS view %d act %d all %.1f | %.2f | %.2f ;; %s" % (
                view, act, total_room / city_days, total_events / city_days,
                100 * total_events / total_room if total_room else 0.0, " ;; ".join(cells)))


if __name__ == "__main__":
    main()
