## M180 — Posters she notices, and loudspeakers that are somewhere: the poster art · drawn 2026-09-23

*([PLAYTEST-123](../playtests/PLAYTEST-123.md), statements 1 to 27; the player on the last sheet:
"posters all look good now".)* A Sonnet first pass, then Opus from the second on, on
`feature/poster-art`; six review sheets, each answered by the player. Art only: nothing is bound.

**What was drawn** (`art/events/posters/`, each a 20×22 sheet at 6..26 × 3..25 on a 32×32 wall
tile, a gap on all four sides): the leader's portrait (jowly, scowling, receding hair, dark suit,
gray backing, dark band); the rules (an inset dark header, four entries of a 2×3 bar, a 1px gap
and two gray lines, a red ring stamp with a diagonal band); the curfew sheet (a ticked clock with
hands at four, two entries, the stamp); the uniform sheet (a phi-on-a-base emblem on near-black);
the wanted notice and its crossed copy (four head-and-shoulders silhouettes in mugshot frames,
one print line under each, the top-right always crossed, and a `neighbor_slot` group bottom-left
crossed only in the second file). **Torn posters are three tear masks**, each a mask of the paper
that stays and an overlay of the tear's fringe, shadow, bare wall, glue and crumbs (B adds a
hanging flap), composited as mask alpha × poster, then the overlay — so every kind tears three
ways. The recipe is in `docs/GRAPHICS.md`'s Posters section.

**The passes.** First (Sonnet): too neutral a leader, faces that did not read, posters touching
the floor, and a torn sheet that "looks nothing like a torn poster". Second (Opus): a grumpy
leader, bar-gap-line rules, silhouettes, a margin all round — "looks better already". The player's
generated reference sheet then set the look of the fourth pass
(`docs/style-references/posters-01.jpg`, brought in with `tools/reference.sh --style` after a
drawing agent's plain copy of it was refused by the permission check). The torn poster was drawn without a reference at the player's word, three ways,
then turned into masks ("one per kind or make it a mask … vary between the torn pattern").
Building fronts on the sheets moved posters off windows onto plain wall, which became M185, a
ground floor is blank wall or shops.

**Tried and rejected.** *A ring with an upside-down T* as the emblem · replaced by the
reference's phi on a base. *Six faces on the wanted notice* · four, so each has a neck and
shoulders. *One torn file per kind* · masks instead, the player's option. *Two print lines under
each wanted face*, as the reference has · one, since two do not fit in 22px; open to overturn.

**Open to overturn.** The wanted notice's two copies, one X on a face that is never the neighbor's
and two Xs adding the neighbor's slot, so the neighbor's cross is always the second (statement 30). The 20×22 size, and the 2×3 bar read as the player's "two pixel vertical
line". The emblem's resemblance to nothing real.

**The item as the queue held it when the art was drawn:**

      A kind that has arrived stays in the mix; nothing is taken down except by her. SVG first, as
      every picture here is, and the first drawn wall comes back to the player as pictures in
      the pull request before anything is polished.

      **The first pictures were answered** ([PLAYTEST-123](../playtests/PLAYTEST-123.md)): the
      leader's portrait is grumpy ("the leader is not going to be a nice fellow"); each printed
      line on the rules notice starts with a two-pixel bar, a one-pixel gap, then the line;
      the wanted notice's faces are proper head-and-shoulders silhouettes; people on posters are
      less blocky; a poster has a gap on all four sides of its tile; the torn poster is shown on
      its own; one row of posters on a wall is fine; and the drawing is Opus 5.5's. **Posters go on blank wall, never over a window**
      ([PLAYTEST-123](../playtests/PLAYTEST-123.md), statement 13): the ground floor gets stretches
      of wall without windows, and a crew pastes there. **The torn poster is redrawn as an SVG
      from the player's reference photos**; PNGs are Codex's, later.
