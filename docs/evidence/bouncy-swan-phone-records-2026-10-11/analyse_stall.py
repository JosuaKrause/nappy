"""Compares a before and an after run of the day-9 replay rig.

usage: analyse_stall.py <before.log> <after.log> [more before/after pairs...]

Reads the rig's own lines: `LOOK` (one per look of the walk siting: its physics tick, the
siting's time in microseconds, her position and the three siting streams' states after it),
`SITED` (each plan a look sited: position, path, facing, role) and `EVT` (the event manager's
whole physics tick in microseconds, and the siting's share of it). Checks that both sides sited
the same plans and left the streams in the same states, look for look, over the ticks both runs
reached, then prints the stalled look's time and the per-look and per-tick distributions.
"""
import re
import statistics
import sys


def read(path):
    looks, sited, ticks, judge = [], [], {}, []
    for line in open(path, errors="replace"):
        if line.startswith("LOOK "):
            m = dict(kv.split("=", 1) for kv in re.findall(r"(\w+=\([^)]*\)|\w+=\S+)", line))
            looks.append(m)
        elif line.startswith("SITED "):
            sited.append(line.strip())
        elif line.startswith("EVT "):
            m = dict(kv.split("=") for kv in line.split()[1:])
            ticks[int(m["tick"])] = (int(m["usec"]), int(m["site"]))
        elif line.startswith("JUDGE "):
            judge.append(line.strip())
    return looks, sited, ticks, judge


def pct(values, q):
    values = sorted(values)
    return values[min(len(values) - 1, int(len(values) * q))]


def describe(name, values):
    return "%s n=%d median=%d p95=%d p99=%d max=%d (us)" % (
        name, len(values), statistics.median(values), pct(values, 0.95), pct(values, 0.99),
        max(values))


def compare(before_path, after_path):
    b_looks, b_sited, b_ticks, _ = read(before_path)
    a_looks, a_sited, a_ticks, a_judge = read(after_path)
    last = min(max(b_ticks), max(a_ticks))
    b_l = [l for l in b_looks if int(l["tick"]) <= last]
    a_l = [l for l in a_looks if int(l["tick"]) <= last]
    keys = ("n", "pos", "walk", "crew", "place")
    same_looks = [tuple(l[k] for k in keys) for l in b_l] == [tuple(l[k] for k in keys) for l in a_l]
    # The manager's tick count starts on its own first physics frame, which can fall a tick either
    # side of the replay's start, so plans are compared without their tick.
    b_s = [s.split(" ", 2)[2] for s in b_sited if int(s.split()[1].split("=")[1]) <= last]
    a_s = [s.split(" ", 2)[2] for s in a_sited if int(s.split()[1].split("=")[1]) <= last]
    print("== %s vs %s" % (before_path, after_path))
    print("ticks compared: 1..%d; looks %d/%d; sited %d/%d" % (last, len(b_l), len(a_l),
                                                               len(b_s), len(a_s)))
    print("looks identical (position, stream states): %s" % same_looks)
    print("sited plans identical (position, path, facing, role): %s" % (b_s == a_s))
    for s in b_s:
        print("  sited: " + s)
    stall = max(b_l, key=lambda l: int(l["usec"]))
    twin = next(l for l in a_l if l["n"] == stall["n"])
    st = int(stall["tick"])
    at_ = int(twin["tick"])
    print("stalled look n=%s tick=%s at %s: siting %d us before, %d us after" % (
        stall["n"], stall["tick"], stall["pos"], int(stall["usec"]), int(twin["usec"])))
    print("  its whole events tick: %d us before, %d us after" % (b_ticks[st][0], a_ticks[at_][0]))
    for side, looks in (("before", b_l), ("after", a_l)):
        print("  " + describe(side + " siting per look", [int(l["usec"]) for l in looks]))
    for side, ticks in (("before", b_ticks), ("after", a_ticks)):
        look_ticks = {int(l["tick"]) for l in (b_l if side == "before" else a_l)}
        print("  " + describe(side + " events tick, look ticks", [ticks[t][0] for t in sorted(look_ticks)]))
        print("  " + describe(side + " events tick, every tick",
                              [ticks[t][0] for t in range(1, last + 1) if t in ticks]))
    for j in a_judge:
        if j.split()[1] == "n=" + stall["n"]:
            print("  after, judgements counter at the stalled look: " + j)
    return same_looks and b_s == a_s


ok = True
args = sys.argv[1:]
for i in range(0, len(args), 2):
    ok = compare(args[i], args[i + 1]) and ok
sys.exit(0 if ok else 1)
