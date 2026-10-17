# r/ClaudeGameDev — first showcase post (draft)

Post type: **Images & Video**, the trailer uploaded as the video (`build/trailer/trailer.mp4`,
re-rendered with `tools/trailer.sh` after the release). Flair: **Browser Game**.
Revised after a cold read by an agent that had never seen the game; the player's own lines were
kept in their words except where a newcomer could not follow them.

---

**Title:** Walk the baby to sleep: a roguelite built with Claude Code

**Body:**

Just a walk, until she sleeps.

Nappy is a top-down game about a parent pushing a stroller through a city, trying to get her baby
to sleep. The only thing you decide is where you walk: the city is the same all run, so you learn
it, but what happens in its streets changes every in-game day. Noise and crowds wind the baby up;
if she gets too upset the day is lost, and a few things end it at once. Find a park where the baby
can calm down. Free, no sign-up, plays in the browser on phone and desktop:
https://nappy.josuakrause.com/

**What Claude did**

- Wrote the game, in Godot 4.7 and GDScript, and the tooling around it. No hand-written code.
- Worked as a team of agents: one session plans the work and briefs agents that each build one
  item in their own git worktree; a separate agent reviews every pull request adversarially before
  it may merge, and every agent works under its own bot account. About 600 pull requests in seven
  weeks.
- Kept the rules in the repo as skills (25 of them) that hooks load before an edit touches the area
  they govern, so a lesson learned once is in front of the next agent at the moment it matters.
- Turned my playtest notes into work: I write a note as a GitHub issue (or say it in a session),
  and it is saved word for word in the repo before anything is built from it.
- Drew the art as SVG, and cut the trailer from scripted scenes the game plays by itself, so it
  renders the same every time.
- Tested headless, with test scripts that walk every route and check that every day can still be
  finished, plus a browser check of the web build on every pull request.

Other tools: Codex (the painted PNG art, and some features and reviews), GoatCounter (anonymous
counts of where players lose a day and what they run into, which Claude reads back).

**What went wrong**

- Turning vector art into painted sprites with an image model. It painted a fake transparency
  checkerboard even when told not to, a "style transfer" came back as the same drawing with a
  nicer texture, and characters changed size between facing directions. What helped: keep the
  vector original as the source, ask for a redraw rather than a retexture, and check every output
  by script (real transparency, the original's canvas size and anchor point, the same height in
  every direction) before looking at it by eye.
- Walk cycles. Generated frames kept putting the same leg in front, and "fixed" frames often only
  recolored the other leg. What helped: compare the frames' leg outlines with the colors removed,
  and trace each leg from hip to knee to foot; in a two-frame walk the front leg has to swap.
- Lag on phones. The obvious suspect, draw calls, turned out not to matter: cutting them in half
  left the frame time where it was. What helped: a debug overlay in the live web build (turned on
  by a URL flag) with switches that turn off one system at a time, so the phone itself shows what
  each part of the game costs.

**What I did:** the design and every decision about it. I came up with the idea and its rules,
playtested on my laptop and phone after nearly every change (281 notes from my playtests, kept word
for word), and brought in project management guidance for Claude: how work is planned, handed to
agents and reviewed.

**What made it fair** (my strategies):

- Build full paths through the city first, then place obstacles along them.
- Draw random events from a shuffled "marble bag" instead of rolling dice, so luck evens out; you
  can stack a guaranteed event into a bag, or put one bag inside another to keep similar events
  apart.
- Warn about a fast hazard before it appears, then spawn it just off screen where the warning
  pointed.
- Guide the player without them noticing they are being guided.
- One unlucky hit never ends a day on its own; a loss takes several mistakes.

**If you try it:** what made you pick one street over another?
