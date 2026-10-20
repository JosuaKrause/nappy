# r/ClaudeGameDev — first showcase post (draft)

Post type: **Images & Video**, the trailer uploaded as the video: the cut the README embeds, from
`build/trailer/2026-10-18b/`. Flair: **Browser Game**. Posted on a weekday at 5pm Eastern, when the
player can answer the first comments.
Revised after a cold read by an agent that had never seen the game; the player's own lines were
kept in their words except where a newcomer could not follow them.

---

**Title:** Walk the baby to sleep: a roguelite built with Claude Code

**Body:**

Just a walk, until she sleeps.

Nappy is a top-down browser game: push a stroller through a city and get your baby to sleep. The
only choice is where you walk. The city stays the same all run, but what happens in its streets
changes every day: noise and crowds wind her up, parks calm her down. Free, no sign-up, phone and
desktop: https://nappy.josuakrause.com/

**How it was made**

Claude Code wrote the game and drew it (Godot 4.7, GDScript, the tooling, the SVG art, the
trailer); Codex painted the PNG art. No hand-written code, no downloaded assets. An orchestrator
session plans the work and briefs agents that each build one item in their own git worktree, and a
separate agent reviews every pull request adversarially before it merges: about 600 pull requests in
eight weeks. The project's rules live in the repo as skills that hooks load right before an edit
touches their area.

I did the design, provided reference drawings and photos, and balanced the game through playtests;
my notes are saved word for word and turned into tasks for the agents. I deliberately stayed out of
the code itself, with no reviews and no advice on how to structure it, to see how far vibe coding
goes.

**What went wrong**

- Walk cycles. Generated frames kept putting the same leg in front, and "fixed" frames often only
  recolored the other leg.
- Lag on phones. The obvious suspect, draw calls, turned out not to matter: cutting them in half
  left the frame time where it was.
- Undertale-level code quality. Agents added code where similar code already lived, so a few files
  grew huge (the main script past 3,000 lines, one event class past 7,000) and the game's finale
  got its own parallel copy of the engine.

**What keeps the game fair**

- Paths through the city come first; obstacles are placed along them.
- Random events come from a marble bag, not dice.
- A fast hazard is announced before it appears.
- One unlucky hit never ends a day.

**If you try it:** what made you pick one street over another?
