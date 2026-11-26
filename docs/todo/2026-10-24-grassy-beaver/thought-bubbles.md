# Thought bubbles over the mother, a few times per lesson

The player: "thought bubbles -- I really like that idea for immediate feedback especially since it
doesn't need reading. it can be a direction to a park (on day 1), a hint to avoid an obstacle, a
hint to cross the street, a hint to turn around, etc.", then "agree with the thought bubble. it
might even make the text obsolete but we should make it so it only shows a few times for each new
lesson. we don't want to clutter everything with constant thought bubbles. but it will become useful
eg to also show that guard huts can be walked through" (curly-moose #819).

**Build:** a bubble over the mother holding an icon, no words: a park and a direction (day 1), an
obstacle to avoid, crossing the street, turning around, and later lessons such as the checkpoint
hut that can be walked through. Each lesson's bubble shows only a few times, at the moment it
applies, then never again. What is open is the mechanics that show them: what counts the shows,
what decides that a hint applies and where it points, and the node that draws the bubble over her.

**The pictures the mechanics draw** are the frame `art/ui/thought_bubble.svg`,
the pointing arrow `art/ui/hint_arrow.svg` (drawn pointing east and turned toward the way to go),
and one icon per hint in each of two sets, all on the `ui` atlas page: the first set, a small
scene per hint (`art/ui/hint_park.svg`, `hint_back_to_route.svg`, `hint_crosswalk.svg`,
`hint_cross_street.svg`, `hint_turn_back.svg`, `hint_noise.svg`, `hint_chalk.svg` and
`hint_hut.svg`), and the simple set beside it, just each hint's thing (`hint_<hint>_simple.svg`
for the same eight). The player asked for the simpler pictures and to "keep both versions for
comparison" (inbox #1771, #1772 and #1773 in spry-wombat). `docs/GRAPHICS.md` gives each one's
size, anchor and the place in the frame its icon and arrow go; which set the mechanics draw is a
question on the Nappy board's main tab, and the mechanics draw whichever the player keeps.

**Two bubbles asked for since:** the zebra-crossing bubble on day 1, shown when she steps onto the
road away from a crossing (minty-dolphin #834, #867; `car-free-start.md`), and one for the chalk
mark: "also a thought bubble should hint on going into the alley to get the mark"
(minty-dolphin #868). The chalk mark is the resistance's first encounter, a mark drawn in an alley that she walks in
to touch, with the alley's robber at its far end; day 6's brief names the rumor of chalk and the task
has its red arrow (`CLAUDE.md`, "Things deliberately not done"). **Read as:** on the day the chalk
mark is first there, a bubble hints that she can go into the alley to reach it, beside the brief and
the arrow. What sets it off, the player: "I mean it's obvious, no? when the mark becomes visible to
the player for the first time it causes a thought bubble", and "how else would that make sense?"
(gentle-owl #1234). **Read as:** the bubble shows when a chalk mark first comes into view on screen,
and like every lesson's bubble only a few times in all ("a few times for each new lesson",
curly-moose #819).

**A bubble that points her back to day 1's tutorial route.** Of day 1's tutorial
(the records grassy-beaver-silky-wombat and grassy-beaver-golden-puffin): "every time she tries to leave the tutorial route there is a thought
bubble that guides her back to the tutorial route. she can choose to ignore it" (gentle-owl #1253).
**Read as:** each time she starts to leave the tutorial route, a bubble points her back to it; it
shows every time, unlike the few-times rule of the other bubbles, and she may walk on regardless.
It shows wherever she leaves the route: past the first block the side streets carry soft seals,
which leave the carriageway open, so she can still leave there in the road (the record grassy-beaver-silky-wombat).

*Proposed, not asked for:* the bubble looks unlike the danger exclamation mark already drawn over
her, since **cues** keeps that vocabulary short; "a few times" starts at three per lesson per run,
and whether a retry of a day counts is the builder's to state.
