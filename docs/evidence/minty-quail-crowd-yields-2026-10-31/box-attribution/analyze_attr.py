"""Tables from the ATTR_JSON / CROWD_CADENCE_JSON lines of attr-<rev>.txt (ungzipped).
usage: analyze_attr.py attr-base.txt attr-head.txt"""
import json, sys, collections

TICK = 1 / 30


def load(path):
    cad, attr = {}, {}
    for line in open(path):
        if line.startswith("CROWD_CADENCE_JSON "):
            r = json.loads(line.split(" ", 1)[1])
            cad[(r["seed"], r["day"], r["walk"])] = r
        elif line.startswith("ATTR_JSON "):
            r = json.loads(line.split(" ", 1)[1])
            lab = r["label"]
            attr[(lab["seed"], lab["day"], lab["walk"])] = r
    return cad, attr


def root_cat(key):
    # "cat|row|state"
    cat, row, state = key.split("|")
    return cat, row, state


def table(name, cad, attr):
    print(f"\n### {name}: {len(attr)} runs, box_stalls {sum(c['box_stalls'] for c in cad.values())}, "
          f"sum of longest box stands {sum(c['longest_box_stand'] for c in cad.values()):.0f}s")
    # seconds by root cause over every second a car stood in a box
    tot = collections.Counter()
    fig_rows = collections.Counter()
    geom = collections.Counter()
    for r in attr.values():
        for k, v in r["totals"].items():
            if k.startswith("root:"):
                cat, row, state = root_cat(k[5:])
                tot[cat] += v
                if cat in ("figure", "parked_figure"):
                    fig_rows[(row, state)] += v
            elif k.startswith("geom:"):
                geom[k[5:]] += v
    total = sum(tot.values())
    print(f"\nSeconds a car stood inside a box (speed under 1 px/s), by what the root of its queue stood for (total {total*TICK:.0f}s):")
    print("| root cause | seconds | share |\n|---|---|---|")
    for k, v in tot.most_common():
        print(f"| {k} | {v*TICK:.1f} | {100*v/total:.1f}% |")
    print("\nOf which figure, by row and the figure's state:")
    print("| row | state | seconds |\n|---|---|---|")
    for (row, state), v in fig_rows.most_common():
        print(f"| {row} | {state} | {v*TICK:.1f} |")
    print("\nSeconds in a box with a figure within 120 px ahead in the lane (geometry, regardless of cause):")
    print("| row | state | seconds |\n|---|---|---|")
    for k, v in geom.most_common():
        row, state = k.split("|")
        print(f"| {row} | {state} | {v*TICK:.1f} |")
    flags = collections.Counter()
    for r in attr.values():
        for k, v in r["totals"].items():
            if k.startswith("flags:"):
                flags[k[6:]] += v
    print("\nDirect flags (what the car's own brake components say; '+' joins several):")
    print("| flags | seconds |\n|---|---|")
    for k, v in flags.most_common():
        print(f"| {k} | {v*TICK:.1f} |")
    # stands
    stands = [(s, lab) for lab, r in attr.items() for s in r["stands"]]
    print(f"\nStands of 0.5 s or more: {len(stands)}")
    for lo, hi in [(0.5, 1), (1, 2), (2, 5), (5, 10), (10, 30), (30, 100)]:
        sel = [s for s, _ in stands if lo <= s["ticks"] * TICK < hi]
        print(f"- {lo}-{hi}s: {len(sel)}")
    # stalls (>=5s): root classification of the stand by dominant root cause
    print("\nStalls (stand of 5 s or more), dominant root cause of each (more than half of its ticks), figure row and state:")
    print("| seed | day | walk | seconds | dominant root | row | state | figure share of ticks | figure in view at box entry |")
    print("|---|---|---|---|---|---|---|---|---|")
    for lab, r in sorted(attr.items()):
        for s in r["stands"]:
            if s["ticks"] * TICK < 5:
                continue
            agg = collections.Counter()
            figt = 0
            for k, v in s["root"].items():
                cat, row, state = root_cat(k)
                agg[(cat, row, state)] += v
                if cat in ("figure", "parked_figure"):
                    figt += v
            (cat, row, state), v = agg.most_common(1)[0]
            print(f"| {lab[0]} | {lab[1]} | {lab[2]} | {s['ticks']*TICK:.1f} | {cat} | {row} | {state} | {100*figt/s['ticks']:.0f}% | {s['entry_fig'] or 'no'} |")
    # stands with any figure root ticks
    print("\nStands with 1.0 s or more of figure root cause: ")
    print("| seed | day | walk | stand s | figure s | row:state | figure in view at box entry | ticks in box before standing |")
    print("|---|---|---|---|---|---|---|---|")
    fs = []
    for lab, r in sorted(attr.items()):
        for s in r["stands"]:
            figt = 0
            names = collections.Counter()
            for k, v in s["root"].items():
                cat, row, state = root_cat(k)
                if cat in ("figure", "parked_figure"):
                    figt += v
                    names[f"{row}:{state}"] += v
            if figt * TICK >= 1.0:
                fs.append(figt * TICK)
                print(f"| {lab[0]} | {lab[1]} | {lab[2]} | {s['ticks']*TICK:.1f} | {figt*TICK:.1f} | {dict(names)} | {s['entry_fig'] or 'no'} | {(s['start']-s['entered'])*TICK:.1f} |")
    return stands


