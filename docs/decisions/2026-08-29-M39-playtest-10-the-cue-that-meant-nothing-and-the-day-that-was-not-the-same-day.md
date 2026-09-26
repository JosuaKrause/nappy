## M39 — Playtest 10: the cue that meant nothing, and the day that was not the same day · `feature/marks-that-mean-danger`

See **[docs/playtests/PLAYTEST-10.md](../playtests/PLAYTEST-10.md)**. Fourteen findings, reported as a list after a session
of five runs in which **no day was won**. Eleven are work; two are answered in writing; one — the
difficulty — is deliberately the milestone after this one.

The sentence under it: **the danger marks and the danger have come apart, and a retried day is not
the same day.**

- [x] **The mark is raised by what a thing costs** — findings 1, 8 and 9, which are one finding with
      three faces. `wants_a_mark()` asks whether the danger *changes over time*, which is a true
      statement about a thing and not a statement about how bad it is: a fire engine (+115) carries
      no caret and a burning building (+56) does, the most expensive ordinary row in act I
      (`dog_walker`, +36) carries none and the leaf blower beside it does, and the man who ends day
      1 in three separate traces (`homeless_yeller`, +31) misses `can_be_timed()` by four tenths of
      a second. The colour half is streaming: `EVENT_STREAM_RADIUS` is 900px and no telegraph is
      longer than 4s, so amber is only ever seen on the two `AHEAD_OF_PLAYER` rows and therefore
      means *near* rather than *not yet*. New rule, with the invariant a test can hold: **if A is
      marked and B is not, A costs more than B**; amber for *go round it*, doubled deep red for
      *ends your day*, and the flash — not a colour — for *it has not started*. Accepted cost,
      written down as a decision: the crouching cat (+20) loses its caret
- [x] **The playground is the calmest ground in the city** — finding 2, and it has been true for
      twenty milestones. `PLAYGROUND` is calm ground, so the decay on it is 7.7/s, and the row emits
      **7.0/s at the peak of its pulse**: it has never once out-emitted the ground it stands on, and
      its denial radius is its own inner radius, 40px of 150. It was right in M5, when the calm
      multiplier was 3.5 and the decay 1.5/s; M18 took it to 10 and M38 to 12. Playtest 08 did this
      exact sum for the busker one function away, in `_denial_radius`, which carries the warning in
      its own docstring
- [x] **The dog follows for too long** — finding 13, *"the running tutorial dog is impossible to
      escape"*, and **the analysis in this session was wrong**. It read the finding as a *reaction
      window* — `pursuit_standoff()` buys `PURSUIT_REACTION` seconds of the dog's 130px/s while she
      is walking into it at 92, so the real window is 0.2s — and built the fix for that. The player's
      own account: *"the charging start earlier was fine — it was enough time to react properly"*,
      *"the issue was that the dog kept following for too long"*, and *"the dog now moves backwards
      before charging — that doesn't make any sense"*.
      The trace agrees with the player: she reacted, she ran, and she **died to the meter with the
      dog 63px away**. It is the **break-off**, which is M35's failure repeating. The work built on
      the wrong reading is in the tree, uncommitted, and `docs/HANDOFF.md` lists every constant to
      re-decide.
      **What was built instead**: `Tuning.PURSUIT_SHAKEN_OFF`, which ends a chase after 0.8s of the
      gap **opening** rather than after a fixed gap has been reached. Because a pursuer is faster
      than a walk and slower than a run by construction, only running can open the gap — so "walking
      away can never end a chase" and "running away always ends one" stop being two inequalities that
      fight over the same three numbers and become facts. The reaction, the stand-off (104px) and the
      chase (3.0s) all go back to what a player said was already right. Measured: the answer costs
      **0.86s of running, 12 points**, against 35 before.
      **Two things found on the way are kept**: a pursuer must stand off inside its own
      `outer_radius` (found by a rig — the dog was holding 174px out with a 150px field, so the phase
      that is supposed to *be* the warning emitted nothing and the `!` never went up), and
      `tests/test_events.gd` has a rig that **accelerates**, which the three that passed while the
      encounter was unplayable did not.
      **Still open, and written down rather than hidden**: the window to answer at the lunge itself
      is 0.1–0.2s, because she is walking into the thing. A player answers during the telegraph
      instead. Widening it means a wider stand-off, and a wider stand-off is the reversing dog
- [x] **A retried day is the same day, and the day-3 lesson always happens** — finding 5. Three
      independent causes and the third is the one that matters. `_place_one_shots` skips a consumed
      one-shot *before* drawing its `randf()`, so attempt 2 starts a value earlier in the stream and
      every later placement moves — five seeds out of five produce a different day 3, and one of
      them changes how many `charging_dog`s exist. `_place_scars` compounds it through
      `_room_around`. And **the tutorial is a weighted roll**: `_teach_the_run` says outright that
      if the day did not buy one, nothing happens, and whole day 3s with `charging_dog x0` exist.
      Also the director's clock only runs while she is moving, and the third attempt in the trace
      never left the doorstep
- [x] **The `!!` comes down when the danger has been avoided** — finding 11. The doubled mark is
      raised for any lethal event whose **outer** radius covers her, so a cyclist lethal inside 26px
      raises it across 145 and keeps it up while the bike rides away. Playtest 06's finding 3 at the
      half M32 did not fix — it gave the traffic a `stand_down()` and left the events on "inside the
      radius". Two conditions now: within a step of what ends the day, **and** closing. Deliberately
      the *relative* rate, where the screen-edge badge deliberately uses the thing's own — the two
      cues say different sentences and the difference is the reason
- [x] **The zzz over the pram** — finding 3, and the other half of M37's own fix
- [x] **`space` carries on, and the pause says which day and how many nerves** — findings 6 and 7
- [x] **Screenshots beside the trace** — finding 12. On the entries that are already *about a
      moment* — a day lost, a nerve, a hard fail, a chase — rate-limited, capped per day, named
      after the entry. In `TelemetryObserver`, because telemetry never touches gameplay
- [x] **Logs you can throw away** — finding 14, plus the follow-up that explains it: a run restart
      reloads the scene, so one sitting is several logs and that is correct. The commit goes in the
      **filename**, `tools/telemetry.sh` grows a prune, and the listing says which are stale
- [x] **The yellow person that did not approach** — finding 4, answered in writing rather than
      built: nothing in act I pursues, and a busker who chases prams is a different game. It is
      recorded because it is findings 1/8/9 from a fourth side — *I cannot tell what any of these
      things are going to do to me*
- [x] **Home at the centre** — finding 10, answered in writing. The city is already odd (7×7) and
      `_place_home` already sorts by distance to the centre; what pushes the home out is
      `MIN_HOME_TO_PARK_TILES`. The two rules compete for the same thing and at 7×7 both cannot
      hold. The recommendation is to take the trade **by growing the city to 9×9**, as its own
      milestone, because it re-measures every density number in `docs/playtests/PLAYTEST-04.md`

### And the thing nobody reported

- [ ] **The crowd is winning.** Nineteen days lost in the session, seventeen to `lost_crying`, and
      the breakdown on the losing line reads `crowd 39.4, events 0.0` / `crowd 44.4, events 3.1` /
      `crowd 28.8, events 0.0`. That is playtest 07's finding 17 after the milestone that answered
      it, and two of the fourteen are downstream of it. **The next milestone**, measured rather than
      argued — not this one

### And the tooling that is getting in the way

- [x] **The test suite takes too long to run.** Done as **M44**; it was 8.4 minutes and is 96
      seconds. Not one of the four things this entry proposed turned out to be where the time was —
      see the milestone for what measuring found instead.
