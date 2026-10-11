"""Write one attempt of a frame record's position track as `seconds x y events_usec` lines."""
import json
import sys

record, attempt, out = sys.argv[1], int(sys.argv[2]), sys.argv[3]
d = json.load(open(record))
ci = {n: i for i, n in enumerate(d["columns"])}
rows = d["rows"]
doorstep = (2560, 2704)
starts = [0]
prev = None
for k, r in enumerate(rows):
    p = (r[ci["player_x"]], r[ci["player_y"]])
    if prev is not None and p == doorstep and prev != doorstep:
        starts.append(k)
    prev = p
starts.append(len(rows))
seg = rows[starts[attempt - 1]:starts[attempt]]
t0 = seg[0][ci["start_usec"]]
with open(out, "w") as f:
    for r in seg:
        f.write("%.4f %d %d %d\n" % ((r[ci["start_usec"]] - t0) / 1e6, r[ci["player_x"]],
                                     r[ci["player_y"]], r[ci["events_usec"]]))
print("attempt", attempt, "rows", len(seg), "->", out)
