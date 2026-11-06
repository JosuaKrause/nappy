# minty-quail — three heavy sweeps watch only as long as their checks need · 2026-11-06


minty-quail's `ci-speed.md`, its second half: the player chose the trims that keep their margin and
refused cutting sweeps that found real bugs (brisk-moose #1130). The park cordon sweep keeps its 4
park spots and the resistance reach sweeps keep their 4 seeds.

**Built.** The mouse-prefers-a-pile test rolls 3 days per seed instead of 6: 144 mice, 108 beside a
pile against 48.8 expected and a bar of 77.1 (it was 288 mice, 207 near, 97.6 expected, bar 137.6),
the same ratio and the same bar formula (expected plus five standard deviations). The masked-man
badge test meets him from 5 starting pauses (0, 19, 43, 71, 83 ms) instead of 11; the frames are not
sped. The "another masked man" test ends when five men have come, four have left the top and four
have taken their first step (the checks need three, one gap and two who ran); the section holds
thirteen. The crowd closure windows, each still stepped at 1/60 s:

| scenario | before | after | what the shorter window still covers |
|---|---|---|---|
| spine cars put out of sight | 80 s | 40 s | each end puts 10 and 12 cars past the edge, so the landings read are not vacuous |
| entry beside a plain edge | 120 s | 60 s | walker and car landings each pass the 5 the check needs by 25 s and stop growing for the car |
| mountain and bridge deck | 60 s | 30 s | the furthest reach has settled by 25 s and the cars past the edge number in the hundreds |
| tunnel and bridge both ways | 40 s | 20 s | thousands of frames each way, the inbound share against outbound is larger at the shorter window |
| plain edge, four sides | 20 s | 10 s | the check is an absence; a broken edge showed 200 to 700 frames out of bounds |
| entry roll in its own room | 60 s | 30 s | 247 landed walkers and 61 samples against the 20 asked, with the spread already 39 px |

The "another masked man" trim and the plain-edge, four-sides window go beyond the pick the player
accepted; the builder made them as the same kind of trim, and the player accepted them too ("it's
fine", inbox #1145).

**Measured** on a loaded machine, so only the ratios mean anything: the six suites together took
1639 s before and 729 s after; per suite, city decay 426 to 140 s, closures a 424 to 187 s, b 329 to
107 s, c 215 to 135 s, the masked man 100 to 74 s and its badge test 120 to 73 s. The checks went from
165504 to 165487. The shuffled run with two passes (`--shuffle 7 --repeat 2`) passes after, with no
`ERROR:` line, and the player's save is byte-identical.

**Mutations that still fail each trimmed test.** Mice: the preference taken out (47 of 144 near
against a bar of 77). Spine cars out of sight: the push past the edge taken out (no landings). Mountain,
bridge and tunnel: departures and the deck extended by 600 px (the roof, dark and deck checks fail), and
entry room zero (no car comes in). Plain edge and entry roll: entry room 30 px with the street test
bypassed (all four sides fail, the roll goes 30 px past the edge). Entry picture: the clearance zero
(walker and car fail). The masked man: `is_telegraphing_still` false (every man steps with no
warning). The badge test: a badge dropped 700 px out fails all 20 starts. The badge test's own
guard, the charger reset, is caught by neither the 11 nor the 5 pauses, since the test is a
probabilistic extra and the deterministic badge model case holds that rule.

**Rejected:** cutting the park cordon spots or the resistance reach seeds, which have caught real
bugs, and speeding the badge test's frames, since the model reads the real frame delta.
