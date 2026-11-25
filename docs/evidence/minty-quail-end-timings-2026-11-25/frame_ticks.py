"""Frames that carry a physics tick vs frames that do not, per frame-profile run (T3 of minty-quail's end remeasure).

Reads <prefix>-scene.json of every run under raw/fp (the rows the observer sampled every frame), keeps the
analyzer's own window (elapsed 5.0 s to 11.0 s), and for every kept frame takes the interval to the previous
sampled frame (the analyzer's callback_interval_ms) and the physics ticks that frame ran (the delta of the
physics_frame column). Prints, per run, the share of frames carrying a tick, the mean and median interval of the
two kinds, and the maximum and the mean of the ten longest intervals of all frames.
Usage: python3 -I frame_ticks.py <raw/fp directory>"""
import glob, gzip, json, os, statistics as st, sys

def runs(directory):
    for path in sorted(glob.glob(os.path.join(directory, "*-scene.json.gz"))):
        yield os.path.basename(path)[: -len("-scene.json.gz")], json.load(gzip.open(path))

print("run physics_hz frames tick_share | interval ms: tick-frames mean/median | no-tick mean/median | all max | top10 mean")
for name, scene in runs(sys.argv[1]):
    rows = scene["rows"]
    previous = {b[0]: a for a, b in zip(rows, rows[1:])}
    kept = [r for r in rows if 5000000 <= r[4] < 11000000 and r[0] in previous]
    tick, still = [], []
    for r in kept:
        interval = (r[3] - previous[r[0]][3]) / 1000
        (tick if r[1] - previous[r[0]][1] > 0 else still).append(interval)
    every = sorted(tick + still, reverse=True)
    print(name, scene.get("physics_hz"), len(kept), "%.2f" % (len(tick) / len(kept)), "|",
          "%.2f/%.2f" % (st.mean(tick), st.median(tick)), "|",
          "%.2f/%.2f" % (st.mean(still), st.median(still)) if still else "-", "|",
          "%.2f" % every[0], "|", "%.2f" % st.mean(every[:10]))
