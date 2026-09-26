## Limb attachment repair — 2026-09-08

The player asked "let's fix the limbs", continuing PLAYTEST-43's connected-body and SVG-scale
review and PLAYTEST-44's selection of the transparent v3 pram. They also explicitly authorized
committing, pushing and updating the existing draft PR #49. The overhaul remains opt-in; this
request does not authorize its release or merge into the default game.

Source inspection found that the mother's 1280×1536 sheet is independently packed. Painted head,
torso and arm bands occupy approximately y=44–190, 205–413 and 440–582; the upper/lower leg sets
occupy 603–787, 795–907, 920–1117 and 1131–1251, with two sets of shoes below them. Uniform
192-pixel rows cut through those drawings. The approved 1448×1086 pram similarly uses unequal
vertical packing: chassis 101–331, seat 375–571, canopy 640–770 and baby 844–1017. Its eight views
begin with the rear, whereas the mother sheet begins with the front. Those approximate bands
guide inspection; they are not substitutes for measured per-part registrations.

The first implementation pass was rejected in code review. It retained inferred crop bands,
guessed joints and the rejected upper-only scale calibration; its segment transform multiplied
the target/source length ratio by the source-to-world scale again. Changing the tiny gait target
to half a stride also did not prove that a stance leg stayed within reach. The repair gate
therefore checks transformed source endpoints, painted extents and sustained displacement, not
just the solver's own targets or literals repeated from a manifest.

The movement contact sheet samples public compositor APIs with accumulated virtual owner
positions, then displays each pose in a fixed cell. Review corrected initialization that reset
sampled walkers when added to the tree, a blocked sample that accidentally teleported its owner,
and a ground line that counted the cell offset twice. Its mid-swing samples must find an actual
active swing; it is a diagnostic of sampled poses rather than proof of smooth live motion.

The sustained stop/start regression exposed a second cadence failure: a short displacement could
reach the step trigger with no distance left to advance the swing, then the following stop
cancelled that swing. Repeating the sequence left both feet behind the body. Five short bursts
did not expose it; forty 0.8-pixel bursts did. The repair must retain unfinished step progress
across zero-displacement calls rather than continually restarting the trigger interval.

The shared affine transform passed a slanted-axis test with an independently displaced pivot:
both source endpoints meet the requested joints while transverse width is scaled once. The
walker implementation uses alpha-measured upper-body crops and crop-local leg/shoe endpoints,
calibrating the complete head-to-ground body to 38 logical pixels. Atlas filtering is clipped to
each region. All parts use zero child z with directional sibling ordering, so the city's
ground-depth sort can keep each actor together.

The gait retains swing progress and lifted pose when applied displacement is zero. Travel
resumes the unfinished step; a large displacement consumes as many complete strides as needed.
Cadence is limited by leg reach, including the first trigger interval, and foot offsets preserve
their screen-side relationship to the hips. Focused regressions cover all facings, continuous
travel, the forty-burst stop/start sequence, planted rendered soles, large reversal, turn and reset.

The source sheet supplies one complete E-facing and one complete W-facing walker leg set, so
each is explicitly reused for the two animated legs without mirroring. Diagonal crops share some
painted edge pixels, and the mustard SW upper drawing has ambiguous authored facing. Those
limitations remain in the manifest and authoring queue; registration does not make new artwork.

Mother registration uses a textured torso core to exclude the painted sleeves, with separate
shoulder-to-hand arm segments reaching the pram's painted grips. The selected transparent v3
pram PNG is unchanged. Review rejected universal bottom-centre layer offsets and then caught
a subtler mismatch: contacts on the basket and seat bottom passed alpha-support tests but were
not the corresponding frame hinges. An independent E/W/NE source review measured approximately
7.18, 5.67 and 6.92 logical pixels of hinge separation. Its crop-local chassis/seat hinge pairs
were E `(81,93)`/`(69,100)`, W `(100,93)`/`(100,100)`, and NE `(128,90)`/`(141,96)`.
The source estimate is within about two pixels; matching these mechanical landmarks matters
more than proving that an arbitrary pivot lands somewhere opaque.

The complete pram is calibrated to 30 logical pixels after connecting all four layers. A
chassis-only calibration produced assembled heights of roughly 32–47 pixels in the inspected
intermediate registrations. N/S use the visible centre support seam because the side hinge is
hidden; the other views use the large side hinge. The canopy and baby attach to their own
painted contacts on the positioned seat.

Two bounded OpenGL captures used the standalone eight-facing scene at 1280×720, one second
after initialization, without a gameplay seed or route. The
[dark-backdrop capture](../evidence/archive/session-captures/2026-09-08/illustrated-limbs-dark-backdrop.png)
was taken at 19:31:57 EDT from `8dc764f`, before the final pram-contact correction. The
[contact review](../evidence/archive/session-captures/2026-09-08/illustrated-limbs-contact-review.png)
was taken at 19:35:24 EDT from `a7d6977` with the lighter actor-row backdrop in the working tree.
Both keep the legacy comparison at +96 world pixels. They are runtime evidence, not approved art.

The lighter backdrop exposed crossed resting knees: the left/right bend signs pointed inward,
and a minimum bone-length multiplier of one forced a bend even when the neutral hip-to-ankle
distance was shorter than the nominal bones. The follow-up uses outward bend signs and derives
the compression floor from configured rest geometry, retaining the stride and maximum-reach
limits. The contact review records the defect that motivated that follow-up; it is not a capture
of the corrected resting knees.

The integrated tree passed `./tools/check.sh`, the illustrated `visuals`, `limb_attachments`
and `mother_attachments` suites, the legacy `visuals` suite, doc lint and whitespace checks.
Negative registration probes intentionally emit validation errors; there were no script errors
or leak warnings in these final runs. The neutral-knee regression checks same-leg alignment,
outward flex and the existing movement sequences. Both diagnostic scenes also boot headlessly.
The full suite belongs to PR CI; smooth motion, live overlaps and visual acceptance remain open.
