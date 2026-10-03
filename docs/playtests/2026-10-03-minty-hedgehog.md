# Playtest minty-hedgehog — The first inbox batch

2026-10-03. The first batch of the player's inbox, every open note labelled `inbox`, filed in one pull request at the player's word, together with the answers the player gave in conversation to the questions asked about them.

The assistant asked whether to file every note in one batch pull request, #423 included, rather than #423 first on its own. The player answered:

> file everything in one PR

## #423 — shadows are misplaced

> currently shadows are oval below objects. for most objects the oval spans the entire visual bounding box. this does not read as shadow. for example, the shadow of a car goes all the way above the roof of the car. it should only be where the wheels would reasonably be. either we keep the oval for shadows and adjust their number and extent to what makes them look reasonable or we draw a custom shadow for each object that resembles what we would expect a shadow of that object to look like

1. **Note #423, "shadows are misplaced", as written above.** → silver-egret.

## #431 — using-tools: gh api reads a file only with -F body=@file

The note was opened as a captured note by `nappy-claude-orchestrator[bot]` before the capture script existed. Its body is the orchestrating session's write-up, not the player's words; the player's words in it are only the request it quotes, "add it as issue".

> The player, on 2026-09-28, asked for this to be recorded as an issue: "add it as issue".
>
> **A skill fix for using-tools: `gh api` reads a file only with `-F`.** `gh api ... -F body=@file` sends the file's contents; `-f body=@file` (`--raw-field`) sends the literal text `@file`. On 2026-09-27 two agents posting to a pull request used `-f body=@file`, each posted the literal `@file` as the comment or review body, and had to correct it with a follow-up edit. The using-tools skill (and the pr-review skill's reviewer instructions, which tell a reviewer how to post) should say which flag to use, since writing a body to a file and passing the file is also how the write guard wants long text passed.
>
> Written by the orchestrating Claude Code session at the player's request; the player's own words are only the request above.
>

The assistant explained that the note's body is the session's own write-up, the player's words in it only "add it as issue", so the script would show it as the player's words, and offered to file it with the body marked as the agent's or to capture it again. The player answered:

> file it as is

The note has no band label. The assistant asked which band it gets, proposing `later`. The player
answered:

> later sure

2. **Note #431, "using-tools: gh api reads a file only with -F body=@file", as written above.** → azure-panda.

## #432 — the van task is unreachable now

> the arrow correctly points to the van but touching the van doesn't solve the task. also, the van should spawn close to the mark not across the city. lastly, the robber should be 2/3rds through the alley not pressed against the edge of it

The player commented on the note:

> this applies to almost all tasks

The assistant asked whether "this applies to almost all tasks" means where every task's target is drawn (anywhere in the city), and proposed that the targets whose place is fixed (the swing park, the power station, a district door, the neighbor's timed walk) keep their place. The player answered:

> yes your read matches

The assistant asked whether the robber two-thirds into the alley keeps M213's floor of at least 176px from the mark, so a touch and a walk back never wakes him. The player answered:

> yes touching the mark shouldn't wake him from the correct side and if the alley is long enough -- the main reason for this is so the robber is not at the edge of the alley which makes him easier visible and easier to avoid

3. **Note #432, "the van task is unreachable now", as written above.** → feathery-marmot.

## #433 — walking behind a car can end the day

> cars should only be lethal in front of them while they're driving. if they're standing still they are good. except for noise

The assistant asked whether "lethal in front" means the front half of the body or a zone ahead of the nose, whether a moving car's side still kills, and whether event vehicles count. The player answered:

> when I walk behind a standing car right now and it starts moving I die -- that is not correct the car is driving away from me

4. **Note #433, "walking behind a car can end the day", as written above.** → grassy-alpaca.

## #434 — dedicated run button

> for joystick mode a dedicated run button (one on each side next to the joystick) would make running much more precise and easier. the button should not trigger when moving the finger over it from navigation and holding the button and navigating should work correctly. also the double tap should still work since mouse only navigation would otherwise break.

5. **Note #434, "dedicated run button", as written above.** → polite-swan.

## #435 — investigate saving on safari

> it seems like navigating to a different tab on safari unloads the page. this is not great since it basically costs a live to interrupt a game. on chrome this works correctly (the page stays loaded). if this is really not solvable in safari, then we probably should look into saving the full state of the game on every blur (and in regular intervals) and allowing to reload from the last location without penalty

The assistant asked whether to file the investigation now and bring back PLAYTEST-82's parked exact snapshot only if Safari cannot be fixed. The player answered:

> yes

6. **Note #435, "investigate saving on safari", as written above.** → tawny-puffin.

## #436 — Language

> We should us "gatehouse" instead of "hut". The "van...before it's light" doesn't read right

The assistant asked whether "gatehouse" changes only the text and docs and keeps the `checkpoint_hut` identifier. The player answered:

> keep identifiers but change texts

The assistant asked which van line reads wrong, day 8's brief "A van took someone from the next
street before it was light." or day 7's mark "A van is waiting on the sidewalk. Don't come home
light.", and whether the player had wording for it. The player answered:

> the former but the latter needs improvement, too, light is ambiguous

7. **Note #436, "Language", as written above.** → cozy-gecko.

## #437 — Easter egg

> One in ~400 bikers should be a pelican riding a bicycle instead. Needs to be svg only

