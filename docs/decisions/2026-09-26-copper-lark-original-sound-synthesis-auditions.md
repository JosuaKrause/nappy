## Copper lark — Original sound synthesis auditions · built 2026-09-26

[Player's words](../playtests/2026-09-26-copper-lark.md): create sounds here from scratch, with no
precreated assets; compare grounded and stylized versions; write the approach down like graphics
so it is reproducible; keep the experiment on its own branch.

The experiment generates footsteps, stroller wheels, a car horn and loudspeaker crackle in both
styles from handwritten Python oscillators, seeded noise, envelopes and filters. These four
subjects were the assistant's selection, not a request for particular game triggers. There is no
runtime audio installation. Human breathing and voices were discussed as a separate, more
difficult synthesis experiment, not implemented or promised as realistic.

`tools/synthesize-sfx.py` writes eight 48 kHz mono PCM16 WAVs, a comparison, a labeled offline
listening page, a provenance manifest and a portable ZIP carrying the exact generator. The
sound-effects skill records source recipes, seeds, processing, commands, hashes, preservation of
submitted passes and the distinction between technical checks and listening approval; the edit
hook loads it for audio and sound-generator paths.

The first shared pass used equal peak levels. The second keeps the same designs but targets
-22.5 dBFS RMS with a 0.70 peak ceiling to reduce loudness bias in the comparison; the measured
RMS spread was under 0.15 dB. This is energy matching, not proof of equal perceived loudness.
The second pass was the listening proposal of its day; neither pass is kept (see "A pass is a
command").

Verification covered Python formatting/types/tests, help and rejected-argument paths with no
output, two-directory byte-for-byte rebuilds, WAV format/non-silence/headroom/boundaries,
page/ZIP references, hook dispatch, skill validation and document lint. Reproducibility is
measured in the pinned environment, not asserted across all floating-point implementations.
No agent listening approval is claimed; recognition, comfort and preferred style await the
player in `REVIEW.md`. The game's visual-only warning contract remains unchanged.

**Listening verdict, 2026-09-26:** the player rejected the stylized direction as too far off and
preferred the grounded direction, while saying it still failed to represent the subjects. The
stroller sounded like ocean waves and the footsteps were too heavy. The next requested pass
therefore addresses recognition and weight before any expansion or runtime binding; the specific
dry-contact/rattle and light-sole recipes are assistant proposals, not approved sound outcomes.

**The focused revision.** Pass 3 compares the exact first-shared grounded footsteps and stroller
WAVs with revised versions: restrained midrange heel/toe contacts instead of the footsteps'
low thump, and dry wheel contacts with paired mechanical rattles instead of the stroller's wash.
The four clips' measured RMS spread is 0.49 dB. The user has not approved their recognition or
weight; the listening question is in `REVIEW.md`. No stylized iteration or runtime binding is
included. The listening page now pauses and resets other players when a new clip starts.

**Reproducibility correction found in review.** The first pass's README originally invoked the
mutable current generator, so its command would have overwritten the preserved pass with newer
bytes. Each pass now includes its own frozen recipe and a scratch-output command. Passes 1 and 2
were rebuilt with those archived recipes and all WAV bytes compared identical. (The archives
and the audio later left the tree; see "A pass is a command".) The skill now
requires each review pass's recipe to stay independently executable and asks listeners to judge
subject recognition and implied weight before style refinement. Final Python/CLI, hook, skill,
determinism, audio-integrity and archive checks passed.
