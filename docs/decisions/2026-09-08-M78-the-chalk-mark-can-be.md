## M78 — The chalk mark can be found · built 2026-09-08

Two findings from [PLAYTEST-19.md](../playtests/PLAYTEST-19.md), halves of one thing: the first mark was
announced when it should not be, and it could not be found when it should be. Neither needed a
drawing, which is why they stood apart from M65's pointing protester. Built by a sub-agent from a
brief; the choices below marked *orchestrator's reading* were fixed in the brief and are open to
overturn against a played day.

**The status line is silent until the first mark has been touched.** *(2026-09-02: "the first chalk
mark is written in the status when it should not be.")* `Hud._refresh_resistance()` names the
current step only while `GameState.completed_resistance_steps` is non-empty — the pickup's own
completion, not `has_joined_resistance()`, because a pickup grants no progress and the rule in
`CLAUDE.md` is about the first *encounter*: *the first encounter comes with no hint at all. After
that the resistance speaks.* The HUD also listens to `resistance_step_completed`, since the first
mark fires no progress signal and the line would otherwise stay silent until the next morning. The
debug build's `resistance ....` prefix keeps its own rule. `tests/test_hud.gd` holds both HUD modes
before and after the first completion.

**A mark that was never on screen was never placed.** *(2026-09-02: "it's hard to find the chalk
mark remember it should be dynamically placed on the path where the player can see it. if it was
placed but never on screen it should count as not placed and be placed on the next alley the player
comes close to.")* The first placement that follows the player through the day; `ClosurePlanner`
and `EventScheduler` decide at dawn and stand. Built in `ResistanceDirector`, for pickup steps only
— a perform contact rides its event and the finale sits in a district.

- **Seen** is the mark's own world position inside the camera's view at any frame that day, asked of
  `DangerEdge.is_on_screen()` — the one rotation-aware on-screen test the game has, made public and
  injected through `set_sight()` rather than duplicated. Seen is sticky: the mark never moves again
  that day. A rig with no predicate never sees anything and the rule keeps running.
- **Comes close to** an alley is any reachable `ALLEY` tile within `NOTICE_RADIUS` (400px) of her.
  *Orchestrator's reading.* The visible world is 640×360, half-diagonal about 367px, so a mark placed
  at 400px is placed just off screen and walks into view rather than appearing in it — the same
  reasoning M77 sites every arrival by.
- **The rule, each frame while unseen:** if she is further than `NOTICE_RADIUS` from the mark and an
  alley tile is within `NOTICE_RADIUS` of her, the mark moves to the nearest such tile — the alley's
  mouth, which is what *on the path where the player can see it* asks for. Hysteresis on the mark's
  own radius is what stops it chasing her step by step. The dawn placement is untouched, so the
  deterministic-placement test still holds; the rule corrects it on the first frame if home is
  nowhere near it.
- **The guard moves with it.** The old `alley_robbery` is retired through a new
  `EventManager.retire()` (the same finish path `silence_city_wide()` uses, so the ordinary sweep
  frees it) and a new one is spawned in the same 66–176px band. **Its bearing is drawn from the
  half-circle facing away from her**: a moved mark sits about 400px out, and a bearing toward her
  could put the robber at about 224px — on screen, appearing from nothing. Facing away, the worst
  case is about 437px. The day's RNG is kept on the director so a mid-day guard still comes from the
  replayable stream.
- **A guard that has already noticed her blocks the move.** Unreachable by the geometry — he wakes
  within 140px of the mark and the mark moves only past 400px — but checked, so a defect there shows
  as a test failure rather than a robber frozen over empty ground.
- Every move and the first sighting write a `contact` telemetry line; the observer's own
  `_watch_the_contact` reads `contact_position()` live and needed no change. The `--spawn contact`
  dev target answers wherever the mark is when asked, so a rig spawned beside it may find it moved.

**What is open.** Nobody has walked a day on this: whether a mark that follows her is now found, and
whether a re-placed mark at an alley mouth reads as chalk somebody left or as the game planting it
in front of her. The player's own next step if it is still unfindable is M65's density half —
more protesters, since a protester obstructs nothing. The guard's own tile is still not checked for
walkability, which is the queued "robber inside a building" item and not this milestone's.
