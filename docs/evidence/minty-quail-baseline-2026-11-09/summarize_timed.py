"""Reads raw/timed/ and prints the tables of measurements 4 and 5 (median and spread over the runs), for every column:
before (v0.29.0), today (38ce03823), placement closed (4da1e5285) and after 4b (b3693bee7).

The two later columns' dawn probes time build_day() and GameDawn.draw_every_unit() apart (their added figure is the
like-for-like one of the first two columns' one call), and their frame profiles carry --invincible; the after 4b column
also has the unmodified launcher's runs, listed as they came out (see the README)."""
import glob, gzip, json, os, re, statistics as st
H = os.path.join(os.path.dirname(os.path.abspath(__file__)), "raw/timed")
def spread(v): return "median %.1f (min %.1f, max %.1f)" % (st.median(v), min(v), max(v))

print("== 4. dawn planning: seconds inside build_day(), 14 cities x 14 days, per run n=1..3")
for t, name in (("before", "dawn_before_{}"), ("today", "dawn_today_{}"),
                ("placement closed", "dawn_placement_closed_run2_{}"), ("after 4b", "dawn_after_4b_{}")):
    b, d, w = [], [], []
    for n in (1, 2, 3):
        text = open(f"{H}/{name.format(n)}.log").read()
        m = re.search(r"build_day_sec ([\d.]+) (?:draw_every_unit_sec ([\d.]+) )?whole_probe_sec ([\d.]+)", text)
        b.append(float(m[1])); w.append(float(m[3]))
        if m[2]: d.append(float(m[2]))
    line = f"{t} build_day {b} {spread(b)}"
    if d:
        line += f" | draw_every_unit {d} {spread(d)} | the two added {[round(x + y, 3) for x, y in zip(b, d)]} {spread([x + y for x, y in zip(b, d)])}"
    print(line, "| whole probe", w, spread(w))

print("== 5a. crowd tick, mean over the 36 cases of the case's median per-tick microseconds, per run")
for t in ("before", "today", "placement_closed", "after_4b"):
    agents, tick = [], []
    for n in (1, 2, 3):
        a_, t_ = [], []
        for l in open(f"{H}/crowdtick_{t}_{n}.log"):
            if not l.startswith("CROWD_TICK_JSON"): continue
            j = json.loads(l[16:])
            if j["mode"] != "whole": continue
            cols = j["columns"]; rows = j["rows"]
            ti = [r[cols.index("tick")] for r in rows]
            tick_med = st.median(ti)
            ag = st.median([r[cols.index("agents")] for r in rows]) if "agents" in cols else 0
            a_.append(ag); t_.append(tick_med)
        agents.append(st.mean(a_)); tick.append(st.mean(t_))
        cases = len(t_)
    print(t, "cases/run", cases, "| tick column", [round(x) for x in tick], spread(tick),
          "| agents' own frames column", [round(x) for x in agents], spread(agents) if t == "before" else "(inside tick)",
          "| agents + tick", spread([a + b for a, b in zip(agents, tick)]))

print("== 5b. per-system frame profile (entity_frame_profile.gd, seed 4242 day 1, ms), per run")
sets = (("before", "{m}_before_{n}"), ("today", "{m}_today_{n}"),
        ("placement closed (--invincible)", "{m}_placement_closed_invincible_{n}"),
        ("after 4b (launcher unmodified)", "{m}_after_4b_{n}"),
        ("after 4b (--invincible)", "{m}_after_4b_invincible_{n}"))
for mode in ("profiled", "disabled"):
    for t, pat in sets:
        cb, wall, scr, acc = [], [], [], []
        for n in (1, 2, 3):
            path = f"{H}/frame_{pat.format(m=mode, n=n)}-summary.json.gz"
            if not os.path.exists(path): continue
            s = json.load(gzip.open(path))
            cb.append(s["callback_interval_ms"]["median"])
            if mode == "profiled":
                wall.append(s["native_ms"]["frame_main_loop_wall"]["median"]); scr.append(s["native_ms"]["script_self_sum"]["median"])
            acc.append(bool(s["accepted"]))
        if not cb: continue
        print(mode, t, "callback interval median ms", [round(x, 3) for x in cb], spread(cb),
              ("| main-loop wall median ms " + spread(wall) + " | script self sum median ms " + spread(scr)) if wall else "",
              "| analyzer accepted", acc)
