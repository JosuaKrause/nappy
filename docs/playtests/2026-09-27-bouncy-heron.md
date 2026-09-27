# Playtest bouncy-heron — The queue stays in the repository, Issues become the inbox, and CI takes the mechanical checks

2026-09-27. Said in conversation, a discussion of whether the queue and the feedback should move
from the repository to GitHub Issues. The player's words are quoted in full; what the assistant
proposed and the player accepted is stated after each quote, since the player's closing answer
accepts every proposal they did not change (statement 12).

## The question

> "currently we keep track of all tasks and decisions inside the repository but that adds PR
> overhead from just managing tasks and feedback. the alternative would be to make use of github
> issues. what are the pros and cons of each? let's discuss"

The assistant laid out both sides: the repository keeps the queue and the code in one commit, is
read offline by every agent, loads its rules through the path hooks and is linted; Issues file and
close without a PR, notify, and can be written from a phone, but lose the review a queue update
gets, the rule hooks and the diff history. It asked which pain was largest: (a) waiting on and
approving queue PRs, (b) not being able to file or triage from outside a session, (c) agents
briefed from a stale queue.

> "one pro is also that items get reviewed when they enter the queue which in theory can reduce
> miscommunication or misinterpreted statements which was a big problem before. spending time
> upfront to avoid having to clean up later is worth it for me. another con of issues is that
> things can be edited without history"

1. **The queue stays in the repository, because an entry is reviewed when it enters it.** Time
   spent at filing to catch a misread statement is worth more than the cleanup it saves. →
   leafy-finch.

> "how would the automated narrow review work?"

> "(b) is an issue since I have to hope that the agent gets to write a comment down before a
> session is cleared. (a) is just overhead that slows things down which is not great (c) I don't
> think I have had that happen yet"

2. **The player's words are at risk until they are written somewhere safe**, and today that means
   a branch and a PR the agent may not reach before the session is cleared. → leafy-finch.
3. **The overhead of a queue PR slows the work down.** → leafy-finch.

## The options

> "by faithfulness I meant having another agent review that the wording I used (in the playtest
> file) and the actual scheduled work (in the todo) matches. is that not happening? how can I move
> the mechanical checks into CI? PR title matcher? how can I make it run only on those PRs? for
> the todo decision etc check I would also add that PRs that implement something must remove some
> todo entry? we can skip the godot suite for doc only prs based on edited files. I think that
> alone would make the process faster. a review from a bot is fast already but then everything
> needs to wait 10min for CI to pass. I like the issues as inbox idea so I can just record thoughts
> there and tell the agent about it and the agent batches them and adds them into the queue. in
> that system edits are actually good because they don't cause multiple lines of just correcting
> previous wording like when I'm formulating a task today. so let's recap and list out the options
> first"

The assistant answered that the narrow review of a queue update does not check faithfulness
today: the pr-review skill leaves it to the filer, and it is checked only when the PR that builds
the entry is reviewed. It proposed classifying a PR by the files it changes, never by its title,
and listed the options this file's statements settle.

4. **Faithfulness means another agent checks that the player's wording in the playtest file and
   the work scheduled in the queue match.** → leafy-finch.
5. **Issues are the inbox, not the queue.** The player records thoughts there and tells the agent;
   the agent batches them into the queue. An inbox note is edited in place until it is right,
   which is better than several lines each correcting the last. → leafy-finch.

## The list

> "okay so
>
> 1. we need a skill for reading the inbox and filing it (maybe with the help of a script)
>
> 2. skip the suite for doc only PRs (via which files were edited with your categories) – we need
> to keep some tests for doc only PRs -- only the heavy game checking tests should be skipped
> 3. let's add language for a faithfulness check in the doc PR review (I think haiku should be
> enough to identify issues and as reviewer it doesn't need to resolve them?)
> 4. add tests for doc things that can be checked automatically and make the haiku review focus on
> more important stuff
> 5. code PRs must update todos are allowed to update decisions
> 6. no PR is allowed to have a handoff file (although it is okay to push handoff files during the
> process of creating the PR -- it just needs to be cleaned up afterwards)
> 7. we can go from haiku to sonnet, sure
> 8. I like the CI for issue transcription
> 9. okay, we can do via capture and then it also shows up as issue -- great -- no need for a hook
> I don't want my entire conversation recorded. an agent has better judgement there. the
> important thing is that it ends up in a safe queue in issues and I can choose when we want to
> turn those into a doc update PR (so I can even go in and edit the issues after the fact before
> the get merged)
> 10. we need to rethink the GitHub write guard -- if it goes through a script it's safe we just
> need to get it working once -- an agent shouldn't use gh issue directly
>
> let's record this as a new work item via the old workflow and once that PR merges you can start
> implementing"

> "everything that you suggested that I didn't explicitly change is accepted"

Asked which model runs the faithfulness check, since point 3 leans on Haiku and point 7 accepts
Sonnet, the player chose **"Sonnet now"**. Asked whether the standing rule that a finished item
needs both its file deleted and its decision record written stays, with CI checking only the
queue, the player answered:

> "okay if the standing rule is both then let's do that. what I want is a CI check that does what
> the reviewer currently does automatically. we should get as close as possible to that. the
> reviewer still needs to verify the correctness of those changes anyway. the CI is only a help"

> "you can push and create PRs"

6. **A skill, helped by a script, reads the inbox and files it.** The agent copies each note's
   current text into a playtest file and files the queue entries in one PR; the player chooses
   when a batch becomes that PR, and may edit an issue until the PR merges. → leafy-finch.
7. **A PR whose changed files are all docs skips the heavy Godot checks, and only those.** The
   light checks still run. The categories are the assistant's: queue-only (every file under
   `docs/todo/`, `docs/review/` or `docs/playtests/`), docs-only (every file Markdown or under
   `docs/`, except `docs/TELEMETRY.md`, `docs/COSTS.md` and `docs/ARCHITECTURE.md`, which the Godot
   checks read), and touches-code (anything under `src/` or `tests/`). → leafy-finch.
8. **The review of a queue update checks faithfulness, and it is Sonnet's.** A reviewer flags;
   it does not resolve. → leafy-finch.
9. **CI checks what can be checked automatically, as close as possible to everything the
   reviewer checks today**, so the review spends its time on what matters. The reviewer still
   verifies the correctness of what CI checked; CI is a help. → leafy-finch.
10. **A PR that changes code must also change the queue and the decision records**, since the
    standing rule is that a finished item's file is deleted and its record written, both. The
    assistant's escape for a PR with no queue item, a `No queue item: <reason>` line the reviewer
    judges, is accepted. → leafy-finch.
11. **No PR merges with a handoff file in it.** One may be pushed while the PR is being made; it
    is removed before the PR is done. → leafy-finch.
12. **CI checks that an inbox issue is transcribed word for word into the playtest file.** →
    leafy-finch.
13. **An agent captures the player's words into the inbox with a script, by its own judgment.**
    There is no hook recording every message: "I don't want my entire conversation recorded. an
    agent has better judgement there." → leafy-finch.
14. **The GitHub write guard lets an issue write through a script, under the agent's own
    identity, and still denies an agent's direct `gh issue`.** → leafy-finch.
15. **The work is filed as a queue entry by today's workflow, and built once that PR merges.** →
    leafy-finch.
