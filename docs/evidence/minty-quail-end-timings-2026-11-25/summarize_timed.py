"""Reads raw/ of this folder (and the baseline's raw/timed for the after-4b column of the crowd tick) and prints the
tables of minty-quail's end remeasure, groups T1 to T5: per round and per side, with the spread (min to max over
rounds). A copy of the baseline's summarize_timed.py (docs/evidence/minty-quail-baseline-2026-11-09/) in its way of
reading the probes' lines, pointed at this folder's side-by-side rounds.
Usage: python3 -I summarize_timed.py   (from anywhere; paths are relative to this file; BASELINE_TIMED names the
baseline folder's raw/timed when it is not the sibling folder, as in a sparse worktree)"""
import glob, gzip, json, os, re, statistics as st
HERE = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(HERE, "raw")
BASE = os.environ.get("BASELINE_TIMED") or os.path.join(HERE, "..", "minty-quail-baseline-2026-11-09", "raw", "timed")

def rd(path):
    """Opens a log or summary whether it is stored plain or gzipped."""
    return gzip.open(path + ".gz", "rt") if not os.path.exists(path) else open(path)

def spread(v, digits=1):
    f = "%%.%df" % digits
    return ("median " + f + " (min " + f + ", max " + f + ")") % (st.median(v), min(v), max(v))

def cases(path, mode):
    """The probe's CROWD_TICK_JSON or TICK_SWEEP_JSON lines of one mode, as dicts."""
    for line in rd(path):
        for tag in ("CROWD_TICK_JSON ", "TICK_SWEEP_JSON "):
            if line.startswith(tag):
                j = json.loads(line[len(tag):])
                if j["mode"] == mode:
                    yield j

def col_median(j, name):
    i = j["columns"].index(name)
    return st.median(r[i] for r in j["rows"])

def key(j):
    return (j["seed"], j["day"], j["walk"], j["repetition"])

def rounds(prefix, n=(1, 2, 3)):
    return [f"{RAW}/{prefix.format(n=i)}.log" for i in n]

print("== T1. dawn planning, seconds, 14 cities x 14 days, per round (end | after-4b side by side)")
for label, pat in (("end", "dawn_end_{n}"), ("after-4b", "dawn_after_4b_side_{n}")):
    b, d, w = [], [], []
    for p in rounds(pat):
        m = re.search(r"build_day_sec ([\d.]+) draw_every_unit_sec ([\d.]+) whole_probe_sec ([\d.]+)", rd(p).read())
        b.append(float(m[1])); d.append(float(m[2])); w.append(float(m[3]))
    print(label, "build_day", b, spread(b), "| draw_every_unit", d, spread(d), "| whole probe", w, spread(w))

print("== T2. crowd tick: mean over the 36 whole-mode cases of the case's median per-tick microseconds, per round")
def crowd(path):
    ag, ti = [], []
    for j in cases(path, "whole"):
        ti.append(col_median(j, "tick"))
        if "agents" in j["columns"]:
            ag.append(col_median(j, "agents"))
    return len(ti), st.mean(ti), (st.mean(ag) if ag else 0)
for label, pat in (("end", "crowdtick_end_{n}"), ("v0.29.0 side by side", "crowdtick_v029_side_{n}")):
    out = [crowd(p) for p in rounds(pat)]
    tick = [o[1] for o in out]; agents = [o[2] for o in out]
    print(label, "cases/round", out[0][0], "| tick", [round(x) for x in tick], spread(tick, 0),
          "| agents column", [round(x) for x in agents], "| agents + tick", [round(a + t) for a, t in zip(agents, tick)],
          spread([a + t for a, t in zip(agents, tick)], 0))
after = []
for n in (1, 2, 3):
    p = f"{BASE}/crowdtick_after_4b_{n}.log"
    if os.path.exists(p):
        after.append(crowd(p)[1])
if after:
    print("after-4b (baseline, not at the same moment) tick", [round(x) for x in after], spread(after, 0))

print("== T3. frame profile (seed 4242, day 1, --invincible), callback interval median ms, per round")
for mode in ("profiled", "disabled"):
    for label, folder, tag in (("end", "fp", "end"), ("after-4b side by side", "fp", "after_4b"),
                               ("end (vs v0.29.0 pair)", "fp_v029", "end"), ("v0.29.0 side by side", "fp_v029", "v029")):
        cb, wall, ok = [], [], []
        for n in (1, 2, 3):
            p = f"{RAW}/{folder}/{mode}_{tag}_{n}-summary.json"
            if not (os.path.exists(p) or os.path.exists(p + ".gz")):
                continue
            s = json.load(rd(p))
            cb.append(s["callback_interval_ms"]["median"]); ok.append(bool(s["accepted"]))
            if mode == "profiled":
                wall.append(s["native_ms"]["frame_main_loop_wall"]["median"])
        if cb:
            print(mode, label, [round(x, 3) for x in cb], spread(cb, 2),
                  ("| main-loop wall " + spread(wall, 2)) if wall else "", "| accepted", ok)
