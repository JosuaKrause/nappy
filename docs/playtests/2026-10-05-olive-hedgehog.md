# Playtest olive-hedgehog — The trailer, the camera without limits, a poster's instant pursuit, the forced cases' bags, warnings for a heavy penalty, any live mast

2026-10-05. Seven notes captured in sessions on 2026-10-05, #579, #586, #587, #591, #595, #598 and
#599, each said in a conversation about the work in hand rather than while playing. Each of the
player's words is copied word for word, after what it answered where the note records that. The
routing of each note is at the end.

## #579 — The trailer, remade around the saved scene recipes

Captured in a Codex session on 2026-10-05, a request rather than an answer. "The newly created
scene recipes" are the saved scenes described in [SCENE_RECIPES.md](../SCENE_RECIPES.md): JSON
files under `scene-recipes/` that build an exact development scene, which the trailer's shots can
start from. The trailer then was M204's (a trailer, rendered from the game by a script), its beats
in [PLAYTEST-139](PLAYTEST-139.md). The work became PR #580 (the trailer reimagined around saved
scenes).

> with the newly created scene recipes reimagine the trailer. the main beats / gameplay should still be there but you have freedom to do whatever you think works best -- if needed you don't need to restrict yourself to in-engine footage only

The player's further words while Codex built and rendered it, in the order they were said, with no
question recorded before them:

> tell me where I can find the video file when you're ready -- remember no checking in video files from this

> what are those weird movements in the beginning where the camera starts at the top left and goes to the position. just start recording a few frames later?

> the first "wrong turn" scene is too fast to realize that the player did a "wrong turn"

> you only applied the pan in fix to the first three shots. the first shot should 1) start further away 2) turn away further away 3) the walking towards it should be longer to actually get a sense of cause and effect 4) the movement overall needs to be more precise. the second shot has the man not walking at all? *always* keep moving! the title cards can benefit from some improvement. also what is the audio? where did you get it from?

> if you need to change the scenery -- do so
>
> also the final zoomout has some black bars left and right -- should be green grass and the water and mountains

> start recording things when they are already in motion and everything has settled -- that way you get smooth movements.

Said in a Claude Code session on 2026-10-05, while PR #580 was being finished: the render built
from the pull request's source was available locally (`build/trailer/trailer.mp4`), and the player
was asking for its last items (the loaded-render check, the queue move) to be done.

> the video itself is okay -- much better than the previous version

> music and audio mix is okay, too

Asked to watch the 01:39 render (26.4s, rendered from PR #580's head 76d06f08, copied at 04:07 to
`build/trailer/trailer.mp4` in both checkouts), since the earlier "okay" was probably about the
00:19 render Codex had delivered:

> I watched the latest version it's better than the previous one

> the only change I'd make is in the first scene she is walking through a car -- move the car further back on the road or have this one not appear or move all the way back to the sidewalk and cross the street properly

> also can we flip the guy's scene with the birds and let it play out a bit longer it stopps too early right now

Asked two questions about the birds shot (the father's, 1.5s, between the opening wrong turn and the
charging dog; the trailer then 26.4s under a 30s cap): (1) what should "flip" do — swap its order
with the dog, mirror it left to right, or swap the parent; (2) how much longer — until the birds
settle (about 3s), about 2.5s, or about 4s.

> move the park to the left side and have the guy walk right to left
>
> About 4s
>
> flip the entire scene horizontally -- the park to the left -- the player walking to the left

> also the just a walk slide show it 500ms longer

> a missing font should be loud and not create a wrong trailer
>
> why did you reuse the city of the dog chase for the bird scene instead of moving the bird scene park to the other side?
>
> also the dad should steer into the park at the end of the scene

> cars are visibly driving behind the tunnel on the mountain -- they should either be behind the mountain or despawn once they enter the tunnel fully

> narratively the first scene doesn't make sense or maybe it's a bug but the pacing should be her walking towards an obstacle, then noticing that it excites the baby, then turning around and crossing the street. in the scene she walks much closer to the leafblower than you would (this makes sense since it is a trailer meant to show what happens+halo). but then the halo shows up again when she is on the other side of the street teaching the wrong lesson. any ideas?

> we can keep the truck tests to not silently degrade the trailer

> but the tests must adjust to the trailer when we edit the trailer -- not the other way around

Answering the agent's explanation of the quiet-versus-loaded check (each shot rendered twice, idle
and under a CPU load, its frame and audio hashes compared, from PLAYTEST-139's "the same output
every time"), and its plan for the wrong-turn shot (after the crossing, her way leads out of the
leaf blower's 190px field, for example up the side street):

