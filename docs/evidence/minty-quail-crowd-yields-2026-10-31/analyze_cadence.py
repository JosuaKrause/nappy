import json,sys,math
def load(f): return [json.loads(l.split(' ',1)[1]) for l in open(f) if l.startswith('CROWD_CADENCE_JSON')]
b=load(sys.argv[1]); h=load(sys.argv[2])
assert len(b)==len(h), (len(b),len(h))
key=lambda r:(r['seed'],r['day'],r['walk'])
bd={key(r):r for r in b}; hd={key(r):r for r in h}
assert bd.keys()==hd.keys()
keys=sorted(k for k,v in b[0].items() if isinstance(v,(int,float)) and k not in('seed','day','frames_per_tick','window_seconds'))
hk=[k for k in h[0] if k not in b[0]]
print('pairs',len(bd),'extra head keys',hk)
for walk in ['all','road','walkers']:
    ks=[k for k in bd if walk=='all' or k[2]==walk]
    print('\n##',walk,len(ks),'pairs')
    print('| metric | base mean | head mean | diff | se | t |\n|---|---|---|---|---|---|')
    for m in sorted(set(keys)|set(k for k in b[0] if isinstance(b[0][k],(int,float)) and k in h[0])):
        if m in ('seed','day','frames_per_tick','window_seconds') or not isinstance(b[0].get(m),(int,float)): continue
        d=[hd[k][m]-bd[k][m] for k in ks]; n=len(d); mu=sum(d)/n
        se=math.sqrt(sum((x-mu)**2 for x in d)/(n-1)/n) if n>1 else 0
        bm=sum(bd[k][m] for k in ks)/n; hm=sum(hd[k][m] for k in ks)/n
        t=mu/se if se>0 else (0 if mu==0 else float('inf'))
        print(f'| {m} | {bm:.3f} | {hm:.3f} | {mu:+.3f} | {se:.3f} | {t:+.1f} |')
if 'events_chain' in b[0] or any('chain' in k or 'hash' in k for k in b[0]):
    for k in b[0]:
        if 'chain' in k or 'hash' in k:
            same=sum(bd[x][k]==hd[x][k] for x in bd); print(k,'identical',same,'of',len(bd))