def dist(vals):
    vals = sorted(vals)
    if not vals:
        return "none"
    n = len(vals)
    q = lambda p: vals[min(n - 1, int(p * n))]
    return f"n={n} median {q(.5):.1f}s p90 {q(.9):.1f}s max {vals[-1]:.1f}s"


def main():
    (bc, ba), (hc, ha) = load(sys.argv[1]), load(sys.argv[2])
    print(f"base runs {len(bc)}, head runs {len(hc)}")
    table("BASE", bc, ba)
    table("HEAD", hc, ha)
    # figure stands durations, head
    for name, attr in (("base", ba), ("head", ha)):
        runs = []
        for lab, r in attr.items():
            for s in r["stands"]:
                figt = sum(v for k, v in s["root"].items() if root_cat(k)[0] in ("figure", "parked_figure"))
                if figt:
                    runs.append((figt * TICK, s["ticks"] * TICK))
        print(f"\n{name}: stands with any figure-rooted ticks: figure seconds {dist([a for a, _ in runs])}; whole-stand seconds {dist([b for _, b in runs])}")
    # per-pair stall delta
    print("\nStalls per pair, base vs head (stall = a stand of 5 s or more):")
    keys = sorted(set(bc) & set(hc))
    print("| seed | day | walk | base stalls | head stalls | base longest | head longest |\n|---|---|---|---|---|---|---|")
    for k in keys:
        if bc[k]["box_stalls"] != hc[k]["box_stalls"] or abs(bc[k]["longest_box_stand"] - hc[k]["longest_box_stand"]) > 2:
            print(f"| {k[0]} | {k[1]} | {k[2]} | {bc[k]['box_stalls']} | {hc[k]['box_stalls']} | {bc[k]['longest_box_stand']:.1f} | {hc[k]['longest_box_stand']:.1f} |")
    print("\nstalls base", sum(bc[k]["box_stalls"] for k in keys), "head", sum(hc[k]["box_stalls"] for k in keys))
    # cross-check: stands>=5 s counted by my instrumentation vs the probe's own stall count
    for name, cad, attr in (("base", bc, ba), ("head", hc, ha)):
        mine = sum(1 for r in attr.values() for s in r["stands"] if s["ticks"] >= 150)
        print(f"{name}: stands of 150 ticks or more in the attribution {mine}; probe's box_stalls {sum(c['box_stalls'] for c in cad.values())}")


main()