> "the same output every time" should happen by construction. running each render twice is just wasteful.
>
> no the walking in scene one is fine -- maybe use a different event? or do the cut before it reaches the 190px again
>
> place the leafblower further south then it should be fine

> I think we need to change the first half of the trailer. the scenes as you are building them are fine. but we should have a text card in between each to state the game ideas. "she won't settle inside. let's walk her outside until she falls asleep", "outside is crowded, we need to find a quiet place", "a park, it is quiet here", "finally she sleeps" (paraphrase each if needed) then scenes 1) just walking down the street with nothing out of the ordinary happening (build a new scene) 2) the current scene 1 3) the current scene with the birds 4) a closeup of the female player in a park where the zzz switches on mid scene 5) the pursuing dog 6) the regular title card 7) the premonition scenes 8) zoom out

> maybe put the text on the gameplay footage instead of separate cards?
>
> we can keep the first card and improve its text, though

> "A park. Quiet." is the birds scene -- the father sees the park and walks towards it ignoring the birds

> maybe "A park. It will be quiet there."

Asked whether, with the two new scenes taking the trailer to about 35s past the 30s cap
(PLAYTEST-139: "I think 30s should be max."), to lift the cap to 35s or trim the other shots to stay
under 30:

> no cap

> we will figure out the exact timing as needed
>
> when there is something to see

> why did you try to move the birds? the scene was fine before, no? he saw the park, walked through the birds, then went into the park? if she walks over the crossing the car doesn't matter because it will stop by itself

> okay I like it how you had it -- no changes needed

> yes, to reverting the bird scene -- let me see it then I will decide which one is better. don't change the first scene since the longer walk made it more clear what was happening

> in the zzz scene zoom in more and have her walk in a circle

> produce the trailer birds version keep both scenes around and merge -- I will decide after the merge

## #586 — The real catch test for "influenced"; olive-badger's rigged bags of 2 or 3

Asked two questions in a session on 2026-10-05:

- **(1) Telemetry** (spry-llama, the GoatCounter encounters): an encounter counted as "influenced"
  when she was inside a dangerous thing's lethal reach measured by distance only, so a guard
  through a wall, or a cyclist still only a warning badge, counted too. Keep distance only, or use
  the game's real catch test (a clear line to her and the event actually live)? The agent proposed
  the real catch test.
- **(2) olive-badger's leftover item** (`the-other-forced-cases.md`, what she meets on her route is
  drawn from a marble bag): day 7's van, day 10's neighbor and day 13's roadblock are placed at the
  chalk mark rather than drawn from her route's marble bag. Should each also get a second,
  route-drawn instance from a rigged bag, and with how many marbles? The agent proposed none for
  the neighbor and the roadblock, and maybe one for the van.

> use the real catch code. each olive badger rigged bag should be 2 or 3. use your own judgement on how soon the events should happen

## #587 — The camera keeps her centered in normal play

Said in a Claude Code session on 2026-10-05, about PR #580. The agent had explained that in normal
play the camera is held inside the city by `City.camera_bounds()` (the map grown by one block,
`OUTSIDE_DEPTH_TILES`, less the camera's look-ahead `Stroller.CAMERA_LOOK_AHEAD`), so the camera
stops at the city's edge and the view never reaches past that band; PR #580 makes the ground beyond
the band load and paint for whatever view asks, which only the trailer's zoom-out used.

> also the camera during normal gameplay shouldn't stop -- it should keep the player centered

Answering the agent's explanation of a test it had proposed for PR #580 and then dropped: a test
that a normal city's view at the camera's limits stays inside the old painted band, meant to catch
a later change to the camera limits letting the view go further during play.

> With the camera stopping at one block past the map edge, -- is there any need for this extra check? why would the camera need to stop? can never happen during normal gameplay -- now that the drawing is fixed we should not spend effort on blocking things that can never happen and are inconsequential anyway

## #591 — Tearing posters, and a torn poster's pursuit

Said in a Claude Code session on 2026-10-05, answering the agent's summary of PR #585 (merry-elk,
more posters): with more sheets on the sidewalks she walks, the sheets she could tear by accident
per route rose (day 4 from 0.7 to 4.7), and at an assumed one accidental tear in ten such sheets a
day-4 walk would draw a pursuit about 0.05 times (up from 0.007). The review had described an
accidental tear as a diagonal push against a wall for 0.4s.

> I never tore a poster by accident. even when doing it on purpose I have to make sure to tap for each poster in a row just walking by with diagonal held only tears every second poster -- not sure if it actually should be this way

