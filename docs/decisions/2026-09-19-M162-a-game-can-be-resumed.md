## M162 — A game can be resumed · built 2026-09-19

*(2026-09-19, [PLAYTEST-80](../playtests/PLAYTEST-80.md): "we need to be able to resume a previous
game. saving should be implicit (on focus loss or game quit) and it should bring you back to
that exact state but paused." [PLAYTEST-82](../playtests/PLAYTEST-82.md): "If that is too hard
then we do start at dawn. But that has a potential to be exploited" — "Unless we give a penalty
of ending the current day losing a nerve" — "No penalty when exiting at a next day/win/lose
screen".)* Built by an agent on `feature/m162-resume`.

**The design, and what was overturned on the way.** *Asked for "that exact state", the crowd
included · overturned by the player on 2026-09-19 to a restart at dawn that costs a nerve.* The
requirement under both is that **quitting is never an escape**. Three shapes were put to the
player: everything, including some two hundred walkers and the cars with their lanes, turns,
queues and signal phases; everything but the crowd, re-seeded around her, which was the
recommendation and was refused because a car she stepped in front of would be gone on resume;
and the run and the day only. The player chose the last with a penalty, which closes the same
exploit without the save format depending on the crowd's internals.

**What was built.**

- **The save is the run.** `GameSave` (a static namespace, like `DevFlags`) writes
  `user://save.json`: every field `GameState` owns, `CityState`'s block-arc history (run
  history, not recomputable from the seed), whether a day was under way, a format version and
  the build string. `GameState._SAVE_FIELDS` is checked against the script's own property list
  by `tests/test_save.gd`, so a field added later and not saved fails a test. **Only
  `FORMAT_VERSION` is compared on load**: a release never invalidates a save by being newer, a
  change of shape does, and an unreadable save is dropped for a fresh title screen.
- **It is written at dawn, at each day's end, on focus loss, on quit, and the instant a day
  is first stepped into.** The player named focus loss and quit; the rest exist because a
  crash, a force-kill and a discarded mobile tab send no notification at all.
- **Opening a save that says a day was under way loses the day** through
  `GameState.finish_day()`, the path every lost day takes: one nerve, the resistance given
  back, the same day again, the last nerve ending the run. She comes up at dawn behind the
  pause screen with a note line. A save written at a day summary comes back to the next dawn
  at no cost; either ending and the held restart clear the save.
- **The save symbol** is `assets/ui/save.svg`, a floppy disk tinted `Palette.CHALK_DONE`, bottom
  right of the design box, on its own always-processing layer.
- **The browser**: after each write on a web build `FS.syncfs` is called so the IndexedDB
  write starts at once rather than on the next main-loop turn.
- **An agent never lands in a saved game**: `GameSave.uses_save()` is the one gate — false for
  a headless run, for any debug run carrying a dev flag, and for `--no-save` — and every read
  and write passes through it. Tests point the save at a scratch path.

**What review caught.** The first build flipped "this day is being played" when the title or
the resume's pause screen was dismissed, and wrote nothing at that moment, so the save on disk
said *not under way* until a notification happened to arrive. A killed process or a discarded
tab then resumed free — all of day 1, and every second escape. `main._engage_the_day()` is now
the one place the flag turns true and it writes the save on that transition; closing an
ordinary pause writes nothing. None of the milestone's first tests exercised the gap between a
gate opening and the next notification; four now do.

**Choices made where the design was silent, open to overturn.**

- **A day behind an undismissed title or resume pause is not under way**, so closing the game
  again before touching the retry costs no second nerve, and opening the game and closing it
  at the title costs nothing.
- **The penalty is applied on load, never on a pause that is continued**, and the save is
  rewritten with the nerve already spent before the resumed day is playable, so no kill
  between the two charges twice or not at all.
- The note's wording: *"Left before the day ended. That cost a nerve — it starts over from
  dawn."* The symbol holds a second and a half and fades for the same.
- The load-time loss is recorded as `DayResult.LOST_HARD_FAIL`; nothing displays it, since no
  day summary is shown on that path.
- `?nosave=1` exists for consistency with the other flags though a web build shares its
  storage with no checkout.

**Not verified by anything but a person**, and filed in `REVIEW.md`: the deployed page keeping
the save across a closed tab and a new release, the note and the symbol on a real screen
(unreachable by any dev-flagged run, by design), and whether the penalty reads as fair.
