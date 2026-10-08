# Playtest dotted-sparrow — The unused joystick becomes Run, and steering chooses the side

2026-10-07.

## #602 — run button should replace other joystick

The player's note on [issue #602](https://github.com/JosuaKrause/nappy/issues/602),
labelled `queue_now`:

> instead of having the run button as separate button whichever joystick button is unused should turn into a run button. also, the size of the run button should match the size of the joystick button otherwise it is easy to miss

The player's comment on 2026-10-06:

> Also the effective radius of all buttons (except the joystick dead zone) should go 5% over the visual radius

In the implementation session, after the assistant described checking how the controls choose a
side and retain touch ownership, the player clarified:

> no, the player chooses a side by using the joystick

After the assistant read this back as using a joystick selecting that side for steering and the
opposite joystick becoming Run, without a separate side selection:

> also it's not permanent

The assistant asked: "Should both joysticks return when the steering finger lifts, so the next
press can choose either side? Movement would keep its existing behavior of continuing after
release." The options were "Yes—restore both when steering ends (Recommended)" and "Keep Run
visible until the player steers from the other side". The player selected:

> Keep Run visible until the player steers from the other side

After the assistant read this back as Run staying visible after release and a later steering
action from the other side swapping the roles, the player added:

> steering can also be done by tapping so we shouldn't immediately reset

**Filed as round-gecko, the unused joystick becomes Run.** Taps and drags choose the steering
side; release does not reset it. A later steering action on the other side swaps the roles.
