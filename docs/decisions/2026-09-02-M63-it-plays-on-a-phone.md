## M63 — It plays on a phone · built 2026-09-02

**Asked for by the site being live and unusable on a phone.** *("I can't start the game on mobile —
there is no space", "the title screen requires me to press space".)* Three screens were gated on
`ui_accept` and nothing anywhere handled a touch, so the page could be reached and not started; past
that there was no way to walk either.

**The fork that was put to the player**, because the two answers wanted opposite things from the
title screen: make it playable, or say honestly that it needs a keyboard and stop. **Playable.** A
third option — tap-to-start only — was offered and argued against here, on the grounds that it turns
a visible dead end into a quieter one: you would tap in and meet a game you cannot steer.

**The stick and the button press the same actions a keyboard does.** `Input.action_press(name,
strength)` on the four `move_*` actions and `run`, so `Stroller` never learns where its vector came
from and no gameplay code changed at all. That is the whole reason this was cheap.

**Running is a separate held button and may never be a stick threshold**, which is the one decision
in here that is about the game rather than about input. `Stroller` moves toward `input_dir *
top_speed` with the **raw** vector, so a partly deflected stick is *already* a slower walk — making
running the far end of that same push would turn the one deliberate act in the game into a gradient
a thumb crosses by accident. The two controls read independent touch indices and sit at the same
height on opposite screen edges, so a steering thumb never crosses a holding one.

**A touch device is `DisplayServer.is_touchscreen_available()`, not `OS.has_feature("mobile")`**, and
the reasoning generalises: this game ships as **one** Web export that runs unchanged whether the tab
is opened on a phone or a desktop, and a feature tag is baked in at export time — so it would answer
identically for every visitor and could never drive "the controls appear only where they are used".
*Cost accepted: a touchscreen laptop gets the overlay beside a perfectly good keyboard, which is the
smaller of the two mistakes next to a phone told to press a key it does not have.*

**Two teaching bugs were found by playing the same build and fixed alongside it.** The day-3 run
lesson was once per **run**, and a lost nerve is not a new run — `main._start_day()` restarts the day
on a HUD that is never rebuilt, so the second attempt at day 3 was the first one that had already
spent its lesson and every attempt after it stayed silent. The flag now belongs to the *attempt*: a
nerve is a rewind, and a rewound day has not been taught anything. *(This side's first hypothesis —
that the signal fires at instance creation rather than at the encounter — was wrong, and the player
supplied the actual cause.)* And `_teach_the_pause()` read a **detained** player as having stopped of
her own accord, offering the pause key at the exact moment her controls were taken away; it is now
stated over the class — *idle **and** nothing holding her still* — because the HUD also keeps
counting behind the title, the pause and the day summary, all of which pause the tree.

**What nobody has verified**, and it is most of the milestone: no thumb has touched any of it. The
controls are built, tested and screenshotted on a desktop, which proves only that they stay *off*
where they should.
