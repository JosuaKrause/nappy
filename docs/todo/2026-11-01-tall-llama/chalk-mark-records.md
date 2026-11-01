**#414's records, test comment, retry test and pictures say what was built**
([#414's review](https://github.com/JosuaKrause/nappy/pull/414#pullrequestreview-5400335968), the
chalk mark, its robber, and the task line; no gameplay defect was found).

- `docs/decisions/2026-09-26-M221.md` gives the wrong cause for the leftover marks: it says the
  leak needed a guarded next step and that `_begin_step()` ran "twice in one completion". On the
  base every mark she read leaked, on days 6 and 7 too, because `_begin_step()` replaced `_contact`
  without freeing it. Rewrite that sentence.
- crisp-moose's "the alley must be next to a path. if there is no path to it it shouldn't appear"
  was read as "a district door counts as a path" without asking. The player has now said so
  ([busy-ibis](../../playtests/2026-10-03-busy-ibis.md), statement 10: "yes a district door counts
  as path"): the comment at `tests/test_resistance.gd` (the alley-path test) and
  `docs/decisions/2026-09-27-downy-otter.md` cite busy-ibis for it, and the question this reading
  raised leaves `docs/review/2026-09-26-M213.md` if it is there.
- The courtyard robber shipped with no still on the player's "no courtyard still needed", which no
  file held. The player has since seen it and likes it (busy-ibis, statement 11); the record that
  describes the courtyard spot cites busy-ibis, and no still is owed.
- The M221 retry test (`tests/test_resistance.gd`, the test that retries a day) retries once and
  only checks that `_guard` no longer points at the old robber. The item asked that "after any
  number of failed attempts at a day, its alley holds exactly one chalk mark and no leftover
  robber": loop three attempts of day 9 and count the live chalk marks and the director's live
  robbers after each.
- Two visible changes have no picture: fluffy-alpaca's task line going away once a task is done,
  and rosy-raven's day 8 line, which was asked to fit "on one line wherever it is shown". One
  `tools/shot.sh` still of each, the second at the narrowest window the game supports.
- `src/ui/hud.gd`'s comment on the task line says the next line arrives "a frame later" after a
  "momentary blank"; both signals fire in the same call, so no blank is drawn. Fix the comment.
- `docs/evidence/m222-arrow-ends-on-the-van-2026-09-27/README.md` says "hands the package over at
  the van" beside "the task is not done", and puts the arrow tip "next to the driver's door"; in
  the still it is on the rear wheel. Describe the walk and the tip as they are.
