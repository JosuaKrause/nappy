# spry-llama — The counter counts encounters: seen, influenced, and bouts of running · 2026-10-04

*([misty-newt](../playtests/2026-10-04-misty-newt.md), inbox #574: "I want to establish two things
-- how frequent do certain events actually appear and are players avoiding them or ignoring
them?" · "mostly I'm interested in the ratio of interacted/seen" · "we can count the number of
running excluding gaps smaller than 10s".)*

**What was built** (PR #578). Three new GoatCounter names per day, `nappy-day-N-seen-<event>`,
`nappy-day-N-influenced-<event>` and `nappy-day-N-influenced-unseen-<event>`, and
`nappy-day-N-ran`, all listed in `docs/TELEMETRY.md`, "The page counts visits".

- `EncounterWatch` (`src/events/encounter_watch.gd`) is asked once a physics frame by
  `EventManager._watch_the_encounters()` and says what it saw on three new listen-only `EventBus`
  signals, `encounter_seen`, `encounter_influenced` and `run_bout_began`; `VisitCounter` turns them
  into names and does nothing else. Nothing it reads is changed by it: it rolls nothing, and what it
  keeps on an instance (`EventInstance.landed_ever`, `EventInstance.encounter`) nothing gameplay
  reads.
- **An encounter** opens the first frame any of an instance's drawn box is in the view, or it lands
  something on her from off screen, and is over once it has been neither for `Tuning.ENCOUNTER_GAP`
  (5s). **Seen** is `Tuning.ENCOUNTER_SEEN_SHARE` (80%) of the drawn box inside the view.
  **Influenced** is `Tuning.ENCOUNTER_INFLUENCE_POINTS` (10% of a full meter) landed within the
  encounter for a row whose field excites her, and her inside its lethal reach or hold, or it chasing
  her, for a row whose field does not. A **bout of running** begins when she runs after
  `Tuning.RUN_BOUT_GAP` (10s) or more without.
- `tools/goatcounter.sh --encounters` prints seen, influenced, influenced ÷ seen and the unseen
  influences per event type, overall and per day, with `--json` as well.
- `tests/test_encounters.gd` covers one encounter one seen, a second after the gap, none inside
  it, the edge sliver, the 10% landing once per encounter, the waiting off-screen influence, the
  chase for a row that does not excite, two instances, the running bouts, and the manager's wiring
  (nothing behind the title); `tests/test_visit_counter.gd` the names; `tools/test_goatcounter.py`
  the table on canned hits.

**Which rule each row uses** (read off the row's own `intensity`/`core_intensity`,
`EncounterWatch.excites()`):

- **10% of the meter:** `cat_dash`, `alley_mouse`, `dog_walker`, `cafe_tables`, `homeless_yeller`,
  `busker`, `fire_truck`, `burnt_shell`, `loose_dog`, `market_stall`, `leaf_blower`,
  `pigeon_flock`, `cyclist` and the pelican, `ice_cream_van`, `reversing_lorry`, `charging_dog`,
  `chatting_mother`, `police_patrol`, `poster_crew`, `poster_crew_square`, `loudspeaker`,
  `curfew_announce`, `roadblock`, `checkpoint_hut`, `checkpoint_post`, `door_guard`, `abduction`,
  `alley_robbery`, `night_raid`, `military_convoy`, `protest`, `firefight`, `car_accident`,
  `robber_giving_chase`, `van_guard_giving_chase`, `finale_explosion`, `masked_pursuer`,
  `basement_steam`.
- **Reach, hold or chase:** `playground`, `delivery_van`, `construction`, `burning_building`,
  `checkpoint_gate`, `barricade`, `fallen_tree`, `skip`, `scaffolding`, `burst_water_main`,
  `moving_van`, `burnt_out_car`, `collapsed_frontage`, `neighbor`, `impact_crater`. None of them can
  end the day, hold her or chase her, so none is ever influenced: every row that can also excites
  her. The detour around a blocker stays out, as filed.

**Decided while building, where the filing left it open.**

- **A pelican is `pelican`, never `cyclist`**, in every name here. The player, asked after the
  filing: "yes cyclist and pelican are treated separately".
- **`nappy-day-3-seen-fire` and `nappy-day-N-pelican-seen` stay** unchanged beside the new set, as
  proposed; `--encounters` leaves the older `seen-fire` out of its table, since `fire` is no row.
- **An influence before the encounter is seen waits** rather than going out at once as unseen: a
  field such as the yeller's (210px) reaches further than the 180px from her to the top and bottom
  edges of the view, so an exciting row can land its 10% a moment before it is 80% in view, and sending those as unseen
  would have taken them out of the ratio for encounters she did see. It goes out as `influenced` when
  the instance is seen in the same encounter, and as `influenced-unseen` once the encounter is over
  without that, or when the next day starts, still under the day it happened on (the signals carry
  their day for this).
- **What is drawn is a box, not the pixels**: the row's own picture (`EventInstance.icon_for()`)
  standing at the instance, stretched over the run a spread, a protest or a firefight covers and
  grown by a flock's wheel (`EventInstance.drawn_box()`). The burning building's flames along its
  facade are wider than its one flame picture, so the fire counts as seen a little early. A row that
  draws nothing of its own (`playground`, `curfew_announce`, `finale_explosion`) is never seen.
- **The view is the camera's**, `Tuning.VIEW_HALF_EXTENT` about `Stroller.camera_screen_center()`,
  not the point test `EventManager._is_on_screen()` makes about her for the fire and the pelican.
- **The joystick scheme's controls hide the bottom corners.** *(Inbox #581, the player: "when
  counting the 80% visibility for seen remove the area at the bottom left and right up to the top
  of the joystick circle and horizontal extent of the speed button -- use that everywhere where
  visibility is concerned -- for the other mode those rectangles *do* count".)* Each bottom corner
  holds a ring with its run button inward of it, so each covered rectangle runs from the screen's
  side to the far edge of its run button and from the top of its ring down, worked out from
  `TouchControls`' own constants. `VisibleView.visible_share()` is the one function that answers
  how much of a world rectangle she can see; the encounter's opening and its seen both ask it.
  Switching gameplay's own visibility tests to it changes play and is a question of its own.
- **Not counted behind the title screen**, which runs the city with her stood aside, **nor on the
  escape**, which is not a day and has `nappy-escape-*` of its own.
- **A planned event streamed out and back in is a new instance**, and that changes nothing: it
  streams out only past `Tuning.EVENT_STREAM_RADIUS` plus its hysteresis, much further than the 5s
  gap can cover at a run.

**Rejected.** Reading the per-encounter landing off `EventInstance.landed()`, which keeps only the
halo's 5s window (`ExcitementHalo.WINDOW`) — an encounter can be longer; a monotonic total read at
the encounter's opening is the accumulator instead, and the halo's window is untouched. Keeping the
watch in `TelemetryObserver`, which exists only while the run log is on and so is absent on the
page the counter sends from.

**Not yet seen:** a real page sending these names; GoatCounter's readout of them waits on a release.
