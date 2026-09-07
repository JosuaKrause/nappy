# Playtest 31 — 2026-09-06

## Graphics-overhaul integration · 2026-09-06

> the luna agent got an initial version for the updated graphics. for now let's hide the new graphics behind a flag (command line argument and URL argument) so we can start merging this branch which has become quite big. in parallel start working on a fix for the graphics issues (for now we have to accept that the subagents cannot take screenshots)

> the default for the runtime flag is the old graphics

The illustrated presentation is an early version, not the release renderer. The ordinary game must
keep its existing graphics unless an explicit command-line or web URL argument opts into the
illustrated version. The opt-in makes the large overhaul branch mergeable while the presentation
work continues independently. Screenshot capability is unavailable to the implementation agents
for now; their visual fixes therefore need headless contracts and must be reported for later
on-screen review rather than claimed visually accepted.
