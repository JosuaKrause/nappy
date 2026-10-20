# curly-pelican — GoatCounter baseline before the refactor's release: where players struggled, 2026-09-20 to 2026-10-19 · 2026-10-19 · not from an entry


Not from an entry. The player asked on 2026-10-19 for an analysis of GoatCounter ("can you have a
look at goatcounter -- can you analyze it?"), then "let's take note of the findings today so we can
start fresh after the release". This record is that note: the baseline, read on `main` at v0.29.2,
that the next release's window is compared against. The player's follow-up, "how can we systematize
analyzing stats? also let's fix the tooling", is `tools/goatcounter.sh --report` (branch
`feature/goatcounter-report`), which prints this same analysis in one command.

**Read with** `tools/goatcounter.sh --days 30`, `--raw`, `--encounters` and `--by-release`, on
2026-10-19 at about 21:00 Eastern, covering 2026-09-20 to 2026-10-19 (releases v0.13.1 to v0.29.2).
An event counts every time it is sent, so a day's attempts include every retry; the page visit is
counted once per visitor. The player's own playtests are in these numbers and cannot be separated.

**Who played.** 68 visitors; 64 fresh runs; 45 resumed runs. Controls chosen: joystick 60, keys 8,
tap 4, so most players are on a phone.

**How far runs got** (attempts = the day's `began`, retries included):

| Day | Attempts | Won | Win rate | Lost to crying | Lost to a hard fail | Largest single cause |
|---|---|---|---|---|---|---|
| 1 | 108 | 33 | 31% | 29% | 18% | a car, 17% |
| 2 | 70 | 28 | 40% | 19% | 34% | a car, 23% |
| 3 | 79 | 18 | 23% | 14% | 57% | the charging dog, 42% |
| 4 | 31 | 21 | 68% | 6% | 26% | a car, 19% |
| 5 | 30 | 19 | 63% | 7% | 20% | the charging dog, 13% |
| 6 | 54 | 10 | 19% | 37% | 39% | a car, 15% |
| 7 | 25 | 5 | 20% | 40% | 36% | a cyclist, 12% |
| 8 | 17 | 4 | 24% | 24% | 47% | the alley robbery, 24% |
| 9 | 13 | 5 | 38% | 8% | 31% | a car and the alley robbery, 15% each |
| 10-14 | 44 | 18 | — | — | — | too few attempts to read |

**Causes across all days.** Hard fails: a car 71, the charging dog 47, a cyclist 18, the alley
robbery 10, the robber giving chase 3, the roadblock 2, the van guard giving chase 1. Crying: a car
accident 25, traffic 17, a loose dog 11, the homeless yeller 9, a dog walker 6, a leaf blower 4, the
crowd 4.

**The escape and the endings.** One run reached the escape (`nappy-escape-begun` 1), lost a section
10 times and got out (`nappy-escape-out` 1). Endings: good 1, neutral 1, bad 31 (a hard run's game
over).

**What it says.**
- **Day 3's charging dog is the largest single wall**: it ended 42% of day 3's attempts, and between
  a third and two thirds of them in each release window from v0.21 to v0.27. teal-trout's change (PR #770, merged
  2026-10-17, first released in v0.29.0: every charger that does not arrive charging warns first, by
  radius) has no day-3 attempt after it yet, so its effect is not measured. Inbox #803 asks for shorter warnings and
  larger radii for every charger.
- **Traffic decides the early days**: cars are the largest hard-fail cause (days 1-2 most), and a
  car accident and traffic are the two largest crying causes.
- **Day 6 is the second wall** (19%), its losses spread over 16 causes (5 hard fails, 11 crying) with none above
  15%.
  It is the first resistance day.
- **Runs thin out fast**: against 64 fresh runs, day 1 was won 33 times, day 3 18 times, day 8 4
  times and day 14 twice (wins counted per day, so a run that resumed is counted where it won).

**Gaps found in the tool while reading**, fixed on `feature/goatcounter-report`: `nappy-mode-*` and
`nappy-checkpoint-N-from-day-M` were listed as unrecognised shapes though `docs/TELEMETRY.md` lists
them, and the first read of `/api/v0/stats/hits` returned an HTTP 404 that the identical call a
minute later did not.

**After the next release**, the comparison is its own window: `tools/goatcounter.sh --report
--by-release` from the release's day, against the table above.
