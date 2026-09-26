## Delegating is the default, and the rule that says so loads at `SessionStart`

Asked for on 2026-09-02: *"make more use of sub-agents — you write plans, sub-agents implement
etc."*, and immediately after it *"make sure this is properly triggered automatically"*. Then, after
the first attempt: *"firing on src / test edits is still too late. how about making it a rule that
loads at the beginning?"*

**Three trigger points were tried, and the two that failed each failed in a way worth keeping.**

- **On an `Agent`/`Task` spawn** — the original, from the M55 session. It cannot ever say *this
  should have been delegated*, because a spawn is the decision already going the right way. It only
  governs how a delegation is written, never whether one happens.
- **On the first `Edit`/`Write` under `src/` or `tests/`** — the first answer to *"triggered
  automatically"*, and the reasoning behind it was the rules hook's own principle: the moment a rule
  matters is the moment somebody is about to touch the file. It is the right principle applied to
  the wrong rule. By the first edit the implementation has already started, so the rule arrives as a
  reprimand rather than as a choice — which is what the player's *"still too late"* names.
- **`SessionStart`** — taken. `.claude/hooks/session-rules.sh` injects the skill before the first
  tool call, and writes the same one-shot marker `project-rules.sh` uses, so the two path triggers
  stay as backstops and no-op. Verified by running both hooks against one session id: the second
  injects only `godot`.

**The generalisation, and it is the reason this entry exists rather than a note in the hook:** a
rule about *what governs this file* can be hung on the file, and a rule about *who should be doing
this at all* cannot. The list loaded at `SessionStart` is deliberately one skill long, because
everything in it is paid for in every session whether or not it turns out to be relevant — which is
the exact cost the path-triggered hook was built to avoid.

**What moved out of the skill in the same pass.** The orchestrating skill had accumulated its own
history — *"Asked for on 2026-09-01"*, the dated player quotes for each of the three instructions
above, and the incident that set the headless-first rule (an agent burning several windowed runs on
a `--walk north` rig that stood against the home notch's back wall for the whole run, since the home
is a notch with one exit facing south). All of it is here; the skill keeps only the rules and the
reasons. *(2026-09-02: "the skill now reads like a quest log — keep the rationale etc in decisions
and clean up the skills — THIS is the proper way to write anything.")*
