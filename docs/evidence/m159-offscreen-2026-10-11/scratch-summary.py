import json,sys,statistics as st
rows=json.load(open(sys.argv[1]))
# keep frames from the play window: frames that have crowd_n (the day running)
rows=[r for r in rows if r.get('crowd_n',0)>0 or r.get('ev_n_in',0)+r.get('ev_n_off',0)>0]
n=len(rows)
keys=sorted({k for r in rows for k in r if k!='frame'})
print(f"frames {n}")
for k in keys:
    vals=[r.get(k,0.0) for r in rows]
    print(f"{k:34s} mean/frame {sum(vals)/n:10.2f}  p50 {st.median(vals):8.1f}  max {max(vals):8.0f}")
def ratio(a,b):
    A=sum(r.get(a,0) for r in rows); B=sum(r.get(b,0) for r in rows)
    return A/B if B else float('nan')
print("crowd draw us/call", ratio('crowd_draw_us','crowd_draw_n'))
print("event draw us/call", ratio('ev_draw_us','ev_draw_n'))
print("event key us/call in", ratio('ev_key_us_in','ev_n_in'), "off", ratio('ev_key_us_off','ev_n_off'))
print("event caret us/computation", ratio('ev_caret_us','ev_caret_n'))
print("crowd caret us/call in", ratio('crowd_caret_us_in','crowd_caret_n_in'), "off", ratio('crowd_caret_us_off','crowd_caret_n_off'))