The assistant asked whether "svg only" means never converted to PNG, drawn as SVG rather than generated, or both. The player answered:

> converted to PNG during atlas creation but otherwise it will always stay SVG never become a converted PNG

8. **Note #437, "Easter egg", as written above.** → feathery-bison.

## #442 — south facing stroller shows handle

> the handle is shown in the south facing stroller when it should be hidden. solution is probably to just remove the black bar in the scaled up version before scaling down

9. **Note #442, "south facing stroller shows handle", as written above.** → misty-trout.

## #446 — split ground visuals creation into multiple frames

> The compositing process of creating ground visuals can be smeared across multiple frames. That would improve stuttering 

This note was already filed and built: PR #452 (silky-rabbit, nearby ground regions prepare across frames) carries `Filed from #446`, its words are in speckled-marten, and `docs/decisions/2026-10-02-silky-rabbit.md` records it. It is copied here so it closes with this batch, and files no entry.

10. **Note #446, "split ground visuals creation into multiple frames", as written above.** → no entry.

## #447 — statues and fountains in parks

> the parks with concrete flooring need some variety. maybe statues or fountains in the center

The assistant asked which ground the note means: quiet squares, market squares or parks. The player answered:

> the calm areas with concrete flooring -- I don't know how you call them

The assistant asked whether a statue or fountain blocks her, so routes go round it, or is
decoration she walks over. The player answered:

> fountain and statue should block at their footing

11. **Note #447, "statues and fountains in parks", as written above.** → speckled-lemur.

## #449 — neightbor goes to work

> the neighbor should actually follow a route that goes to work and disappear at its entrance. he should not unload so you might cross paths with him at any point of the route. two open questions: should there always be a path that goes to the power plant so the neighbor can follow it without disruption? what happens on the day where he goes home?

12. **Note #449, "neightbor goes to work", as written above.** → breezy-hawk.

## #450 — more events

> ideas for more events: squirrels in the park (that run away when arriving), group of school children running on the street, a robber being chased by the police (not lethal; should only happen in the first act; probably later in the act; is used to establish law enforcement as helpers which is then overturned in the next act), red construction crane blocking the whole street, food cart, sewer/cable/electricity repair van with orange cones and manhole

13. **Note #450, "more events", as written above.** → cozy-raven.

## #451 — waterfront update

> currently, the water front just goes directly into a short wall and then water. it should be improved, also either have a guard rail or ship bollards. and maybe laterns

14. **Note #451, "waterfront update", as written above.** → jolly-panda.

## #459 — Write guard's approval prompt names the kind of write but not the command

> ## Problem
>
> When asking is switched on (`NAPPY_ASK_FOR_PLAYER_WRITES=1`, in a cloud session or on a machine without agent identities), `.claude/hooks/github-write-guard.sh` asks the player before an agent runs a write such as `git push`, `git commit` or `gh pr comment` under the player's own account. The question it shows is built near the end of the script (the `decision="ask"` branch, around line 1213 on `main`):
>
> > This command (`$flagged`) would go out under the player's own GitHub account: … Approve it only if you want this one command run as you; the next one is asked about again.
>
> `$flagged` holds only the **kind** of write the guard found (for example `git push`), not the command. So the player is asked to approve "this command (git push)" without seeing which push, to which remote or ref, or whether the command pushes anything at all.
>
> The comment above that branch assumes the opposite: "on the mobile app it shows only the command, not this reason". In practice the player saw the reason without the command.
>
> ## How it showed
>
> 2026-10-03, while a review agent tested PR #453 (deny unreadable pushes supplied through xargs and GNU parallel), it put test text containing `git push` on its own command line. The live guard asked the player, who could not tell what they were approving: "it was some command -- the hook doesn't tell me what the command itself is". It turned out to be test input, not a real push.
>
> ## Fix
>
> - Include the command itself in `permissionDecisionReason`, cut to a readable length (about the first 200 characters, with an ellipsis when cut), alongside the kind of write.
> - Correct the comment's claim about what the mobile app shows.
> - Add a test in `tools/test_rules_hooks.sh` that an asked-about command appears in the reason.
> - Per CLAUDE.md's Codex integration rule, check `tools/codex-hooks.py` and its tests. Codex turns an ask into a deny, so probably no change is needed, but the check is part of the change.
>
> PR #453 does not touch this part of the script: everything from `askable_reasons=` to the end of the file is identical at its base and head.

The note was opened from the player's account. Whether its Problem, How it showed and Fix sections are the player's own or an agent's draft the player posted is asked; the player's words it quotes are "it was some command -- the hook doesn't tell me what the command itself is".

The assistant asked whether the note's body, with its Problem, How it showed and Fix sections, was
the player's own or an agent's draft the player posted. The player answered:

> the hook approval that we created doesn't properly tell me what the command is that you're trying to execute. it shows me the hook's code instead

15. **Note #459, "Write guard's approval prompt names the kind of write but not the command", as written above.** → rosy-marmot.

## How an ingestion treats open questions

Said in conversation, after the assistant had held this batch for the wording of day 7's line:

> "If there is an open question in an issue stays open until the task gets picked up. Most of the time there needs to be some exploration etc done. The whole point of the issue ingestion is to get things in to the codebase fast. The questions come later after the ingestion is merged"

**An ingestion files every note as it stands and merges fast; a question a note leaves open is
written into its queue entry and stays open there until the task is picked up.** → the inbox skill.
