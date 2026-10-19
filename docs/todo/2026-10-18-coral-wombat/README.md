priority: later

# coral-wombat — Sharing the game on Reddit from the player's account · filed 2026-10-18


The player asked for a way to read and post on Reddit for sharing the game, then settled it: "actually,
no. all you need is read access -- I can post things manually", and "copy over the credentials that
you had from earlier here (gitignored) and write tooling for it", and set the band: "It's fine later it
is", and "yes, keep improving the reader where you see gaps -- same with above where you had to write
a custom script" (minty-lemur #769).

Built: the read-only reader `tools/reddit.py` (PRs #774 and #775). Open: the sharing itself, which
starts from the draft of the first r/ClaudeGameDev post on draft PR #776. **Read as:** the agent reads
Reddit and drafts each post or reply into a file in the repo; the player reviews it and posts it by
hand; the two decide together when and to what to reply.
