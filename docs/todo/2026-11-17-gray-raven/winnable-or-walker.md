# Find out whether the escape got harder or the probe's walker is weaker

*Proposed, not asked for:* run `tests/probes/escape_winnable.gd` at the commit that measured "95 of
96" (`tools/decisions.sh` finds the record behind the sentence in `docs/EVENTS.md`'s escape section)
and at main, with the same walker. If the old commit gets out about 95 of 96 with today's probe, the
escape got harder and the change that did it is found by bisecting the probe; if the old commit
also loses about half, the walker is what changed, and the sentence is re-measured with the walker
the game's own rigs use. The sentence is then made true either way, and a harder escape is a
question for the player (lilac-marten, the fuller escape, retunes it).
