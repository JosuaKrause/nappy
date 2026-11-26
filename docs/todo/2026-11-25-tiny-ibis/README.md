priority: next

# tiny-ibis — The touch controls hide the view's bottom corners, where a charger can warn · filed 2026-11-25

**The defect.** In the joystick mode the steering ring and the Run disc cover the view's two bottom
corners, and the game already says those corners are not visible to her: `VisibleView` lays the covered
corners onto the camera's view and `visible_share()` leaves them out (feathery-lynx #581, which asks
every place where visibility matters to follow it, and to treat the tap mode as the whole view). Yet a
waiting charger on screen (the dog, the robber, the roadblock's guard) is sited and judged against the
camera's whole view, corners included (`SpawnSiting.on_the_view()` and the whole-view tests that read
`VisibleView.camera_view()`), so he may stand under a covered corner and raise his hand there, and the
warning goes unseen.

**Read as:** under the two kinds of charge (the note on them, GitHub issue 1774, filed in PR #1785, and
velvet-marten #699, every charger is neutral, then warns, then charges) a charger who is on screen must
warn where she can see him. A hand raised under the Run disc is no warning.

**Source:** finding 4 of the Opus review of PR #1785
(https://github.com/JosuaKrause/nappy/pull/1785#pullrequestreview-6067438071).

**What a builder does.** Read the code that decides "in her view" for a waiting charger (the whole-view
test in `src/world/spawn_siting.gd`, `EventManager`'s on-screen reads, and where the charger's rest
turns into its warning in `src/events/simulation/behaviours/event_pursuit.gd`), and decide which kind
the charger is by what she can see (`VisibleView.sees()`, the corners removed), so a charger whose body
is under a covered corner counts as out of view and arrives as the off-screen kind (badge, already
charging) or waits to be sited clear of the corners. The pop-in rule stays: a thing never appears or
vanishes inside the camera's whole view. The fix goes where the decision is made, never as a second
test beside it, and a test holds both modes (the tap mode keeps the whole view).

**Proposed, not asked for:** the band `next` (the filer's proposal; the player named none), and which
of the two ways out above a charger under a corner takes. The plainer alternative is to move only his
raised hand's place, which leaves him standing where she cannot see him.

**Alive beside it:** fix-1785 (two kinds of charge, events code) and finish-1752 (M199, the roadblock that
closes its whole street); this entry touches neither's files while they are open.
