priority: now

# sunny-alpaca — Work survives an interruption: in-flight state is recoverable · filed 2026-11-02


**The ask.** The player: "consider: what happens if you get interrupted / the computer dies / you
get compacted / you get cleared while you're in the middle of something. it should be possible to
recover from this", then "that's why we store things on the board or the issues or the repo", "so it
doesn't have to rely on an active conversation (that might get deleted at any time)", "local files
are fine, too... for some information, like restart prompts etc", "as long as a new you is able to
reorient and continue where the previous session ended", and, on the orchestrator saying it would
rewrite the board and the restart prompt at every merge, verdict, hand-back and answer: "not
everything needs to be updated every time. it's enough if the state *can* be recovered. if it's
cheaper to just update the local file then it can be updated more frequently and the board gets
updated in batches", "if I want to see what's going on I usually ask before looking on the board
anyway", "treat the board as information for me (and a channel to respond) but keep (temporary)
information for you local" (inbox #986 in brisk-pelican).

**Read as:** an orchestrating session keeps what it is in the middle of where a fresh session finds
it: the repository, the issues, the board, or a local file such as the restart prompt. A new session
can reorient from those alone and carry on. The orchestrator's own working state (which pull request
waits on what, which review is next, what a builder was told) goes in the local restart prompt,
updated whenever it is cheap to; the board is for the player, what they need to know and where they
answer, and is updated in batches rather than at every step.

*Proposed, not asked for:* the band, `now` (the player named none), and that the rules go in the
skills that govern these moments: **orchestrating** (keeping in-flight state recoverable, the
restart prompt kept current during the session, not only at its end), **session-cleanup** (its
restart-prompt step says the file is written during the session too) and **board** (the board as
the player's information and answer channel, the Running table updated in batches).
