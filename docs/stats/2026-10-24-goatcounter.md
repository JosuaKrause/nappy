# GoatCounter and Reddit, 2026-10-19 to 2026-10-24: what two posts brought, and where new players stopped

The player asked on 2026-10-24 to check GoatCounter and Reddit since the last read
(`2026-10-19-goatcounter.md`), to see whether each of two Reddit posts gave a bump, and to analyze
the rest. This file is that read, saved so it is not repeated. The live game was v0.29.2 throughout
(released 2026-10-19); nothing merged since is released.

**Read with** `tools/goatcounter.sh --report --start 2026-10-19 --end 2026-10-25` (the report is
below), `--raw` for each UTC day from 2026-10-14 to 2026-10-24 for the visitors per day, and
`tools/reddit.py user` and `thread` for the posts and their replies, on 2026-10-24 around midday
Eastern, so 2026-10-24 is a partial day. The player's own play is in these numbers and cannot be
separated. GoatCounter is on the default block lists of common ad blockers, and a developer audience
on Reddit runs them more than most, so the visitor counts are a floor of unknown distance from the
real ones. What other people wrote on Reddit is given in rough summary, never quoted.

## Visitors per day around the two posts

| UTC day | Visitors | Fresh runs | Resumed runs | What happened |
|---|---|---|---|---|
| 2026-10-14 to 2026-10-18 | 0-2 a day (5 in all) | 0 | 5 | |
| 2026-10-19 | 1 | 1 | 1 | v0.29.2 released |
| 2026-10-20 | **8** | 1 | 7 | the player's post on r/ClaudeGameDev, 12:28 UTC (score 14, 11 comments) |
| 2026-10-21 | 4 | 2 | 0 | |
| 2026-10-22 | 3 | 3 | 0 | the player's comment in r/ClaudeAI's showcase thread, 2026-10-21 23:41 UTC (score 1) |
| 2026-10-23 | 0 | 0 | 0 | |
| 2026-10-24 (partial) | 2 | 3 | 0 | |

## What it says

- **The r/ClaudeGameDev post gave a bump, and a short one**: visitors went from about one a day to 8
  on its day, 4 the next, and back to the floor within three days. Seven of that day's eight runs
  were resumed saves rather than fresh runs, so part of the bump is returning players or the player.
- **The r/ClaudeAI comment gave little or none**: 3 visitors the day after, inside the first post's
  tail. A comment inside a large shared thread reaches few readers.
- **New players seem to stop on day 1**: 10 fresh runs made 12 day-1 attempts and won 1 (8%),
  against 31% over the three weeks of the previous read; 12 attempts, retries and the player's own
  play included, are too few to be sure. The losses: crying from a car accident 3, hit by a car
  2, a loose dog 1, the pigeon flock 1. The player's answer is curly-moose #819.
- **The post's replies agree with that**: the one reply that reported playing, on desktop, from an
  account that pitched its own service in the same reply, said in rough summary that from the starting block it could not tell which way led to calm ground. The
  others were reactions (parenting and horror jokes, a likeness to an old arcade game) rather than
  play reports.
- **Phones still dominate**: controls chosen were tap 6 and joystick 5, keys none.
- **Days 4-13 are one or two players** (one to eight attempts a day), too few to read; one run
  reached the good ending and got out of the escape.

**After the next release**, its window is read against `2026-10-19-goatcounter.md`'s table with
`tools/goatcounter.sh --report --by-release --start <the release's day>`.

## The report

Caveats: counts are attempts, not visitors -- events opt out of sessions, and a nerve-bought retry begins its day again, so began is inflated by retries and a win rate is wins per attempt.
A day with fewer than 20 attempts (MIN_ATTEMPTS) is printed and marked (low-sample); that says how far its numbers can be trusted, and nothing is left out of any table. Only the page visit counts visitors.

### Players

- Visitors (page visit): 18
- Runs: 10 fresh, 8 resumed
- Controls: tap 6, joystick 5
- Mode: normal 8
- Endings: good 1
- Escape: out 1
- Checkpoints (by the day they came from): 3 (day 6: 1, day 7: 1, day 13: 1)

### Per day

| Day | Attempts | Won | Win rate | Lost | Crying | Hard fail | Timeout |
|---|---|---|---|---|---|---|---|
| 1 (low-sample) | 12 | 1 | 8% | 7 | 5 | 2 | 0 |
| 4 (low-sample) | 2 | 2 | 100% | 0 | 0 | 0 | 0 |
| 5 (low-sample) | 5 | 2 | 40% | 3 | 0 | 3 | 0 |
| 6 (low-sample) | 8 | 1 | 12% | 4 | 3 | 1 | 0 |
| 7 (low-sample) | 3 | 1 | 33% | 1 | 1 | 0 | 0 |
| 8 (low-sample) | 1 | 1 | 100% | 0 | 0 | 0 | 0 |
| 9 (low-sample) | 1 | 1 | 100% | 0 | 0 | 0 | 0 |
| 10 (low-sample) | 1 | 1 | 100% | 0 | 0 | 0 | 0 |
| 11 (low-sample) | 4 | 1 | 25% | 3 | 0 | 3 | 0 |
| 12 (low-sample) | 4 | 2 | 50% | 2 | 0 | 1 | 1 |
| 13 (low-sample) | 4 | 0 | 0% | 3 | 1 | 2 | 0 |
| 14 (low-sample) | 0 | 0 | - | 0 | 0 | 0 | 0 |

### Cause totals

- Crying: car-accident 5, checkpoint-hut 1, dog-walker 1, homeless-yeller 1, loose-dog 1, pigeon-flock 1
- Hard fail: car 8, alley-robbery 1, charging-dog 1, cyclist 1, police-patrol 1
- Timeout: 1

### Causes per day

Every cause of the day's losses, biggest first, with its share of the day's attempts.

- Day 1: crying-car-accident 3 (25%), hard-fail-car 2 (17%), crying-loose-dog 1 (8%), crying-pigeon-flock 1 (8%)
- Day 4: (no losses)
- Day 5: hard-fail-car 3 (60%)
- Day 6: crying-car-accident 1 (12%), crying-dog-walker 1 (12%), crying-homeless-yeller 1 (12%), hard-fail-cyclist 1 (12%)
- Day 7: crying-car-accident 1 (33%)
- Day 8: (no losses)
- Day 9: (no losses)
- Day 10: (no losses)
- Day 11: hard-fail-car 2 (50%), hard-fail-alley-robbery 1 (25%)
- Day 12: hard-fail-car 1 (25%), timeout 1 (25%)
- Day 13: crying-checkpoint-hut 1 (25%), hard-fail-charging-dog 1 (25%), hard-fail-police-patrol 1 (25%)
- Day 14: (no losses)
