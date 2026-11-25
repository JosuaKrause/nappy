"""The later days' events weighed by the cost table (silver-ferret evidence, not a repository tool).

Reads the probe log of `probes/later_days_rows.gd` (its FLAGS, RD, RV and RM lines) and the pass
tables of `docs/COSTS.md`, and prints, per day and per act, how many events a city-day places and
how hard they are to deal with: the cost table's price of one pass of each placed row weighted by
the day's mix of rows, beside the share of the day's events whose rows end the day or hunt her.

    python3 -I weigh_days.py [--without ROW] <docs/COSTS.md> <later_days_rows.log> [<flags log>]

`--without ROW` leaves one row out of the placed events, as though no unit drew it, to show how
much of a reading that row carries.

A row's price is its pass at the nearest line the table gives (0px, or 20px for a row with a solid
body, whose 0px column is dashed), awake and asleep. "Paid" counts a pass that is a net cost and
takes a pass that nets below zero as 0, since the decay she would have had walking anyway is not
the row's to give back; "net" keeps the sign. A row the table dashes (it pursues or waits for her,
so has no pass) is unpriced and is counted in the share instead.
"""

import re
import sys
from collections import defaultdict

ACT_START = [1, 4, 8, 12]


def act_of(day: int) -> int:
    act = 1
    for i, start in enumerate(ACT_START):
        if day >= start:
            act = i + 1
    return act


def pass_prices(costs: str, heading: str) -> dict[str, float | None]:
    section = costs.split("## " + heading, 1)[1].split("\n## ", 1)[0]
    prices: dict[str, float | None] = {}
    for line in section.splitlines():
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) != 6 or cells[0] in ("id", "") or cells[0].startswith("-"):
            continue
        near = cells[1] if cells[1] != "—" else cells[2]
        prices[cells[0]] = None if near == "—" else float(near)
    return prices


