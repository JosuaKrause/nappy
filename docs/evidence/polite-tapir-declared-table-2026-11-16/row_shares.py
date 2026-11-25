"""Per row and ground: the row's share of the ground's events, seed against a cells run, on the
row's own days. Usage: python3 -I row_shares.py <seed> <cells> [factor]"""
import collections, sys
GROUNDS = ["street", "junction", "alley", "open"]
def read(path, tag):
    ev = collections.Counter()
    for line in open(path):
        p = line.split()
        if p and p[0] == tag:
            ev[(int(p[1]), p[3], p[4])] += int(p[5])   # day, ground, row
    return ev
se, ce = read(sys.argv[1], "SE"), read(sys.argv[2], "CE")
factor = float(sys.argv[3]) if len(sys.argv) > 3 else 2.0
rows = sorted({k[2] for k in se} | {k[2] for k in ce})
for g in GROUNDS:
    print("-- %s: share of the ground's events on the row's days, seed -> new (ratio seed/new)" % g)
    for r in rows:
        days = {k[0] for k in list(se) + list(ce) if k[2] == r}
        s_r = sum(n for k, n in se.items() if k[2] == r and k[1] == g)
        n_r = sum(n for k, n in ce.items() if k[2] == r and k[1] == g)
        s_all = sum(n for k, n in se.items() if k[1] == g and k[0] in days)
        n_all = sum(n for k, n in ce.items() if k[1] == g and k[0] in days)
        if not (s_r or n_r):
            continue
        ss, ns = (s_r / s_all if s_all else 0), (n_r / n_all if n_all else 0)
        ratio = ss / ns if ns else float("inf")
        flag = "  <<<" if (ratio > factor or ratio < 1 / factor) else ""
        print("   %-20s %6.3f -> %6.3f   x%5.2f%s" % (r, ss, ns, ratio, flag))
