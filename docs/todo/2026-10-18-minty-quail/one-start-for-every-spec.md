# One start for every spec: the days, an authored scene and the escape begin the same way

**The ask.** "there really should be no separate code for escape", "the escape is just like a
normal day with some special settings", "all should be implemented through the regular game
engine's means" (inbox #785 in minty-lemur). This entry's README has one controller start and finish a spec.
The design review found that the day director (`DayDirector`, the class that starts and ends a
day) finished every spec while a spec was started in three places, the escape's start hand-built
in the main scene with a run-log path and a start signal of its own. Shown that as "A day
is finished by one controller but started in three places. The escape's start is still hand-built
in the main scene, with its own run-log path. That is where the fuller escape and the explosions
would land next", the player: "can we improve this?", and to the plan below, as the orchestrator
summarised it ("One `start(spec)` for every kind of day, with the world built per spec by a builder
handed in, one day-started event, and the run log watching any spec the same way"): "agree on all
design review points. let's do it" (inbox #1268 in olive-ferret).

**Read as:** no code outside the spec's own settings asks whether the escape is being walked in
order to start it, and an escape start is testable without booting the whole game.

**What is left**, the design review's shape, which the player approved ("I saw the review and
approved it", inbox #1268 in olive-ferret); the detail was worked out by the same review after the approval:

- **Who builds the event manager and the crowd**, with the third hand-ins pull request
  (`city-hand-ins.md`): the city scene stops building its own, and the building and the city get
  theirs from one factory (`standing-layer-breaks.md`, the city scene as builder).

**The pull request:** it touches the event manager's setup and lands between two placement pull
requests (`city-hand-ins.md` holds the proposal to cut it).
