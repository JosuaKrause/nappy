# minty-quail — Where she is has one channel, and the halo's word on the point goes · 2026-11-17

**The ask.** "whatever is the *correct* implementation" (inbox #1278 in olive-ferret), the
player's answer to whether a step of the events' interface design
(`docs/todo/2026-10-18-minty-quail/event-interface.md`, section 7, point 6) fixes an answer that
is slightly wrong today. The item named three such answers; this record settles the last, the
bullet "The halo's word once a drawn frame reaches only the events it lights; every other live
event keeps the tick's word."

## The premise was stale

The bullet was written when where she is was one object being built (minty-quail-olive-finch).
The code does not do what it assumed: `ExcitementHalo._pick_and_predict()` calls
`ExcitementSource.set_player_at()` on **every candidate**, every live event and the whole crowd
(`EventSources.every_source()`), not only the events it lights, so the halo's word reached every
live event already. What was wrong about it was something else: `EventExcitement.set_player_at()`
also called `WhereSheIs.see_her_at()`, so an event heard where she is through **two channels**, the
manager's word once a physics tick and the halo's once a drawn frame, and the second shadowed the
first until the manager's next word.

## What was built

- **One channel.** The event manager tells `WhereSheIs` once a tick, and nothing else tells an
  event where she is. `EventExcitement.set_player_at()` is no longer overridden: it was the halo's
  word on the point reaching the event's handle and did nothing else. The halo still hands every
  source her velocity, decay rate and sensitivity once a drawn frame (an event's projection needs
  them), and a crowd body's source still takes the point from it, since the crowd has no manager
  word; an event's source reads the point from its handle alone (`EventExcitement._her_at()`).
- **`WhereSheIs.see_her_at()` stays**, for the one thing that still tells an event a point itself:
  a task that sets a man on her (`EventInstance.notice_her_at()`), which is its own until the next
  word.
- **No event loses a first-frame position.** An event made after the tick's word hears the word so
  far, and `forget()` clears it at a walk's start (the record of where she is as a handle,
  minty-quail-olive-finch, and the officer's facts after it); the halo's word was never what gave
  an event its first position.
- **The check** is `tests/test_excitement_source.gd`, "the halo's word on where she is, once a
  drawn frame, changes nothing the caret reads": the halo's call on an event's source with her on
  the lethal reach leaves the caret where the manager's word put it. At main the caret read 2, the
  doubled red, from the halo's point; now 0. Six suites had set where she is for an event
  through the halo's call (`test_danger`, `test_event_redraw`, `test_drawn_view`,
  `test_tutorial_dog`, `test_resistance_steps`, `test_world_passability`); each now tells the event's `WhereSheIs`, the
  way the game does.

## What changes in play and in the run log

Nothing she sees. Nothing moves her between physics ticks (the stroller is a body moved in the
tick), so the point the halo gave a drawn frame was the point the tick had already told. Held to
it by `tests/probes/excitement_fingerprint.gd` at main and at the head: its `XF` lines, what every
source charges her tick by tick over days 1, 9 and 14 of two seeds, the escape's city and the
building, are identical (20515 lines each, `diff` empty). The run log names nothing differently.
(`tests/probes/olive_badger_route_mix.gd` measures the director's handouts and does not touch the
halo; the fingerprint is the probe that does.)

## Open to the player

The one-channel reading is the orchestrator's, not the player's words: "whatever is the *correct*
implementation" names no mechanism. The plainer alternative the premise offered, the halo's word
reaching only the events it lights, would keep two channels and was not taken. If a reader truly
needs the drawn frame's position rather than the tick's, it asks the player's body itself; no
reader does today.
