# minty-quail — Where she is has one channel, and the halo's word on the point goes · 2026-11-17

**The ask.** "whatever is the *correct* implementation" (inbox #1278 in olive-ferret), the
player's answer to whether a step of the events' interface design
(`docs/todo/2026-10-18-minty-quail/event-interface.md`, section 7, point 6) fixes an answer that
is slightly wrong today. The item named three such answers; this record settles the last, the
bullet "The halo's word once a drawn frame reaches only the events it lights; every other live
event keeps the tick's word."

## The premise was stale

The bullet was written when where she is was one object being built (minty-quail-olive-finch).
The code does not do what it assumed: `ExcitementHalo._pick_and_predict()` told **every
candidate**, every live event and the whole crowd (`EventSources.every_source()`), her point
through `ExcitementSource.set_player_at()`, not only the events it lights. What was wrong was
something else: an event heard where she is through **two writers**, the manager's word once a
physics tick and the halo's once a drawn frame (`EventExcitement.set_player_at()` called
`WhereSheIs.see_her_at()`), and a third, a task setting a man on her
(`EventInstance.notice_her_at()` called `see_her_at()` too). The latest writer shadowed the
manager's word until its next one.

## What was built

- **One channel, no second writer.** The event manager tells `WhereSheIs` once a tick and nothing
  else tells an event where she is. `WhereSheIs.see_her_at()`, its stored point and its word
  counter are deleted, and so is the write in `notice_her_at()`. The notice's own inputs, the
  heading, the notice clock and `EventPursuit.was_set_on_her()`, keep taking her position as an
  argument: they are an order, not a word on where she is. Every caller passes the point the tick
  tells anyway (the resistance director its player node's position, the recipe runtime her
  starting place). **The director's fallback**, to the contact's place when it has no player (a
  rig only), sets the man heading there and he then hears nowhere until a manager tells a word;
  nothing in the game reaches it.
- **`set_player_at()` is split, so a call never means two things.** Every source takes her motion
  through `ExcitementSource.set_her_motion(velocity, decay_rate, sensitivity)`, which
  `ExcitementHalo` calls once a frame. A crowd body, which hears no manager's word, is told the
  point through its own `CrowdExcitement.set_her_at()`, which the halo calls for a crowd source
  only. An event's source has no point to be handed: `EventExcitement._her_at()` reads its
  handle. A source with no account of its own measures from nowhere (`Vector2.INF`).
- **This overturns the orchestrator's earlier reading** that the notice's point is an order kept
  on the event's handle ("an order, not a channel"): the review found it could not mean "chase
  from here" (it lasts only until the next word) and that every caller hands over the point the
  tick tells. The player's words, "whatever is the *correct* implementation", name neither
  reading.
- **No event loses a first-frame position.** An event made after the tick's word hears the word
  so far, and `forget()` clears it at a walk's start (minty-quail-olive-finch and the officer's
  facts after it); the halo's word was never what gave an event its first position.
- **The checks.** The split of the method holds the halo's half of the guarantee by its
  signature: the halo hands a source only her motion (`set_her_motion()`, which takes no point),
  and only a crowd body is told her position (`CrowdExcitement.set_her_at()`), so no check can
  state it. The check that fails at main is `tests/test_where_she_is.gd`: a robber set on a far
  point (`notice_her_at()`) read that point back through `sight_line_to_her()`; now a pursuer
  set on a far point still hears her where the tick put her, and the next word moves it.
  `tests/test_excitement_source.gd` holds that an event's caret reads the point its instance's
  handle says. Six suites that put her somewhere for an event through the
  halo's call (`test_danger`, `test_event_redraw`, `test_drawn_view`, `test_tutorial_dog`,
  `test_resistance_steps`, `test_world_passability`) now tell the event's `WhereSheIs`, as the
  game does; the crowd's tests tell `set_her_at()`.

## What changes in play and in the run log

Nothing she sees. Nothing moves her between physics ticks, and the stroller steps before the
event manager in a frame, so the point the halo gave a drawn frame was the one the tick had told.
Held to it by `tests/probes/excitement_fingerprint.gd` at main and at the head: its `XF` lines,
what every source charges her tick by tick over days 1, 9 and 14 of two seeds, the escape's city
and the building, are identical. The run log names nothing differently.

## Open to the player

The one-channel reading is the orchestrator's, not the player's words: "whatever is the *correct*
implementation" names no mechanism. The plainer alternative the premise offered, the halo's word
reaching only the events it lights, would keep two channels and was not taken. A reader that
needs a drawn frame's position rather than the tick's would be told by the one channel; none does
today.
