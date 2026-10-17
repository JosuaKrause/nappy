# Playtest woolly-finch — The player's words first recorded in CLAUDE.md and the skills

2026-10-17.
These are the player's words as `CLAUDE.md` and the skills recorded them, each with the date it
carried there, moved here on 2026-10-17 so that the skills can cite them instead of quoting them
(woolly-penguin #759). No playtest or record held them. The line under each quote is what it was
about, taken from the skill's own context; only the quoted lines are the player's.

## 2026-09-05, a windowed run stalls when it loses focus

> if you run in a windowed mode and the window loses focus the test gets stalled since the window will never close. when I'm doing something else the window will lose focus 100%

About windowed test runs: verify's reason for keeping runs headless, since a window that loses focus
could stall a test.

## 2026-09-05, a messy commit inside a branch is fine

> unclean commits are fine inside a branch since main is protected

About commits on a branch: committing's rule that a messy commit inside a branch is fine, since main
is protected.

## 2026-09-06, pictures are assets, so they are judged without running code

> that way you can evaluate the assets independently of running code

About drawing pictures in code: the cues skill's reason that an image file can be judged on its own,
without booting the game.

## 2026-09-08, making a note means the repository

> 'making a note' means writing it somewhere in the repo (eg claude.md) *not* storing it as memory

About "make a note of that": CLAUDE.md's rule that a note is written in the repository and
committed, never kept in an assistant's memory.

## 2026-09-08, a cold agent is not resumed

> resuming after an hour will be a huge token hit because the cache expires. at that point it's better to just start a new one.

About resuming a finished agent: orchestrating's rule that one is not resumed once its prompt cache
has expired.

## 2026-09-08, the cache windows

> claude cache is 1h

> caching for codex is 20min only

About how long a prompt cache lasts: one hour in Claude Code and twenty minutes in Codex, in
orchestrating's rule on resuming agents.

## 2026-09-08, five minutes to spare

> I would give like a 5min safety buffer

About resuming an agent near the end of its cache window: orchestrating's rule to resume only with
five minutes to spare.

## 2026-09-08, the main checkout is the player's test bed

> always check out what you want me to test.

About what the player is asked to try out: orchestrating's rule that it is checked out in the
repository's own folder, never left in an agent's worktree.

## 2026-09-09, a queue entry is named with a short title

> whenever you're talking about milestones and todos give a short title in addition to the number.

About naming milestones and queue entries in conversation: CLAUDE.md's rule that one is named by its
words or number and a short title.

## 2026-09-09, a question carries all its context

> also provide all necessary context when asking a question.

About asking the player a question: CLAUDE.md's rule that a question carries everything needed to
answer it, in the message that asks it.

## 2026-09-09, review findings are comments on the PR

> reviewing a PR should result in comments in the PR so they can be picked up and resolved

About where a review's findings go: pr-review's rule that they are posted as comments on the pull
request, anchored to their lines.

## 2026-09-09, branch work always has a pull request

> always create prs don't leave branches locally only

> or have branches on the remote without pr without good reason

About ending a session: committing's rule that branch work is pushed and has its pull request.

## 2026-09-09, the docs a change owes are in the PR before it merges

> why do you keep updating handoffs and todos *after* a PR has landed? the updates *must* go in the PR … that's a hard requirement

> the requirement is not for docs to be updated before the PR opens. it's for the docs to be updated *before* it **merges**

About doc and queue updates: committing's rule that every doc a change owes is on its branch before
it merges.

## 2026-09-09, a work item never merges while its queue item is unresolved

> a workitem may never merge if it's corresponding TODO item hasn't been resolved

About merging: committing's rule that a work item does not merge while its queue item is unresolved.

## 2026-09-11, Haiku for a wait

> for wait tasks like this haiku makes more sense -- use your judgement

About which model an agent runs on: orchestrating's rule that a wait (polling a check, removing a
worktree, pulling main) goes to Haiku, by judgement.

## 2026-09-11, burst captures are an option

> add somewhere that taking burst captures is an option when recording evidence / creating screenshots

About recording evidence: verify's note that a burst capture can be taken instead of a still.

## 2026-09-11, invincibility exists for captures

> make future agents aware that invincibility exists to capture things where timing to avoid a death screen would be difficult to do

About the --invincible dev flag: verify's note that it keeps the day running so a capture can wait
for its moment.

## 2026-09-11, work only a person can judge gets a review item

> keep a document with items that need human review / test runs. That way you can keep working without having to stop. And test runs can capture multiple items at once.