def main() -> None:
    args = sys.argv[1:]
    without = ""
    if args[:1] == ["--without"]:
        without = args[1]
        args = args[2:]
    costs = open(args[0], encoding="utf-8").read()
    log = open(args[1], encoding="utf-8").read().splitlines()
    if len(args) > 2:
        log += open(args[2], encoding="utf-8").read().splitlines()
    awake = pass_prices(costs, "The pass — awake")
    asleep = pass_prices(costs, "The pass — asleep")
    flags: dict[str, tuple[int, int, int, int]] = {}
    seeds = 0
    rd: dict[int, tuple[int, int]] = {}
    rv: dict[int, dict[tuple[str, int], int]] = defaultdict(dict)
    rm: dict[int, dict[str, int]] = defaultdict(dict)
    for line in log:
        parts = line.split()
        if not parts:
            continue
        if parts[0] == "FLAGS" and len(parts) == 6:
            flags[parts[1]] = (int(parts[2]), int(parts[3]), int(parts[4]), int(parts[5]))
        elif parts[0] == "RD" and len(parts) == 5:
            seeds = int(parts[2])
            rd[int(parts[1])] = (int(parts[3]), int(parts[4]))
        elif parts[0] == "RV" and len(parts) == 5 and parts[2] != without:
            rv[int(parts[1])][(parts[2], int(parts[3]))] = int(parts[4])
        elif parts[0] == "RM" and len(parts) == 4:
            rm[int(parts[1])][parts[2]] = int(parts[3])
    missing = sorted({row for d in rv.values() for row, _ in d} - set(flags) - set())
    if missing:
        sys.exit("rows with no FLAGS line: %s" % missing)
    unknown = sorted({row for d in rv.values() for row, _ in d} - set(awake))
    if unknown:
        sys.exit("rows the cost table does not list: %s" % unknown)

    def lethal(row: str) -> bool:
        return bool(flags[row][0] or flags[row][1])

    def with_rung(row: str) -> bool:
        return lethal(row) or bool(flags[row][3])

    def only_waits(row: str) -> bool:
        return bool(flags[row][2]) and not lethal(row)

    rows_out: list[tuple[int, defaultdict[str, float]]] = []
    for day in sorted(rv):
        counts = rv[day]
        r: dict[str, float] = defaultdict(float)
        for (row, view), n in counts.items():
            for scope in ("all", "route") if view == 0 else ("all",):
                r[scope + " placed"] += n
                if lethal(row):
                    r[scope + " lethal"] += n
                if with_rung(row):
                    r[scope + " rung"] += n
                if only_waits(row):
                    r[scope + " waits"] += n
                if awake[row] is None:
                    r[scope + " unpriced"] += n
                    continue
                r[scope + " priced"] += n
                r[scope + " paid awake"] += n * max(0.0, awake[row] or 0.0)
                r[scope + " paid asleep"] += n * max(0.0, asleep[row] or 0.0)
                r[scope + " net awake"] += n * (awake[row] or 0.0)
                if (awake[row] or 0.0) > 0.0:
                    r[scope + " costly"] += n
        for row, n in rm.get(day, {}).items():
            r["moments"] += n
            price = awake.get(row)
            if price is None:
                r["moments unpriced"] += n
            else:
                r["moments paid awake"] += n * max(0.0, price)
            if lethal(row):
                r["moments lethal"] += n
        r["rd placed"], r["rd moments"] = rd.get(day, (0, 0))
        rows_out.append((day, defaultdict(float, {k: v / seeds for k, v in r.items()})))

    print("# Per row: price of one pass, awake / asleep (nearest line), flags")
    placed_rows = {row for d in rv.values() for row, _ in d}
    seen = sorted(placed_rows | {row for d in rm.values() for row in d})
    for row in seen:
        f = flags.get(row, (0, 0, 0, 0))
        print("ROW %-20s %6s %6s  ends %d pursues %d waits %d hunts %d" % (
            row, "-" if awake.get(row) is None else "%.1f" % awake[row],
            "-" if asleep.get(row) is None else "%.1f" % asleep[row], *f))

    def line(label: str, r: dict[str, float], scope: str) -> str:
        placed = r[scope + " placed"]
        priced = r[scope + " priced"]
        return "%s placed %.1f | lethal %.1f (%.1f%%) | with rung %.1f (%.1f%%) | waits %.1f | " \
            "priced %.1f, costly %.1f | paid awake %.1f a city-day, %.2f an event | " \
            "paid asleep %.1f, %.2f | net awake %.2f an event" % (
                label, placed, r[scope + " lethal"], 100 * r[scope + " lethal"] / placed,
                r[scope + " rung"], 100 * r[scope + " rung"] / placed, r[scope + " waits"],
                priced, r[scope + " costly"], r[scope + " paid awake"],
                r[scope + " paid awake"] / priced, r[scope + " paid asleep"],
                r[scope + " paid asleep"] / priced, r[scope + " net awake"] / priced)

    for scope in ("all", "route"):
        print("\n# %s: per day, a city-day (sums over the seeds / %d)" % (
            "The whole city" if scope == "all" else "On her route (view 0)", seeds))
        for day, r in rows_out:
            print(line("DAY %2d" % day, r, scope))
        print("# per act, the mean of its days")
        for act in range(1, 5):
            days = [r for d, r in rows_out if act_of(d) == act]
            mean: dict[str, float] = defaultdict(float)
            for r in days:
                for k, v in r.items():
                    mean[k] += v / len(days)
            print(line("ACT %d" % act, mean, scope))
    print("\n# The rows that carry the paid points, per act: "
          "row count a city-day, paid awake a city-day")
    for act in range(1, 5):
        acts_days = [d for d in rv if act_of(d) == act]
        count: dict[str, float] = defaultdict(float)
        for d in acts_days:
            for (row, _view), n in rv[d].items():
                count[row] += n / seeds / len(acts_days)
        paid_by = {row: c * max(0.0, awake[row] or 0.0) for row, c in count.items()}
        top = sorted(paid_by.items(), key=lambda kv: -kv[1])[:8]
        print("TOPACT %d %s" % (act, ", ".join("%s %.1f / %.1f" % (row, count[row], p)
                                               for row, p in top)))
    print("\n# The moments the dawn owes her, a city-day (sent ahead of her, not placed)")
    for day, r in rows_out:
        print("MOM %2d moments %.1f (RD %.1f) | lethal %.1f | unpriced %.1f | paid awake %.1f" % (
            day, r["moments"], r["rd moments"], r["moments lethal"], r["moments unpriced"],
            r["moments paid awake"]))
    print("# per act, the mean of its days, and the moments' rows")
    for act in range(1, 5):
        days = [r for d, r in rows_out if act_of(d) == act]
        n = len(days)
        moments = sum(r["moments"] for r in days) / n
        paid = sum(r["moments paid awake"] for r in days) / n
        lethal_m = sum(r["moments lethal"] for r in days) / n
        by_row: dict[str, float] = defaultdict(float)
        for d, per_row in rm.items():
            if act_of(d) == act:
                for row, count in per_row.items():
                    by_row[row] += count / seeds / n
        mix = ", ".join("%s %.1f" % (row, c) for row, c in
                        sorted(by_row.items(), key=lambda kv: -kv[1]))
        print("MOMACT %d moments %.1f | lethal %.1f | paid awake %.1f a city-day, "
              "%.2f a moment | %s" % (act, moments, lethal_m, paid, paid / moments if moments else 0.0, mix))
    print("\n# RD placed a city-day against the RV sum")
    for day, r in rows_out:
        print("RDCHK %2d %.1f %.1f" % (day, r["rd placed"], r["all placed"]))


if __name__ == "__main__":
    main()
