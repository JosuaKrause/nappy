# r/ClaudeGameDev — first showcase post (draft)

Post type: **Images & Video**, the trailer uploaded as the video (`build/trailer/trailer.mp4`,
re-rendered with `tools/trailer.sh` after the release). Flair: **Browser Game**.
Lines marked **[check]** are guesses about the player's side and need the player's word.

---

**Title:** Walk the baby to sleep: a roguelite built with Claude Code

**Body:**

Just a walk, until she sleeps.

Nappy is a top-down game about a mother pushing a stroller through a city, trying to get her baby
to sleep. The only thing you decide is where you walk: the city is the same all run, so you learn
it, but what happens in its streets changes every day. Free, no sign-up, plays on phone and desktop:
https://nappy.josuakrause.com/

**What Claude did**

- Wrote the game, in Godot 4.7 and GDScript, and the tooling around it. **[check: no hand-written code]**
- Worked as a team of agents: one session plans the work and briefs agents that each build one
  item in their own git worktree; a separate agent reviews every pull request adversarially before
  it may merge, each under its own bot account. About 600 pull requests in seven weeks.
- Kept the rules in the repo as skills (25 of them) that hooks load before an edit touches the area
  they govern, so a lesson learned once is in front of the next agent at the moment it matters.
- Turned my playtest notes into work: I write a note as a GitHub issue (or say it in a session),
  and it is filed word for word as a playtest record before anything is built from it.
- Drew the art as SVG, generated the sound effects from code, and cut the trailer from the game's
  own saved scenes by script, so it renders the same every time.
- Tested headless, with rigs that walk the routes and check that every day stays winnable, plus a
  browser check of the web build on every pull request.

Other tools: Codex (the illustrated pictures, and some of the work), GoatCounter (anonymous counts
of what players run into, which Claude reads back).

**What went wrong**

- Standing still was the best move in the game. The baby calmed fastest while the stroller stood,
  so a full meter cleared in seventeen seconds anywhere, and the run log showed the winning strategy
  as a 74-second gap where nothing happened. Now only walking calms her, and quiet streets calm her
  faster, which is what makes the route matter.
- Road closures could cut off every way home. Every closure is now checked before it is placed,
  counting how many separate routes are left. **[check: is this a real incident?]**
- The game locked up on my phone and never on a desktop. Finding it started with a per-frame
  record you can save from the phone's browser.

**What I did:** the game itself and every decision about it. I came up with the idea and its
rules, playtested on my phone after nearly every change (281 playtest records hold my notes word
for word), and answered every question the agents brought back. I also set how the agents work:
most of the repo's working rules began as something I told them after a mistake.

**One question:** which way did you walk, and what made you avoid the other street?
