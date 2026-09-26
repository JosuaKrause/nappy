## M56 — The resistance is noticed · the brief as it was drafted, before the forks came back

*(The outcome, and what the three forks settled, is under "M56 — The resistance is noticed ·
`feature/the-city-notices`" earlier in this file. This is the drafting that preceded it, kept for
the questions it raised rather than for the answers it guessed at.)*

**Given on 2026-09-01, as the answer to M55's fourth question rather than as a finding.** The
question was whether a resistance task may cost a nerve. The answer is no, and the second half of it
is a system this game does not have:

> **"how would that work? losing a nerve means repeating the day with the failed day erased. so no it
> cannot cost a nerve. but what should happen is that the more resistance tasks are completed the
> more dangerous the environment becomes. we need abduction vans that normally just abduct people
> but start trying to abduct the player if she is part of the resistance. and other dangers like
> this"**

**The refusal is better argued than this side's recommendation was**, and the difference is worth
keeping. M55 argued *not yet, because five nerves are five attempts and a step that spends one can
end a run for an optional reward* — a caution. The player's reason is structural: **a nerve is not a
resource, it is a rewind.** Losing one replays the day with the failure erased, so "spend a nerve"
does not mean *pay*, it means *have this day not have happened*. There is nothing to trade. Nothing
in the design should offer it, at any difficulty.

**And what replaces it is the same instruction as playtest 17's finding 9, one scale up.** Finding 9
is *pursuing the resistance should make the game harder*, and M55 answers it **at the chalk mark** —
a guard beside every mark. This answers it **in the city**: the further in you are, the worse the
place gets.

- [ ] **Danger scales with resistance progress.** `GameState.resistance_progress` is already the
      number; what it may move is the open question. The constraint is `CLAUDE.md`'s M50 rule — *the
      role is not a decision*, it is read off the def — so heat must not become a per-row switch
      somebody sets by hand
- [ ] **The patrol is the non-lethal rung of the ladder.** *(2026-09-01: "and the robber is a guard
      now — the patrol should be more dangerous when you're part of the resistance but not lethal
      like the van.")* Two instructions in one sentence, and the first explains the second.

      **The robber has been reassigned.** M55 makes `alley_robbery` the guard standing beside every
      chalk mark, which is a *fixed* cost attached to a *place*. So it is no longer available as the
      thing that gets worse as you go, and `police_patrol` takes that job.

      **And the ladder has two rungs on purpose: the patrol escalates but never kills, the van
      escalates and does.** That is the range the escalation is spent over — it is the same shape as
      M50's *"ranges from very costly to deadly"*, applied to progress instead of to ground.

      What `police_patrol` is today, so the escalation has a floor to be stated against: mobile at
      74px/s along roads and crossings, intensity 10, inner radius 44, outer 185, up to 12 a day,
      from day 4, and **not** `hard_fail`. Its own docstring is the design — *"not dangerous yet —
      the danger is that you start planning around it, which is the point."* The axes an escalation
      could move are intensity, radius, population, and whether it investigates rather than patrols;
      which of those, and how they read, is design work to draft and put back, and `hard_fail` is
      ruled out by the instruction

      **Not to be confused with the patrol rule M55 deletes.** That one is `ContactPoint`'s
      hold-reset, and it goes because there is no hold left to reset. This is a different mechanism
      on the same row, and it arrives *after* M55 rather than surviving it
- [ ] **The abduction van takes somebody, and then it takes you.** *"Vans that normally just abduct
      people but start trying to abduct the player if she is part of the resistance."* Two halves and
      the first is not the small one:

      **`abduction` today does neither** (`event_catalogue.gd:926`). It is an unmarked van that
      **idles** — static, 250px field, `hard_fail` inside 54px, a 4.6s telegraph, `first_day` 8. It
      never moves and nothing is ever taken; the abduction is entirely in the name and in what
      happens to *her* if she walks into it.

      - **"Normally just abduct people" is a first for this game.** Nothing in the catalogue has ever
        acted on the crowd. The one existing coupling runs the other way — M19's bump, where *she*
        startles an agent — and the excitement invariant is why: events never push, the world sums
        `contribution_at()`. A van that takes a pedestrian is the first authored event with a
        **victim**, and it is a precedent worth taking deliberately rather than as a side effect of
        a two-word phrase. It is also what makes the second half legible: a van you have watched take
        somebody is a van you understand is coming for you.
      - **"Starts trying to abduct the player" is `pursues`, conditioned on run state**, and that
        collides with a load-time contract. `Tuning.validate_event()` and `validate_pursuit()` check
        the whole catalogue **on boot**, from data. A def that changes shape mid-run is validated in
        the shape it booted in, so **both shapes have to be validated or only the harmless one is** —
        this is the M35 lesson (*a contract stated in seconds is not stated at all*) arriving as a
        contract stated about the wrong object.
      - **A van cannot chase at van speed.** `validate_pursuit` is stated over `RUN_SPEED`, and the
        two things that pursue both move at 130px/s — slower than a run, faster than a walk, by
        construction, because that is what makes running the right answer. A hunting van inherits
        that, which means an unmarked van creeping after her at a fast walk. Whether that reads as
        menacing or as comic is a **screenshot question**, not an arithmetic one
- [ ] **What it collides with, named rather than resolved.** M28's rule is that **nothing else
      happens inside a lethal event's field**, and M50 exempts only the off-corridor `WALL` role. A
      lethal field that *follows her* is neither: it goes wherever she goes, so it cannot be kept
      clear of anything by placement. Either the rule gains a third case for pursuers — which
      `charging_dog` and `alley_robbery` have quietly needed since M35 and M36 without anybody
      writing it down — or a hunting van is not a `hard_fail` and takes something else off her
- [ ] **"And other dangers like this"** — the same brief as playtest 17's finding 8, one level up:
      more rows of this shape, **drafted and put back** rather than built. The obvious candidates
      already in the catalogue are `police_patrol` (which already knows about the resistance, via
      `ContactPoint`'s patrol rule), `checkpoint` and `night_raid`. Do the drafting after the vans,
      because the vans are where the precedent gets set
- [ ] **And measure it against the nerves before believing it.** Five nerves are five attempts at a
      fourteen-day run, and this milestone makes the back half harder *precisely for the player who
      is doing well at the optional path*. The last human verdict on the difficulty is playtest 06's,
      and **nobody has ever reached act III**. A throwaway probe over a full run at each progress
      level, not an argument
