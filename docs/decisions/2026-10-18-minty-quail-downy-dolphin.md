# minty-quail — The event catalogue's and event definition's comments state the rule, not its history · 2026-11-06

**Built.** `src/events/event_catalogue.gd` and `src/events/event_def.gd` had their comments rewritten
to state each rule and the reason it must hold, with at most one citation, in the present tense.
Comment lines fell from about 2,030 to 1,720 in the catalogue and from about 1,130 to 925 in the
definition. Nothing else under `src/` changed.

**What was taken out.** The player's quotes with their dates (the rule and its reason stay, and the
playtest or inbox note that records the words is cited once); dates; the playtest, finding and
milestone numbers beyond the one citation; review findings ("the review finding this field exists
to answer"); phrasing about past states ("used to", "was first priced at", "no longer"); the
retelling of earlier measurements ("from +10.2 to +9.6", "the 3.5/s decay this was set beside"),
leaving the current figure and the probe that reproduces it; and the arguments that a past number
was wrong. The tuning reasons were kept where a reader needs them to change a row safely: the two
ceilings on `homeless_yeller`, the wall line on `dog_walker`, the 19.9 limit on `protest`, why a
`MAP` row waits on a notice, why a crash is solid only in parts, the stairwell trigger margins.

**No reason went missing.** Every reason a removed passage carried is in the surviving comment, a
playtest file the comment now cites, or an existing decision record, so this record adds none.

**Citations.** Two quotes the catalogue cited by a date alone are now cited by the playtest that
holds them: the crash's walkable gaps (PLAYTEST-63) and the fire engine's high cost (PLAYTEST-119
24). A quote with no recorded source is dropped with its rule kept.

**Verified.** The two files with comment lines and trailing comments stripped (a script that
removes `#` outside string literals and blank lines) are byte-identical to `origin/main`'s, so no
code line changed. Not done: the same pass on `src/events/event_instance.gd`, which another build
owns.

**Rejected.** Rewriting every block to two sentences: the long blocks that state a fairness
contract, a measured margin or a reachability argument (`homeless_yeller`, `roadblock`,
`_pigeon_flock`, the stairwell trigger) are shortened to what a reader changing the row must know
rather than to a sentence, because the reason is the content.
