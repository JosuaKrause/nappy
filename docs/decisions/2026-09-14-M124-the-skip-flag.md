## M124 — The skip flag · built 2026-09-14

*(2026-09-13: "prepare the flags for the additional mobile test runs and I'll provide
screenshots".)* One agent commit on `feature/m124-skip-flags`, reviewed on the PR; the stills
are `evidence/m124-skip-flag-2026-09-14/`, the same seed and walk with and without
`--skip events,crowd,shadows`.

**What it is.** `--skip <words>` and `?skip=<words>`, one arity-1 row in `DevFlags`' table,
parsed the same release-safe shape as `?svg=1` — no `enabled()` gate — but honoured only while
`readout_requested()` holds, so a release page without the DEBUG MODE note never skips and a
page that skips carries the note. `events` returns from every `EventInstance._draw` before it
draws, `crowd` the same for `CrowdAgent._draw`, `shadows` leaves `BuildingShadows` drawing no
chunk; fields, costs, motion and the halo run untouched. Each drawing class reads its own word
once into a member at spawn or build time, the way `main.gd` reads `_readout_requested` once,
rather than asking `DevFlags` per frame. `CrowdAgent._draw_body()` is left ungated because the
halo also calls it for a picked agent's ring. The readout's `skip` line sits directly beneath
the seed line and is absent when nothing is skipped.

**Refusal.** An unknown word refuses the whole value with a warning, the way an unknown
`--ending` word is refused; an empty value skips nothing, silently, following `--layers`'
precedent. Both were the agent's choices where the entry said only "refused the way the game
refuses any other malformed flag", and either is open to overturn.

**What the stills show**, on the desktop, seed 3265820891, day 1, the same three-second walk:
draws 644 against 567, objects 1952 against 1853, primitives 4565 against 3834 with all three
off — the desktop table's rows (c), (d) and (e) reproduced by the flag rather than by editing
the code — and a visibly bare street, which is the check that the flag reaches every caller.
The phone readings are the entry's next item and are the player's to take.
