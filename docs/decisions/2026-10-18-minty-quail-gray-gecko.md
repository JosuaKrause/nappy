# minty-quail — The day director's members only its own class used become internal · 2026-11-19


minty-quail's `tests-own-class-members.md`, the underscore pass, for one module outside the events
and the resistance: the run's day director (`src/run/day_director.gd`), the one start every walk goes
through and the one place a day's outcome is decided. A public member only its own class and the
tests use becomes internal and its tests move to what the class does outward (curly-rabbit #1098).

**Which module.** Outside `src/events/` and `src/resistance/`, which wait for the events' interface
rows, three owners had members under the list's `[own file only]` group: the scene recipe runtime
(`manifest`, `named`, `start_position`, `tick`), the day director (`events`, `player`, `day`,
`landed_by_group`) and the screen-edge badge's control (`model`, `sees`, `view`). The first two
tie at four. The day director was taken: the scene recipe runtime is still named in the events'
interface row 3c and in the scene recipes' own pass with the authored scene (`city-hand-ins.md`),
so its file waits on the events track.

**Built.** Internal: `DayDirector._events`, `_player`, `_day` and `_landed_by_group()`; their four
lines leave the list. `tests/test_day_director.gd` moved to what the director does outward:

- the crying-cause checks read the cause `EventBus.day_ended` carries, never the grouping. The bare
  world's empty grouping is held by its cause being `self` (the check that the grouping was empty
  went, since the cause already depends on it); the pelican's own group is held by two cases, the
  pelican landing more than a cyclist beside it (lost to the pelican) and the cyclist landing more
  (lost to the cyclist): the two shares merged would name the cyclist both times, either dropped
  would name the other both times. The exact grouping's read-back, `{"cyclist": 3.0, "pelican":
  5.0}`, went with it;
- the rig hands back the event manager it built, and the suite spawns and clears through it rather
  than through the director's field;
- the won day with a player and no city hands her in the world through `use_the_world()`, as the
  game hands her, rather than writing the director's field; the world then hands her to the events
  too (`EventManager.use_player()`), as in play.

`day` had no test read on a `DayDirector`: the check counted a test receiver it cannot type that
reads another class's `day` (`planned.day`, `fixture.day` and the like). It became internal with the
others, since nothing outside the file reads it.

**Mutations run.** Grouping each live event by `row_id()` instead of `logged_name()` fails the
pelican case (got `cyclist`); dropping the events' shares from the grouping fails both cases (got
`self`). Dropping the city guard from the won day's unmet-fire branch (`_in_a_city`) passes this
suite and main's alike: the player case holds that such a day ends, not that the fire is skipped,
and was not weakened here. No test was added for it, since the pass keeps test parity.

**Docs.** The comments naming `DayDirector.landed_by_group()` (`Baby`, `LossCause`,
`tests/test_loss_cause.gd`) and `docs/TELEMETRY.md`'s crying-cause paragraph name
`_landed_by_group()`.

**Remeasure:** nothing; no behavior changed.
