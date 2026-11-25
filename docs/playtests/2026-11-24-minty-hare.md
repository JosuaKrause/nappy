# Playtest minty-hare — The spawning that is implemented may be far from the rules the player defined

2026-11-24.

Two notes, said in the orchestrating session's chat on 2026-11-25 (UTC): #1737 after an explanation
of where the escape's dog walker comes from, #1740 answering the board question
escape-convoy-at-dawn.

## #1737

1. **The note.**

   > we have very precise rules around how spawning should work and this doesn't sound at all like how we defined it. this sounds like what is implemented is pretty far off from what we wanted

2. **Context** (the assistant's):

   Said in the orchestrating session's chat on 2026-11-25 (UTC), after the orchestrator explained (twice wrongly, then corrected) where the escape's dog walker comes from: that every event is drawn from one of two bags — the dawn's units (the three views on, beside and off the planned route, each with its own bag; on the escape every unit drawn before she sets off) and the event director's route bag, drawn only to fill moments the dawn's plan owes her route and sited just ahead of her on the branch of the route tree she walks — and that on today's code the escape's route bag is filled with the ordinary rows but never drawn from. Related notes: #1733 (no dog walkers in the escape), #1736 (its filing).

3. **Read as:** (the assistant's interpretation, not the player's words)

   An Opus read-only audit (.claude/briefs/designs/spawning-audit.md in the orchestrator's checkout, read from main at 47e465438, not measured) compared every rule the player set for where and when an event appears with the code. Ordinary days follow the rules. The escape diverges: the event director, which sends events at her while she walks, is started for the escape like any day and never reads the escape's settings; it fills an ordinary day's route bag chosen by the run's day number. Booted straight into the escape (--start-escape, ?escape=1) the run is on day 1, so day one's rig makes two of her first three encounters dog walkers — which fits #1733. Reached from a run (day 14) the director can send the charging dog one escape in four. The context of this note, and the dog-walker item filed in #1736, said main's escape sends nothing; that is wrong on the direct boot. The escape bag also holds 9 empty marbles, second after trucks, where the player's order puts empty last (known, waiting on lilac-marten). The refactor made the escape a day spec on the player's "all should be implemented through the regular game engine's means" (minty-lemur #785), so this is the refactor's defect: read as filed in band bug and fixed before minty-quail's closing pull request.

## #1740

1. **The note.**

   > no, trucks get placed ahead of her if they're on route. are you referring to trucks as barriers? if so then, sure they're off route blokades

2. **Context** (the assistant's):

   Said in the orchestrating session's chat on 2026-11-25 (UTC), answering the board question escape-convoy-at-dawn: "should the escape city's army trucks, like a day's convoy, be sent ahead of her as she walks, not placed before she sets off? (built on my pick)", whose pick was to keep them placed. The escape's trucks are marbles of military_convoy, the moving army truck, in the escape's one bag (DaySpec._place_the_escape_city()), placed on its streets before she sets off; on an ordinary day the convoy is sent just ahead of her. The streets off the escape's walk are sealed with barriers drawn as army trucks (the escape's seal pictures), which close streets she does not walk.

3. **Read as:** (the assistant's interpretation, not the player's words)

   The escape's moving army trucks on her route are sent ahead of her as she walks, as a day's convoy is, not placed before she sets off; the barriers that seal the streets off her walk, drawn as trucks, stay placed as off-route blockades. My pick on the board is overturned.
