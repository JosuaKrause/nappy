# minty-quail — event_instance.gd's comments state the rule, not its history · 2026-11-06

minty-quail's `comments.md` item, `src/events/event_instance.gd` (1,004 of 1,993 lines were comment
lines when it started; the file had been split into behaviours by earlier steps, so the item's
7,342-line figures and its two named defects were out of date).

**Built.** The comments only; a diff of the file with comments stripped
(`git diff -U0 origin/main -- src/events/event_instance.gd | grep '^[-+]' | grep -v '^[-+]\s*#'`)
shows nothing. Quotes of the player, a date and a nickname for who asked are gone from the doc
comments; each rule keeps its reason and at most one citation. The history those comments carried,
which now lives here:

- **Pelican name in logs** (azure-tapir #527): the player asked that logs identify a pelican
  correctly from the first line, which is why `PELICAN_NAME` replaces the row's `cyclist` in the run
  log and GoatCounter events.
- **Bodies centred on the pavement band** (PLAYTEST-19): the complaint was the offset, not the
  width, of stationary bodies clipping into other things; the remedy is the position (centre on the
  two-lane band), not a smaller radius.
- **A boom's body follows its arm** (2026-09-24): the player had not asked for a lowered-then-raised
  boom to stay solid when open.
- **A charge ends in exactly one counted way, independent of an ended day** (minty-lemur #764).
- **One radius, a warning on a clock inside it** (minty-lemur #764, #788): a warning happens when
  she comes close; back outside the radius before it runs out, the warning stops and the robber
  waits again where he stands; staying inside, the charge starts.
- **The task guard's way to her** (curly-gecko): proposed, not asked for; the player only asked
  that he start pursuing when she hits the task.
- **A pursuer's catch needs a clear line to her** (freckled-goose #544): reaching across a
  building's corner would not physically connect, so it is not a catch.
- **The charge needs a clear line** (mossy-beaver #650).

**Checked, not changed.** The item's two named defects no longer exist in the file: the spliced
sentence survives as the `is_its_guard_inside` doc (now one sentence, rewritten), and the claim that
`chatting_mother` "can never detain a second time" is now `has_chatted`'s doc, which says what the
code does: `CheckpointController.check_detentions` skips a row that has held her and does not
`redetains`, and `EventHold.step` ends such a row when its hold runs out. The code is right.

**Left.** `event_catalogue.gd` and `event_def.gd`.
