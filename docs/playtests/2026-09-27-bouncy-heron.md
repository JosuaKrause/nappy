# Playtest bouncy-heron — The queue stays in the repository, Issues become the inbox, and CI takes the mechanical checks

2026-09-27. Said in conversation, a discussion of whether the queue and the feedback should move
from the repository to GitHub Issues. The player's words are quoted in full. Before each quote
stands what the assistant had just said, as far as the quote answers it: every label the player
uses — (a), (b), (c), "your categories", "capture", "the CI for issue transcription" — is defined
there, since the quote alone does not say what it points at. The player's answer after the list
accepts every proposal of the assistant's they did not change, so those proposals are written out
in full here.

## The question

> "currently we keep track of all tasks and decisions inside the repository but that adds PR
> overhead from just managing tasks and feedback. the alternative would be to make use of github
> issues. what are the pros and cons of each? let's discuss"

The assistant measured the overhead (11 of the last 50 commits on `main` touched only the queue,
the review items or the playtests, and each went through a branch, a PR, a Haiku review and the
player's go-ahead) and laid out both sides. **For the repository:** the queue and the code change
in one commit, so a PR that finishes an item deletes it and writes its record together; every
agent reads the queue offline; editing `docs/todo/` or `docs/review/` loads the
**playtest-feedback** rules by hook; `tools/lint.sh` enforces the bands and `after:` lines; the
narrow review catches an open item deleted with no record; one grep searches the queue and the
records together. **For Issues:** filing, re-banding and closing need no PR; labels and GitHub's
own "blocked by" links could replace the bands and `after:` lines; a review item assigned to the
player notifies them and can be answered from a phone; "Closes #N" closes an issue when its PR
merges. **Against Issues:** closing one is a click nobody reviews, no hook loads a rule on an
issue edit, every agent needs GitHub access through its bot identity, the search splits in two,
and moving 38 entries and about 118 review items means rewriting the queue tools, the lint and
about six skills. It proposed three ways forward — stay in the repository and let CI merge a
queue-only PR on green; move everything to Issues; or move only the review items to Issues — and
recommended the first. It asked which pain was largest:

- **(a)** waiting on and approving queue PRs;
- **(b)** not being able to file or triage from outside a session;
- **(c)** agents briefed from a stale queue, since every brief is written from `origin/main` and a
  filing not yet merged is missing from it.

> "one pro is also that items get reviewed when they enter the queue which in theory can reduce
> miscommunication or misinterpreted statements which was a big problem before. spending time
> upfront to avoid having to clean up later is worth it for me. another con of issues is that
> things can be edited without history"

1. **The queue stays in the repository, because an entry is reviewed when it enters it.** Time
   spent at filing to catch a misread statement is worth more than the cleanup it saves. →
   leafy-finch.

The assistant agreed and dropped the move to Issues. It noted that GitHub does keep an issue's
past versions, but nobody reviews an edit before it lands and a past version can be deleted. It
then pointed out that the review a queue update gets today does not check what the player cares
about: the pr-review skill's narrow review checks only the paths, that no playtest file was
rewritten, that no open item was deleted without a record or an agreed drop, and the lint, and
says outright that "whether a filing states the player's ask faithfully is the filer's job". It
proposed moving those mechanical checks into CI and spending the review on faithfulness instead,
and asked whether that review should be Sonnet's or stay Haiku's.

> "how would the automated narrow review work?"

The assistant described it: a CI step lists the PR's changed files; if every one is under
`docs/todo/`, `docs/review/` or `docs/playtests/`, the PR is a queue update and the checks run —
playtest files only added, a deleted item accounted for by a record on `main` or a `Dropped:` line
in the description quoting the player, a deleted review item named by a playtest file, the lint
passing — and a queue-only PR skips the Godot checks and the eight suite shards, which run today
on every PR. It asked two things: whether a `Dropped:` quote must appear verbatim in a playtest
file (its pick), and whether to skip the suite on queue-only PRs (its pick: yes).

> "(b) is an issue since I have to hope that the agent gets to write a comment down before a
> session is cleared. (a) is just overhead that slows things down which is not great (c) I don't
> think I have had that happen yet"

This answers the question of the first reply: (b) is not being able to file or triage from
outside a session, (a) is waiting on and approving queue PRs, (c) is agents briefed from a stale
queue.

2. **The player's words are at risk until an agent writes them down**, and a session can be
   cleared before it does. → leafy-finch.
3. **The overhead of a queue PR slows the work down.** → leafy-finch.

The assistant proposed **Issues as an inbox, not as the queue**: the player writes a note as an
issue at any time; in a session, an agent's first act on feedback is to open such an issue with
the player's words, in one call; filing then works as today — the note copied into a playtest
file, the queue entries filed, and the PR saying "Closes #N". It proposed a CI check that a
playtest file in a PR carrying "Closes #N" contains that issue's body word for word, a hook that
reminds the agent on every message to capture feedback first, a script `tools/capture.sh` for
the capture, and a decision record saying Issues were weighed as the queue and adopted as the
inbox only.

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

4. **Faithfulness means another agent checks that the player's wording in the playtest file and
   the work scheduled in the queue match.** → leafy-finch.
5. **Issues are the inbox, not the queue.** The player records thoughts there and tells the agent;
   the agent batches them into the queue. An inbox note is edited in place until it is right,
   which is better than several lines each correcting the last. → leafy-finch.

The assistant answered that faithfulness is not checked when a filing is its own PR, only later
when the PR that builds the entry is reviewed. It answered that CI tells PRs apart **by the files
they change, never by the title**, which the agent writes: a first job sets three flags —
**queue-only** (every file under `docs/todo/`, `docs/review/` or `docs/playtests/`),
**docs-only** (every file Markdown or under `docs/`, except `docs/TELEMETRY.md`, `docs/COSTS.md`
and `docs/ARCHITECTURE.md`, which the Godot checks read) and **touches-code** (anything under
`src/` or `tests/`) — and the workflow always runs, because a path filter on the workflow would
leave the required `test` check waiting forever. These three flags are "your categories" below.
It then listed the options:

- **A.** Skip the Godot suite on docs-only PRs.
- **B.** CI runs the narrow review's mechanical checks on queue-only PRs.
- **C.** A PR touching code must also delete or rewrite a `docs/todo/` file and add or change a
  `docs/decisions/` record, with a `No queue item: <reason>` escape line the reviewer judges.
- **D.** A faithfulness review on every filing PR; Sonnet or Haiku.
- **E.** Issues as the inbox — an `inbox` label and an issue template; the agent copies a note's
  current text and the player's comments into a playtest file and closes the issues with the
  filing PR; after filing, a later thought is a new note; optionally, the CI check that the
  playtest file holds the issue's text word for word ("the CI for issue transcription").
- **F.** In-session capture — `tools/capture.sh` opens an inbox issue with the player's words in
  one call, and a hook on every message the player sends reminds the agent to capture first.
- **G.** Fix the GitHub write guard, which denied a `grep` because its search pattern contained
  the issue command's words.

It suggested building A alone first, then B, C and D together, then E, F and G.

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

The assistant asked two questions. **First:** point 3 says Haiku should be enough and point 7
says "we can go from haiku to sonnet, sure" — which model runs the faithfulness check? The options
were "Haiku now, Sonnet if Haiku misses misreadings" and "Sonnet now"; the player chose **"Sonnet
now"**. **Second:** point 5 read as CI requiring a `docs/todo/` change on a code PR and allowing,
not requiring, a `docs/decisions/` change, while the committing skill's standing rule (2026-09-09)
counts an item resolved only when its file is gone *and* its record is written — should that rule
stay, with the reviewer enforcing the record? The options were "keep the rule, CI checks the queue
only", "CI requires both" and "records become optional". The player answered:

> "okay if the standing rule is both then let's do that. what I want is a CI check that does what
> the reviewer currently does automatically. we should get as close as possible to that. the
> reviewer still needs to verify the correctness of those changes anyway. the CI is only a help"

> "you can push and create PRs"

6. **A skill, helped by a script, reads the inbox and files it.** The agent copies each note's
   current text into a playtest file and files the queue entries in one PR; the player chooses
   when a batch becomes that PR, and may edit an issue until the PR merges. → leafy-finch.
7. **A PR whose changed files are all docs skips the heavy Godot checks, and only those.** The
   light checks still run. The categories are the three flags above. → leafy-finch.
8. **The review of a queue update checks faithfulness, and it is Sonnet's.** A reviewer flags;
   it does not resolve. → leafy-finch.
9. **CI checks what can be checked automatically, as close as possible to everything the
   reviewer checks today**, so the review spends its time on what matters. The reviewer still
   verifies the correctness of what CI checked; CI is a help. → leafy-finch.
10. **A PR that changes code must also change the queue and the decision records**, since the
    standing rule is that a finished item's file is deleted and its record written, both. The
    `No queue item: <reason>` escape line of option C is accepted. → leafy-finch.
11. **No PR merges with a handoff file in it.** One may be pushed while the PR is being made; it
    is removed before the PR is done. → leafy-finch.
12. **CI checks that an inbox issue is transcribed word for word into the playtest file** (option
    E's optional check). → leafy-finch.
13. **An agent captures the player's words into the inbox with a script, by its own judgment.**
    Option F's script is kept and its hook is dropped: "I don't want my entire conversation
    recorded. an agent has better judgement there." → leafy-finch.
14. **The GitHub write guard lets an issue write through a script, under the agent's own
    identity, and still denies an agent's direct `gh issue`.** → leafy-finch.
15. **The work is filed as a queue entry by today's workflow, and built once that PR merges.**
    "The old workflow" is filing as this file does — a playtest file and a queue entry on a
    branch, a PR, its review and the player's go-ahead to merge — rather than through the inbox
    the entry builds. → leafy-finch.

## The filing's own record

> "for things like "(b) is an issue since I have to hope that the agent gets to write a comment
> down before a" you need to also include what (b) meant at the time. if you just record my side
> then important context is lost"

16. **A playtest file records the assistant's side as far as the player's words answer it**: the
    question, the options with their labels, the proposal a "yes" accepts. A label the player uses
    is defined where it is quoted. → **playtest-feedback**, "Write it down with all of its
    detail, before doing anything about it".