for mode in ("profiled", "disabled"):
    p = f"{RAW}/fp/{mode}_end_unmodified_1-summary.json"
    if os.path.exists(p) or os.path.exists(p + ".gz"):
        s = json.load(rd(p))
        print(mode, "end, unmodified launcher: accepted", s["accepted"], s["rejections"],
              "callback interval median ms %.3f" % s["callback_interval_ms"]["median"])

def stream_tables(pairs):
    """Per tree, per round: mean over the split cases of the stream column's median (microseconds), the same over
    the cases whose split chain equals the whole chain, the planned events (split mode) and microseconds per plan,
    and the whole mode's events column (the events' whole step)."""
    for label, pat in pairs:
        s_all, s_ok, per_plan, ev, nfail, plans = [], [], [], [], [], []
        for p in rounds(pat):
            whole = {key(j): j for j in cases(p, "whole")}
            sa, so, pp, evs, bad, pl = [], [], [], [], 0, []
            for j in cases(p, "split"):
                stream = col_median(j, "stream")
                sa.append(stream); pl.append(j["planned_events"]); pp.append(stream / j["planned_events"])
                w = whole[key(j)]
                if w["chain"] == j["chain"]:
                    so.append(stream)
                else:
                    bad += 1
            evs = [col_median(j, "events") for j in whole.values()]
            s_all.append(st.mean(sa)); s_ok.append(st.mean(so)); per_plan.append(st.mean(pp) * 1000)
            ev.append(st.mean(evs)); nfail.append(bad); plans.append(st.mean(pl))
        print(label, "| stream us/tick, all 36 cases", [round(x, 1) for x in s_all], spread(s_all),
              "| chains agree only", [round(x, 1) for x in s_ok], spread(s_ok), "(cases whose chain differs per round", nfail, ")",
              "| planned events (mean)", [round(x, 1) for x in plans],
              "| stream ns per plan", [round(x) for x in per_plan], spread(per_plan, 0),
              "| whole mode events step us/tick", [round(x) for x in ev], spread(ev, 0))

print("== T4. streaming's tick, m159_tick_sweep_events_cost.gd, split mode's stream column")
stream_tables([("end (beside pre-3a)", "sweep_end_vs_pre3a_{n}"), ("pre-3a", "sweep_pre3a_side_{n}"),
               ("end (beside v0.29.0)", "sweep_end_vs_v029_{n}"), ("v0.29.0", "sweep_v029_side_{n}")])

print("== T5. the events' interface's owed readings: tawny-swan merge (75ef3ad57) beside calm-egret merge (d22a78e15)")
def t5(tree, n):
    p = f"{RAW}/t5_m159_tick_sweep_events_cost_{tree}_{n}.log"
    ev = sum(col_median(j, "events") for j in cases(p, "whole"))
    baby = sum(col_median(j, "baby") for j in cases(p, "split"))
    xf = sum(int(m[1]) for m in re.finditer(r"XF_COST .*\| cues (\d+) usec", rd(f"{RAW}/t5_excitement_fingerprint_{tree}_{n}.log").read()))
    text = rd(f"{RAW}/t5_calm_pelican_fields_layer_cost_{tree}_{n}.log").read()
    cold = sum(float(m[1]) for m in re.finditer(r"whole map, cold: \d+ outlines, ([\d.]+) ms", text))
    tick = crowd(f"{RAW}/t5_m159_crowd_tick_cost_{tree}_{n}.log")[1]
    return ev, baby, xf, cold, tick
names = ("events' whole step, sum of 36 per-case medians (us)", "baby's sweep, sum of 36 per-case medians (us)",
         "XF_COST, sum of nine (us)", "fields layer, whole map cold, two seeds (ms)", "crowd tick control (us, mean of medians)")
ns = [n for n in (1, 2, 3, 4) if glob.glob(f"{RAW}/t5_m159_crowd_tick_cost_egret_{n}.log*")]
for i, name in enumerate(names):
    a = [t5("tawny", n)[i] for n in ns]; b = [t5("egret", n)[i] for n in ns]
    print(name, "| tawny-swan merge", [round(x, 1) for x in a], spread(a), "| calm-egret merge", [round(x, 1) for x in b], spread(b),
          "| egret / tawny per round", [round(y / x, 3) for x, y in zip(a, b)])

lk = [n for n in (1, 2, 3, 4) if os.path.exists(f"{RAW}/t5_look_fingerprint_egret_{n}.log")]
if lk:
    print("== T5b. look_fingerprint.gd LK_COST: polite-newt merge (cf0f9db72) beside calm-egret merge (d22a78e15)")
    for tree in ("newt", "egret"):
        vals = []
        for n in lk:
            m = re.findall(r"LK_COST[^\n]*", rd(f"{RAW}/t5_look_fingerprint_{tree}_{n}.log").read())
            vals.append(m)
        print(tree, vals)
