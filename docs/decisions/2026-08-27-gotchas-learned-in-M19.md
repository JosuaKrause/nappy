## Gotchas learned in M19

- **A green suite and a screenshot both passed a collision that was catastrophically wrong.**
  A pedestrian slower than the player was pushed *further along their own line of travel*,
  which separates nobody at 92 against 60 — so she accumulated a wedge of pedestrians in front
  of her, all permanently in contact, all permanently startled, at 150 excitement per second.
  Nothing in the test suite could see it and the screenshot showed a normal street. Forty
  seconds of a scripted walk down a real pavement showed it immediately. A bumped body **steps
  aside** now.
- **The contact radius is set by the lane spacing, not by a body's width.** The only line with no
  contact on it is the midline between two lanes. At 18px there was no such line anywhere on a
  two-tile pavement: the same forty-second walk cost eleven bumps however carefully it was done,
  which is a toll rather than a decision. At 14px it costs two. That relationship is the assertion
  in `tests/test_crowd.gd`, not the number.
- **And the line has to be wide enough to aim at.** *(M46.)* With the lanes on their tile centres
  it was `32 − 2 × 14` = **four pixels**, which is a line a player is occasionally on rather than
  one she chooses — while forty seconds down an arterial lane centre cost 15.3 contacts and the
  midline cost none. `CrowdLanes.SIDEWALK_LANE_SPREAD` pushes the two lanes of a footway apart to
  make it 20px. Widen the **street**, never the body: `BUMP_RADIUS` is what makes a contact mean
  walking into somebody.
- **A contact has to startle once, not once per frame.** She walks faster than a pedestrian, so
  a person bumped from behind stays inside the radius for the better part of a second.
  `CrowdAgent.touching` is the hysteresis; without it one person cost what a crowd should.
- **The throwaway probe is the headless stand-in for playing a minute.** A
  `tests/test_zz_*.gd` that prints numbers and is deleted before committing found both of the
  above and set `budget_for()`. `CLAUDE.md` carries it next to the screenshot rule.
- **A budget is not a count, and the gap is about a third.** `_ensure_one_usable_park` strips
  whatever reaches the calmest block and `_ensure_the_city_is_still_walkable` drops
  obstructions that would seal the city, so a budget of 18 places 13 or 14 events. Density has
  to be measured from what a day *places*, over several seeds. Deriving it from the formula
  gets you a number that is a third too small and looks right.
- **`move_and_slide()` owns `velocity`.** Folding the collision deflection into it made
  `is_idle()` and `run_excess_ratio()` answer for the crowd rather than for the player;
  restoring `velocity` afterwards was worse, because it discards the slide's own correction
  and walking into a wall stops reading as idle. The deflection goes through its own
  `move_and_collide()`.
- **A cue over the player's head has to stay near the player's head.** At 68px the exclamation
  mark drifted far enough up the screen to read as belonging to whatever was standing behind
  her — which, for the one cue in the vocabulary that means *this is about you*, is the single
  thing it must not do. She is 46px tall; the mark sits at 54.
- **A dead comment survives a deleted feature and then lies about its neighbour.**
  `busy_road`'s doc comment outlived it by six milestones in `event_catalogue.gd`, ending up
  attached to `_dog_walker()` and describing arterial traffic noise. Deleted here.
