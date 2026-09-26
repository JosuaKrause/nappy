## M37 — Playtest 07 again: one picture per row

See **[docs/playtests/PLAYTEST-07.md](../playtests/PLAYTEST-07.md)**. Four of the six that were left, and they are all
"what you can actually see".

- [x] **One picture per row, and no two rows share one** — finding 2, and the fix is bigger than
      the finding because the finding was a symptom. `EventDef.Look` opened with five
      **categories** — `PERSON`, `VEHICLE`, `OBJECT`, `ANIMAL`, `FIRE` — and a category is a thing
      you can always put one more row into, so sixteen of the twenty-eight visible rows drew five
      pictures between them: five people on one man, six vehicles on one van.
      **It had already cost two findings and neither looked like an art problem.** M34 spent a
      milestone fixing `alley_robbery` for a complaint about `homeless_yeller`, because a player can
      only say *"the robber"*; playtest 09 then asked *"who is the person killing me?"*. And a third
      had gone unreported — `DangerEdge` kept its **own** table of which picture a look meant, so
      the screen-edge badge, whose entire content is *what* is coming, drew a delivery van for a
      fire engine and for the unmarked van that takes the baby.
      So it is a rule with a test rather than fifteen drawings: no two rows share a look, no two
      looks share a silhouette, `EventInstance.icon_for()` is the one table, and `look` has no
      default worth having. **The cost of adding an event is a drawing.** Same move as M34's
      `obstructs_radius`, on the other half of the vocabulary
- [x] **The robber has two postures** — `is_waiting()` picks between them. M36 gave that row three
      states and the screen showed one, so *a man is standing there* and *he has seen you* looked
      identical. The `cat_crouched` / `cat_running` rule, at the row where reading it wrong ends
      the run
- [x] **The protest is a crowd, and its body followed its picture** — the catalogue said of that
      row *"one person's worth, because one person is what it draws… the art is the fix"*, and it
      is 55px now, two ranks drawn across exactly the ground it takes. The clearest case in the
      game of art deciding a gameplay number. Measured over five seeds: events placed per day is
      **identical**, day for day, and so are protests placed
- [x] **The café has people at it** — finding 11. The tables were what obstructs and the
      conversation was what it emits, and only the first was drawn
- [x] **Buildings sort against nothing** — finding 4, diagnosed in M34. The fix is not the one the
      diagnosis pointed at: the comparison is **meaningless**, not merely wrong. Buildings tile
      their lots exactly and no lot tile is walkable, both asserted since M3, so nothing can ever
      legitimately stand behind a building. `Buildings` is a y-sorted layer under `Entities`.
      `building.gd` had claimed the opposite in a comment for twenty-two milestones
- [x] **The zzz stops dodging nothing** — finding 14. The baby's cue steps out of the exclamation
      mark's column, and that column is only occupied when there is a mark in it; unconditional, it
      put the zzz a body's width to one side of the pram on the commonest picture in the game.
      Playtest 06's own lesson again — *a cue is a claim about a moment* — reaching a player for
      the reason M32's two did: nothing in `tests/test_danger.gd` can see a `_draw()`. It is
      `Stroller.baby_cue_aside()` now, and the suite asks it
