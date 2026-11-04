import json,sys
def load(f): 
    return [json.loads(l.split(' ',1)[1]) for l in open(f) if l.startswith('CROWD_YIELDS_JSON')]
b=load('raw/yields-base.txt'); h=load('raw/yields-head.txt')
keys=['walker_overlap_entries','walker_overlap_seconds','car_overlap_entries','car_seconds_standing_for_figures','longest_stand_for_a_figure','longest_box_stand','box_stalls','horns','bumps','strikes']
print('| seed | run | '+' | '.join(k.replace('_',' ') for k in keys)+' | pose hash |')
print('|'+'---|'*(len(keys)+3))
tot={k:[0,0] for k in keys}
def f(x): return ('%.2f'%x).rstrip('0').rstrip('.') if isinstance(x,float) else str(x)
same=0
for x,y in zip(b,h):
    assert x['run']==y['run'] and x['seed']==y['seed']
    row=[str(x['seed']),x['run']]
    for k in keys:
        row.append(f(x[k])+' > '+f(y[k]) if x[k]!=y[k] else f(x[k]))
        tot[k][0]+=x[k];tot[k][1]+=y[k]
    s=x['events_chain']==y['events_chain']; same+=s
    row.append('same' if s else 'DIFF'); print('| '+' | '.join(row)+' |')
print('\nsame hashes',same,'of',len(b))
print('| metric | base total | head total |\n|---|---|---|')
for k in keys:
    if k=='longest_stand_for_a_figure' or k=='longest_box_stand':
        print('| max',k,'|',f(max(x[k] for x in b)),'|',f(max(x[k] for x in h)),'|')
    else: print('|',k,'|',f(tot[k][0]),'|',f(tot[k][1]),'|')
import statistics as s
for k in ['mean_car_speed','crowd_tick_usec','most_figures']:
    print(k,s.mean(x[k] for x in b),s.mean(x[k] for x in h))
