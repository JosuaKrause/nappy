## M76 — A screen offers something to press, the rest of it · built 2026-09-06

Playtest 26's last two findings and playtest 27's third, which is the restart's third asking. The
title screen's half was built first and is the entry below.

**The summary's tap-anywhere was never broken, and finding out cost more than a fix would have.**
*"on mobile when the day ends or one dies you have to tap on the text"* contradicted the source
outright — `DaySummary._unhandled_input()` accepts any pressed `InputEventScreenTouch` with no
position test, and neither touch handler calls `set_input_as_handled()` — so the entry made the
investigation the deliverable rather than a fix. It was settled by booting `day_summary.tscn` inside
a real `SceneTree` and firing a genuine touch at (20, 20), far from any text and through the `Dim`
`ColorRect` whose `mouse_filter` is `STOP`: `continued` fired. **A raw touch bypasses Control hit
testing entirely** — only the *emulated* mouse click goes through that path — so the scrim was never
in the way. The report was **discoverability**, which is the player's own alternative reading:
*"or it should be obvious where I need to tap"*, and the buttons are the answer.

**The restart shipped inert on one of its two screens, and a green suite said nothing.** The
day-summary button held, filled its bar and emitted `restart_requested`; `main._ready()` connected
`_pause.restart_requested` and nothing at all connected the summary's. **What let it through is that
every test asked whether pressing the button emits the signal, and none asked whether the signal
reaches anything.** The four connections are now one function, and the test calls
`Signal.is_connected()` on both screens directly rather than driving a press — a distinction worth
keeping, because the wiring is the half a review of the diff does not see.

**The press acknowledgement is two `await get_tree().process_frame`, and one is not enough.**
`SceneTree.process_frame` fires *before* the frame it names is drawn — confirmed against
`RenderingServer.frame_pre_draw`/`frame_post_draw`, which both fire only after the first await has
resumed. The first version awaited once, cleared the pressed look before a pixel of it reached the
screen, and **nothing in the suite could see the difference**, since a frame that is never drawn is
invisible to every assertion about state. It was caught by a screenshot rig that showed no flash at
all. The second await is what lands after the draw between them.

**Why the flash is forced rather than a `Button`'s own pressed state.** The catch-all is what fires
for most presses — nothing requires landing on the button — so a native pressed state, which only
answers a press that actually hit, would leave a tap on the bare scrim with nothing to show. Both
now go through `ModeButton.force_pressed_look()`. The keyboard branch stays synchronous: `space` has
no on-screen button to flash, and a wait with nothing to show for it is latency for its own sake.

**A one-frame gap is a one-frame window for a second tap**, found while building it rather than
after: a coroutine that has not resumed does not stop `_unhandled_input` reading the next event as a
fresh press, so a fumbled double tap started the day twice. A `_continuing` guard closes it.

**The delay behind the complaint was measured and nothing was moved on the strength of it**, which
the entry required. `_start_day()` — planning the day's closures, placing every event, streaming the
world around the doorstep — is **610–740 ms on day 1 and 860–910 ms by days 8–14**, against city
generation's 280–450 ms; it is the dominant cost and it grows with event density. **Day 1 is
provably off every button's path**, paid during `_ready()` before the title opens. The web half —
shader compilation and texture uploads on the first frames after a screen closes — is not measurable
headlessly and stays unmeasured. What to do about the wait is a decision for the player, and the
acknowledgement is what this milestone owed regardless of the answer.

**`PauseScreen.resumed` has no listener in `main.gd` at all**, found during the same audit. Its
catch-all closes the screen and emits into nothing, and both are instant, so it was left alone —
recorded because it looks exactly like the bug above and is not one.

**Choices made where the design was silent**, each cheap to overturn: the hold is exactly 1.0 s
(*"about a second"*, taken as the round number); restart's glyph is a three-quarter ring with an
arrowhead and continue's a play triangle, matching the reference picture rather than the plain arrow
the player offered as a suggestion; the fill bar is a linear rectangle under the disc rather than a
ring around it; the buttons appear on touch only, and a desktop keeps `space`/`esc`/`r` as text
because a key already reads as a control there; and the final ending screen gets the same pair even
though a plain tap there already restarts, chosen for *one interaction to learn* over a special case.
