"""Reads raw/timed/ and prints the tables of measurements 4 and 5 (median and spread over the runs)."""
import glob, gzip, json, os, re, statistics as st
H = os.path.join(os.path.dirname(os.path.abspath(__file__)), "raw/timed")
def spread(v): return "median %.1f (min %.1f, max %.1f)" % (st.median(v), min(v), max(v))
print("== 4. dawn planning: seconds inside build_day(), 14 cities x 14 days, per run n=1..3")
for t in ("before", "today"):
    b, w = [], []
    for n in (1, 2, 3):
        m = re.search(r"build_day_sec ([\d.]+) whole_probe_sec ([\d.]+)", open(f"{H}/dawn_{t}_{n}.log").read())
        b.append(float(m[1])); w.append(float(m[2]))
    print(t, "build_day", b, spread(b), "| whole probe", w, spread(w))
print("== 5a. crowd tick, mean over the 36 cases of the case's median per-tick microseconds, per run")
for t in ("before", "today"):
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
for mode in ("profiled", "disabled"):
    for t in ("before", "today"):
        cb, wall, scr = [], [], []
        for n in (1, 2, 3):
            s = json.load(gzip.open(f"{H}/frame_{mode}_{t}_{n}-summary.json.gz"))
            cb.append(s["callback_interval_ms"]["median"])
            if mode == "profiled":
                wall.append(s["native_ms"]["frame_main_loop_wall"]["median"]); scr.append(s["native_ms"]["script_self_sum"]["median"])
            assert s["accepted"], (mode, t, n, s["rejections"])
        print(mode, t, "callback interval median ms", spread(cb),
              ("| main-loop wall median ms " + spread(wall) + " | script self sum median ms " + spread(scr)) if wall else "")