About work only a person can judge: committing's rule that it adds a review item under docs/review/
in the same pull request.

## 2026-09-14, no engine warning is left standing

> we don't want warnings -- we want to do things properly

About warnings the engine prints: the godot skill's rule that each is fixed at its cause rather than
read around.

## 2026-09-14, a broken PR is fixed on its own branch

> we're not merging broken things -- fixes go in the same PR *always*

> a PR is a *completed* workitem

> we don't merge PRs that are broken, we fix PRs, not by creating new PRs

About a pull request that built the wrong thing or built it wrong: committing's rule that it is
fixed on its own branch, never by a second PR.

## 2026-09-14, the unit is the work item

> why do you keep creating new PRs for things that should go in the same PR?

About splitting work across pull requests: committing's rule that the unit is the work item, not the
queue entry.

## 2026-09-20, a dead agent past its cache window is replaced

> don't let them continue because their cache is expired

About an agent killed mid-task: orchestrating's rule that past the cache window a fresh agent is
started in the dead agent's worktree.

## 2026-09-22, a manual sequence becomes a script

> if you find yourself doing similar things over and over again that require a lot of manual work maybe that's a time to move them to shell scripts and note them down somewhere. is there a skill about how to use the scripts in the tools folder?

About shell work done by hand over and over: CLAUDE.md's rule that a manual sequence done a second
time becomes a script, with its row in the using-tools catalogue.

## 2026-09-22, a skill found wrong is fixed and flagged

> if you ever notice that a skill doesn't work correctly or contains incorrect information or otherwise could be improved fix that and flag the fix to me since I want to understand how skills can be improved.

About a skill that turns out wrong: CLAUDE.md's rule that it is fixed, and the fix flagged to the
player.

## 2026-09-22, a usage limit is over once it is heard of

> by the time _you_ hear of it the quota or usage is fully restored so there is no need to change behavior due to it (ie no reducing agent usage or things like that). quota limits happen from time to time.

About usage and quota limits: orchestrating's rule that a limit message is no reason to use fewer
agents or cheaper models.

## 2026-09-22, a long pause and a brief one

> long pauses let the cache expire which means we probably shouldn't let existing agents continue and start a new agent with a precise updated prompt instead. if the pause was brief nudging the existing agents is enough since the cache is still warm and they can just continue. usually, I'll tell you which kind of interruption it was.

About recovering from a limit or an outage: orchestrating's rule that the pause's length decides
whether agents are nudged or replaced.

## 2026-09-23, the Opus guidance is Claude Code's only

> make the opus guidance claude only -- codex has a different model hierarchy here

About the rule that drawing is Opus's: orchestrating keeps it to Claude Code, since Codex has its
own model hierarchy and tiering for art.

## 2026-09-23, pictures in a PR description are embedded

> the images don't show up inline

> while they do show up inline for the other prs

About images in a pull request's description: committing's rule that a picture is embedded with
image syntax, never left as a bare URL.

## 2026-09-23, a PR with several visual passes opens with the current one

> it's not clear what the current proposal is

About pull requests that went through several visual passes: committing's rule that the description
opens with the current proposal.

## 2026-09-25, a short clip may be committed for a PR

> short clips like that are fine if they're needed to convey something in a PR

About video in the repository: session-captures' rule that a short clip is committed only when a
pull request needs it to show motion.

## 2026-09-26, the restart prompt goes into a local file

> make a note to not write the local handoff in the chat since CLI c&p is broken write it to a local file and don't check it in

About the restart prompt at a session's end: session-cleanup's rule that it goes into a local,
git-ignored file and never into the chat, since copying long text out of the CLI corrupts it.

## 2026-09-26, only whoever opened a thread resolves it

> also add a note that only whoever raised a concern can resolve it, too.

About review threads: pr-review's rule that a thread is resolved only by whoever opened it.

## 2026-09-26, resolving threads is not enforced

> but dont enforce that resolving all comments is required for approval. resolving is more of a gentlement's agreement

About review threads: pr-review's rule that resolving them is a convention, not a gate on approval
or merge.

## 2026-09-27, a code comment may quote the player

> sure

Asked whether the godot skill should let a code comment quote the player's own words with where they
were said, since the code already carries many.

## 2026-09-27, a queue update goes first, with a lighter review

> Task list updates should have priority and could use a weaker review agent (or no review at all if you think that is safe)

> Write it down how it makes sense. You might see some gaps that I missed

About pull requests that only change the queue: pr-review's rule that they are reviewed for
faithfulness and merged ahead of other work.