Asked how tearing should work, given that a tear needed a push into the wall (at least 30 degrees
off its line, feet at its face) held for 0.4s per sheet, the timer starting over after each tear,
so sliding along a papered wall with a diagonal held tore every second sheet. The options:
**option 1**, once she pushes, every sheet she slides past tears (the first sheet still takes the
0.4s push; after that each next intact sheet tears as soon as she is in front of it while the push
is held), the agent's pick; **option 2**, shorten the push to about 0.2s; **option 3**, keep it as
it is, the docs dropping "by accident".

> option 1 for tearing

Answering the agent's change to PR #585's record, from "I never tore a poster by accident": it had
written that in play the extra sheets bring pursuits only through tears made on purpose, and had
briefed the tearing change to drop `docs/MECHANICS.md`'s "a push can still happen by accident,
which is how it is found" unless still true.

> the accidental tear statement is about how a player will learn this mechanic -- this is still the case. we don't tutorialize this -- it's an easter egg

> also, I mentioned that I have never encounter a pursuit due to tearing posters. is this a bug from the wording misinterpretation you had? where you thought pursuits shouldn't happen when a tear was "accidental"?

Answering the agent's explanation of why no tear pursuit had been met: a pursuit marble sends a
`police_patrol` (a police car) down the carriageway toward her, placed only once she walks on along
a street with a road route toward her, retrying every second; and its question whether a police car
reads as a pursuit.

