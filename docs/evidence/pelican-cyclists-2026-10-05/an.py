import sys,collections,random,statistics as st
import numpy as np
runs=collections.defaultdict(dict); cre=collections.defaultdict(dict); rows=collections.defaultdict(dict)
for l in open(sys.argv[1] if len(sys.argv) > 1 else 'pelican.out'):
    if not l.startswith('CYC'): continue
    p=l.split(); s,d,r,c,tot=map(int,p[1:6]); runs[s][d]=r; cre[s][d]=c; rows[s][d]=tot
full=[s for s in runs if len(runs[s])==13]
print("seeds",len(full))
def q(a,p): return float(np.percentile(a,p))
for d in range(2,15):
    a=[runs[s][d] for s in full]; c=[cre[s][d] for s in full]; t=[rows[s][d] for s in full]
    print(d,"rolls mean %.2f med %g min %d max %d | created mean %.2f | all rows mean %.1f"%(np.mean(a),np.median(a),min(a),max(a),np.mean(c),np.mean(t)))
N=np.array([sum(runs[s].values()) for s in full]); C=np.array([sum(cre[s].values()) for s in full])
print("N mean %.2f med %g p10 %g p90 %g min %d max %d; created mean %.2f"%(N.mean(),np.median(N),q(N,10),q(N,90),N.min(),N.max(),C.mean()))
# per day N list for per-day bag
D={d:np.array([runs[s][d] for s in full]) for d in range(2,15)}
def runs_needed(pr):
    out={}
    for target in (.5,.9,.99):
        k=1
        while True:
            if 1-np.prod([(1-pr)]*k)>=target: break
            k+=1
        out[target]=k
    return out
def mix(ps,label):
    ps=np.array(ps); m=ps.mean()
    # each player draws runs iid from sample: P(no pelican in k runs)=(1-m)^k
    print(label,"P/run %.4f"%m,{t:int(np.ceil(np.log(1-t)/np.log(1-m))) for t in (.5,.9,.99)}, "E runs %.1f"%(1/m))
mix(1-(399/400)**N,"(a) flat")
mix(np.minimum(N/400,1),"(b) one bag/run")
# (c) per-day bag: P(no)=prod(1-n_d/400)
pc=[1-np.prod([1-D[d][i]/400 for d in D]) for i in range(len(full))]
mix(pc,"(c) per-day bag")
# (b) first-pelican run distribution via simulation of players with runs drawn iid from sample; and (a)
rng=np.random.default_rng(1)
def sim(pfun,n=200000):
    res=[]
    for _ in range(n):
        k=0
        while True:
            k+=1
            if rng.random()<pfun[rng.integers(len(full))]: break
        res.append(k)
    r=np.array(res); return r.mean(),np.percentile(r,[50,90,99])
print("sim a",sim(1-(399/400)**N)); print("sim b",sim(np.minimum(N/400,1)))
# (d) persistent bag: runs until cumulative >=400, for median and p10 N
for lab,n in (("median",np.median(N)),("p10",q(N,10)),("mean",N.mean())):
    print("(d)",lab,n,"guaranteed by run",int(np.ceil(400/n)))
# (d) sim: random starting position uniform in bag; player draws 399 blanks +1 pelican shuffled; runs until first pelican
res=[]
for _ in range(100000):
    pos=rng.integers(400); cum=0;k=0
    while True:
        k+=1; cum+=N[rng.integers(len(N))]
        if cum>=pos+1: break
    res.append(k)
res=np.array(res);print("(d) sim first-pelican runs mean %.2f p50/p90/p99"%res.mean(),np.percentile(res,[50,90,99]))
# guaranteed-by distribution across player (sum of 400/N)
g=np.ceil(400/N); print("guarantee run by N: p50 %g p90 %g max %g"%(np.median(g),q(g,90),g.max()))
