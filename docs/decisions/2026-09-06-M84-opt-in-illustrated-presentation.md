## M84 — Opt-in illustrated presentation · 2026-09-06

PLAYTEST-31 asked for the large graphics-overhaul branch to merge while its initial illustrated
runtime remains reviewable rather than becoming the published look. The baseline is therefore the
legacy SVG presentation. `--illustrated` opts into the illustrated runtime on the command line and
`?illustrated=1` does so on web builds; an absent argument or `illustrated=0` remains legacy. The
web query is deliberately outside developer-flag gating because an exported build is where the
review must happen. It selects presentation only: movement, collision, crowd behavior and gameplay
randomness remain the same simulation.

The character repair restored the mother sheet's measured hip and knee pivots after the preceding
scale adjustment shortened them, and derives the pram lift from its wheel pivot and the sheet's
ground baseline. Focused headless contracts cover parser defaults, opt-in selection, legacy
bindings, joint registration and wheel grounding. The illustrated result is not visually approved:
a display-capable review still needs to inspect mother/pram scale, leg attachment, foot and wheel
contact, and layer ordering while the opt-in is active.
