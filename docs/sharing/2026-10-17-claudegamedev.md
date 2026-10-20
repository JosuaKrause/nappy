# r/ClaudeGameDev — first showcase post (draft)

Post type: **Images & Video**, the trailer uploaded as the video (`build/trailer/trailer.mp4`,
re-rendered with `tools/trailer.sh` after the release). Flair: **Browser Game**.
Revised after a cold read by an agent that had never seen the game; the player's own lines were
kept in their words except where a newcomer could not follow them.

---

**Title:** Walk the baby to sleep: a roguelite built with Claude Code

**Body:**

Just a walk, until she sleeps.

Nappy is a top-down browser game: push a stroller through a city and get your baby to sleep. The only
choice is where you walk. The city stays the same all run, but what happens in its streets changes
every day: noise and crowds wind her up, parks calm her down. Free, no sign-up, phone and desktop:
https://nappy.josuakrause.com/

**How it was made**

Claude Code wrote all of it (Godot 4.7, GDScript, the tooling, the SVG art, the trailer); no
hand-written code. One session plans and briefs agents that each build one item in their own git
worktree, and a separate agent reviews every pull request adversarially before it merges: about 600
pull requests in seven weeks. The project's rules live in the repo as skills that hooks load right
before an edit touches their area. Codex painted the PNG art.

I did the design and playtested after nearly every change; my notes are saved word for word and
turned into work. I deliberately stayed out of the code itself, no reviews and no advice on how to
structure it, to see how far vibe coding goes.

**What went wrong**

- Walk cycles. Generated frames kept putting the same leg in front, and "fixed" frames often only
  recolored the other leg. What helped: compare the legs' outlines with the colors removed, and
  trace each leg from hip to knee to foot; in a two-frame walk the front leg has to swap.
- Lag on phones. Draw calls were not it; a debug overlay in the live build that turns systems off
  one at a time showed what each part actually costs.
- Undertale-level code quality. Agents add code where similar code already lives, so a few files
  grew huge (the main script past 3,000 lines, one event class past 7,000) and the escape sequence
  got its own parallel copy of the game's engine.

**What keeps it fair**

- Paths through the city come first; obstacles are placed along them.
- Random events come from a marble bag, not dice.
- A fast hazard is announced before it appears.
- One unlucky hit never ends a day.

**If you try it:** what made you pick one street over another?
