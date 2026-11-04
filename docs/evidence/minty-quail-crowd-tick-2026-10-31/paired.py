"""Paired comparison of two minty_quail_crowd_cadence.gd outputs.

  paired.py A.txt B.txt [A-frames-per-tick B-frames-per-tick]

Pairs the runs of A and B by seed, day and walk (each pair is the same city, crowd and walk) and
prints, per measure, both means, the mean of B minus A, its standard error, t (the difference
over its error: past about 2 is hardly chance) and how many pairs came out identical. The two
optional numbers pick one `frames_per_tick` out of a file that holds several.
"""
import json,sys,statistics as st
def load(p,fpt=None):
    d={}
    for l in open(p):
        if l.startswith("CROWD_CADENCE_JSON "):
            r=json.loads(l.split(" ",1)[1])
            if fpt is None or r["frames_per_tick"]==fpt: d[(r["seed"],r["day"],r["walk"])]=r
    return d
a=load(sys.argv[1],int(sys.argv[3]) if len(sys.argv)>3 else None); b=load(sys.argv[2],int(sys.argv[4]) if len(sys.argv)>4 else None)
keys=sorted(set(a)&set(b)); print("pairs",len(keys))
for m in ["horns","box_collisions","bumps","strikes","mean_car_speed","box_entries_per_minute","headway_median"]:
    d=[b[k][m]-a[k][m] for k in keys]
    mean=st.fmean(d); se=st.stdev(d)/len(d)**.5
    print(f"{m:24} A={st.fmean(a[k][m] for k in keys):8.2f} B={st.fmean(b[k][m] for k in keys):8.2f} diff={mean:+.2f} se={se:.2f} t={mean/se if se else 0:+.2f} identical={sum(1 for x in d if x==0)}/{len(d)}")