> the poster pursuit should not be placed! it should happen instantly with the pursuer spawning off-screen! and it should be a proper pursuer not a police car -- maybe a policeman on foot?  (we will need a graphic for that anyway for the polic robber chase later) and a guardsman once they are in the city (earlier a guardsman won't make much sense)

Answering the agent's plan for the poster pursuit (a pursuit marble sends a pursuer on foot from off
screen at once, after M226's off-screen warning rework lands) and its question whether the
guardsman replaces the policeman from day 9 (guards first at the checkpoints) or from day 13 (the
army arrives):

> the poster tear marble bag is a completely separate marble bag than the event marbles. nothing influences across them. the pursuer is not a scheduled event. it is instant! policemen get switched to guardman on day 9.

Answering the review item `docs/review/2026-10-05-silky-plover.md` (judge the policeman on foot,
PR #594): does he read at once as police and as a danger, apart from the robber, the guard, the
crowd and the neighbor? Keep the baton or drop it? This verdict closes that review item.

> policeman looks good

Said after the agent listed the work not started this session: jolly-hare (the fire truck lethal
while driving, solid parked), pebbly-ibis (the pelican from one shared bag per run), olive-badger's
forced cases (day 7's van, day 10's neighbor, day 13's roadblock also drawn on her route from
rigged bags of 2 or 3), and the instant poster pursuit (a policeman, or a guardsman from day 9,
spawned off screen already pursuing). The player had said "things that haven't started let's not
pick up for this release".

> queue those items as immediately now after the release (but don't start them this session)

## #595 — tools/goatcounter.sh's count queries fail

Answering the agent's report that `tools/goatcounter.sh --check` worked with the `.env` token, but
the count queries (`--raw`, and the default per-day funnel, over 30 and 60 days) failed with
"network error reaching GoatCounter: Remote end closed connection without response", so the tear
and pursuit counts could not be read.

> looks like you need to fix goatcounter.

## #598 — Telegraphing is for a heavy penalty, not only lethal

Asked, about PR #597 (M226, one-second off-screen warnings), which things get a warning at all. On
2026-09-26 ([PLAYTEST-145](PLAYTEST-145.md), statements 21 to 24) telegraphing was for things that
go fast, are dangerous and come toward her, "dangerous means it can end the day" (`hard_fail`), so
the fire truck and the day-13 column would stop being warned and the loose dog and the cat get no
badge; on 2026-10-04 "for all offscreen warnings ... 1s", with the fire engine, the column and the
loose dog listed. The agent proposed the earlier rule (only dangerous things warned; the fire truck
kept, since jolly-hare makes it lethal while driving).

> the telegraphing rule was about heavy penalty not *only* lethal

> fire truck has heavy penalty

The player's further words on PR #597's measurements of the day-3 dog (its warning, its time in
view and its chase, walking toward, standing and walking away), in the order they were said. The
sentence beginning "Before, the dog was created off screen" quotes the agent's own report, which the
player answers in the words after it.

> let's be clear about terminology. the chase is what happens on screen -- if the dog was placed off screen and it took a moment to come on screen that is not counted as chase. can you give the corrected numbers/
>
> 1) why does the warning change? you have full control over that 2) why does walking away increase? we didn't change anything regaring the pursuit
>
> Before, the dog was created off screen and spent its 4.5s approach closing on her from out of view while she walked away, coming into view only at 2.63s.  -- we just established that off screen doesn't count toward the timing it only counts towards the warning timing

> why is the warning now 1s? why did the build show 6.55s when walking away? your numbers don't make sense
>
> you reported 0.47s to 0.78s for the warning so 1s is non-sensically out of that range. your "Caught" numbers don't make sense either and what do you mean by "pursuit starts"? speak clearly
>
> it's still not clear whether the numbers are from before or now
>
> no. why?
>
> I know why walking away changed -- I don't understand why you want to place the dog somewhere else? instead of just doing the new approach with the latest numbers

> 0.53 is a good warning time -- the chase on screen didn't change at all. so what's the problem?

> just to be clear objects don't spawn "at the edge of the screen" they spawn *offscreen*

> I don't want any pop in

> off screen is not the same as visible -- the corners get removed for visible not for off screen

> why would the robber walk towards her when it spawns as pursuing robber? the proximity rule is only for standing robbers.

> pursuers should never (or a long time)  stop pursuing if she walks -- that will make it impossible to walk away.

> you can decide on the warnings for now. put the question into a review point for later when the table is ready.

## #599 — Day 11: any live mast answers the task

Asked, about PR #588 (plush-moose, every task has a red arrow to the closest by walking distance),
on day 11 ("the red arrow keeps jumping to the closest ones on the other route", inbox #561):
**(1)** only the two masts the day sets up (the one near the mark and the one rigged onto her route)
answer the task, touching either completes it; or **(2)** any live mast in the city answers the
task, the arrow pointing at the closest by walking distance.

> I go with 2 for the masts. why limit artificially to two arbitrary masts.

## Routing

**#579** → PR #580 (the trailer reimagined around saved scenes), which is building it: the cut with
captions over the footage, the new plain walk and the park close-up, the mirrored birds scene, no
length cap, a missing font stopping the render, cars vanishing inside the tunnel, the render the
same every time by construction. "I will decide after the merge" between the two birds scenes is
the player's to make on PR #580. No new queue entry.

**#586** → the real catch test is built and merged in PR #589, recorded in
[spry-llama-2](../decisions/2026-10-04-spry-llama-2.md) (influenced counts the game's real catch and
hold). The rigged bags of 2 or 3 rewrite olive-badger's item
[the-other-forced-cases.md](../todo/2026-09-27-olive-badger/the-other-forced-cases.md).

**#587** → PR #580, which is building it: the city camera has no limits and keeps her centered with its
look-ahead, and the dropped test stays dropped. No new queue entry.

**#591** → tearing every sheet she slides past (option 1) is built and merged in PR #593, recorded
in [grassy-newt](../decisions/2026-10-05-grassy-newt.md) (a held push tears every sheet she slides
past), and `docs/MECHANICS.md` keeps the accidental tear as how tearing is found. The policeman's
drawing is merged in PR #594, recorded in [tiny-beaver](../decisions/2026-10-05-tiny-beaver.md) (a
policeman on foot, drawn for the pursuits to come); "policeman looks good" closes its review item,
silky-plover (judge the policeman on foot), which this filing deletes. The instant pursuit on foot
is a new entry, [sandy-ferret](../todo/2026-10-05-sandy-ferret/README.md) (a torn poster's pursuit
is instant, on foot). "queue those items as immediately now after the release" files jolly-hare
(the fire truck lethal driving and solid parked), pebbly-ibis (the pelican from one shared bag per
run), olive-badger's forced cases and sandy-ferret in band `now`.

**#595** → built and merged in PR #596, recorded in
[pebbly-pelican](../decisions/2026-10-05-pebbly-pelican.md) (tools/goatcounter.sh pages with one
comma-joined exclude list). No new queue entry.

**#598** → PR #597 (M226 and dappled-swan, every off-screen warning one second, what she can see
leaving out the touch-control corners), whose build these words direct: the telegraphing rule
(a heavy penalty, not only lethal), the day-3 dog's timing (the chase counted on screen only), no
pop-in, off screen as distinct from visible, a pursuing robber not walking up to her, pursuers that
a walk does not escape, and the warnings decided for now with the question put to a review item once
the cost table is ready. "fire truck has heavy penalty" also goes into jolly-hare: the fire truck keeps its
one-second warning. "pursuers should never (or a long time) stop pursuing if she walks" also goes
into sandy-ferret for the poster's pursuer. No new queue entry.

**#599** → PR #588 (plush-moose, every task has a red arrow to the closest by walking distance),
which is building option 2: any live mast answers day 11's task. No new queue entry.
