## M167, choose the actual opposite leg contact — 2026-09-19

[PLAYTEST-102](../playtests/PLAYTEST-102.md) rejects the normalization's source: "you took the wrong
leg picture for the cropping -_- it's the one where the wrong leg is in front". This repeats
the anatomical contact requirement in PLAYTEST-87 and PLAYTEST-88. The selected P2 pushing
side A and B both show the advancing down-right thigh in front. The B label and the generation
record's claimed correction were not evidence of a different leg overlap; selecting that
source made normalization preserve the wrong pose.

Inspection found the required foreground thigh continuing down-left into the trailing shoe
in the final carrying F side B. The final carrying F front-diagonal A has its near screen-left
leg trailing and far screen-right leg advancing; its thighs sit beside each other, making the
profile overlap the stronger proof. Both registered source sprites match the runtime artwork.
The next donor selection uses those final carrying legs beneath the father's pushing upper
body. This is a leg donor choice, not a change to carrying art. The rejected normalization
also supplied an entire old father figure as an identity reference, including its wrong
legs; the new identity input ends above the pelvis to remove that competing pose.

The crop-feedback record was first moved from PLAYTEST-94 to PLAYTEST-95 to avoid the
independent escape/save feedback. Its current identity is PLAYTEST-101; its original words
and separate identity are preserved.

One normalization attempt with the corrected carrying-F donor crops retained the profile
foreground thigh's continuous down-left chain into the trailing shoe; the far advancing thigh
emerged behind it. The diagonal retained the screen-left higher trailing shoe and screen-right
lower advancing shoe. The large input included no old father pants: the father's original
high-resolution identity crops ended above the pelvis. The generator completed the lower jacket
and pelvis between that upper artwork and the selected legs. The result and its source-contact
proof are preserved under `correct-contact-2026-09-19/` beside the rejected attempt. Runtime
art stayed unchanged; final appearance and frame-to-frame proportions remained for visual review.
Native inspection also found brighter B trousers and a more front-facing diagonal stride.
Fresh preparation and assembly reproduced the saved inputs, sheets and GIFs byte-for-byte;
protected frames, native canvases and 190ms phase timing passed the recipe checks. Documentation
lint and whitespace checks passed. The prior boot check covered the unchanged runtime tree.
