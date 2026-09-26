# Brisk heron — The order after the hook, the park fence's review, and Codex beside Claude

2026-09-26. Said in conversation while PRs #377 (the `git grep` guard), #372 (M207, the cyclist's
warning) and #374 (M129, a spent park is closed) were reviewed. The player's words on the pursuing
dog's timing from the same conversation are in [PLAYTEST-145](PLAYTEST-145.md), statements 10–16.

## The order

> "get the hook in. then the new planning rules. then we need to update all open PRs to follow the
> new planning rules -- this will be a major effort so I want this to get out of the way first. I
> asked other work (not in claude) to stop for now"

> "then the counter args"

> "then we can do regular work again"

1. **The order is: the `git grep` hook (PR #377), then M223 (the queue as files), then every open
   PR converted to M223's layout, then M225 (the counter's asks), then regular work.** → the
   queue's order, written on PR #377.

## The spent park's review

After the post-merge review of PR #374 found that a fence carried into days 10–11 can leave the
day's route tree with one calm area, and listed six choices the build made beyond the player's
words (the fence in act III or later; in every run, on day 9; standing for the rest of the act
only; nothing spoiled inside it; the route tree refusing a branch that ends at a used area as well
as one through it; a fence chosen on day 13 or 14 dropped by the night escape's repaint), with the
recommendation to keep all six:

> "5. yes, obviously that is an important note that should be clear by the rule that a path should
> end in an available calm zone. night escape doesn't need a fence in a park. plan the fix but we
> need to focus on other tasks right now"

2. **A day's path ends in an available calm area**, so the route tree refuses a branch that ends
   at a used area as well as one that passes through it. The rule is to be stated where the route
   tree's rules are. → M129.
3. **The night escape needs no fence in a park**, so a fence chosen on day 13 or 14 is dropped by
   its repaint. → M129.
4. **The other four choices stand** as recommended; the player did not object. → M129.
5. **The review's fix is planned now and built later**, after the work in statement 1. → M129.

## The Codex adapter

Told what `tools/codex-hooks.py` is (it lets Codex run the same hook scripts as Claude Code) and
that the `git grep` guard's review had found two places it did not reach:

> "okay, yes this is important to keep up to date"

6. **A change to a hook updates the Codex adapter and its tests in the same PR.** → PR #377, which
   writes the rule into `CLAUDE.md` and python-tooling.

Told that the rule would also be loaded automatically on an edit to the hook files, once M223 has
landed, since M223 rewrites the file that maps paths to rules:

> "good"

7. **An edit to `.claude/hooks/`, `.claude/settings.json` or `.codex/` loads the adapter rule by
   itself**, after M223. → M228.

## Codex as a sub-agent

> "I wanted to make it a later item but since you're on it right now -- let's add a todo to make it
> possible to use codex as subagent, too" · "from within claude"

> "codex subagents should work in worktrees like your subagents" · "not in random tmp folders"

> "there might be a claude plugin for using codex? not sure"

8. **A Claude Code session can hand work to Codex as a sub-agent.** → M227.
9. **A Codex sub-agent works in a git worktree under `.claude/worktrees/`, the way a Claude
   sub-agent does, never in a scratch folder elsewhere.** → M227.
10. **Whether a Claude Code plugin for Codex exists is to be found out first**; the player is not
    sure. → M227.
