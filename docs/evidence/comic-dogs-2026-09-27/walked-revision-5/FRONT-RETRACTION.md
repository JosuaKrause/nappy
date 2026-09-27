# Front-diagonal near foreleg retraction

## Restore the advancing hind leg

Inputs: `raw/front-retracted-missing-hind.png` (target with corrected near foreleg but missing
near hind), `raw/dog_front_diagonal_c.png` (the successful advancing near-hind anatomy only),
`source-renders/art/events/dog_front_diagonal_c@6.png` (four-limb pose authority).

```text
Image1 is the edit target. It accidentally has ONLY THREE legs. Restore the missing FOURTH leg: the forward-reaching LIGHT NEAR HIND LEG. Preserve the three currently drawn legs and entire dog body/head/tail exactly.
Image2 shows the correct four-leg anatomy before its near front leg was corrected. Use ONLY its forward-reaching light hind leg as the donor/reference to restore the missing limb in Image1. Image3 is the reviewed SVG C full pose.
The missing near/light hind leg must grow continuously from the SAME rear haunch, immediately in front of the existing dark backward hind leg. It angles down-right beneath the rear half of the belly. In a326x263 composition plane, original near hip approx(62,145), new light thigh passes through(98,190), shin(113,216), paw(125,234). Copy this anatomical idea and exact existing style from Image2's advancing light hind leg.
KEEP Image1's corrected light near FRONT leg bending backwards to its paw around(155,235). It is a separate limb farther RIGHT than the restored near hind paw. Leave a clear small transparent gap between these TWO LIGHT legs and TWO LIGHT paws beneath the belly: near hind paw atx125, near front paw atx155. Do not erase, merge, fuse or recolor either one.
Final animal MUST show FOUR owned legs and FOUR paws: dark hind trailing far left, LIGHT hind advancing atx125, LIGHT fore trailing atx155, dark fore advancing far right. Original haunch and shoulder stay fixed. Preserve all head/body/tail/collar/other-limb pixels as close as possible. One dog, original framing, true transparent background; no labels or guide marks.
```

The first front C keeps the near foreleg directed forward; the reviewed source requires it
to trail back-left. The current raw remains as the edit dependency. Only that foreleg is
requested to change; the other three limbs already have the required opposite reach.

Inputs: `raw/dog_front_diagonal_c.png` (edit target),
`source-renders/art/events/dog_front_diagonal_c@6.png` (reviewed pose authority).

```text
Use case: precise-object-edit. Correct ONLY THE NEAR/LIGHT FORELEG in Image1. Preserve the other three legs, whole torso/head/tail/collar, canvas and true alpha.
Image1 is the current illustrated front-diagonal C edit target. Image2 is the reviewed source C pose authority.
There is one precise anatomical error: the foreground LIGHT foreleg still slopes down-right to a foot ahead of its shoulder. It must instead trail BACK-LEFT from the SAME attached shoulder, underneath the belly, exactly as the light near foreleg in Image2. This is a genuine shape/position change, not recoloring.
Keep the upper shoulder attachment where it is beneath the cream chest. REDRAW this one connected near foreleg so its knee/elbow bends left and the paw lies conspicuously LEFT of that shoulder, toward the rear dog's feet. In the original A crop coordinate plane (326x263), keep root around(177,157), bring elbow to(161,202), paw center to(150,245). The current light paw aroundx200 must move approximately50 pixels LEFT, staying on the same low floor. The shin should visibly lean down-left, with a small forward toe at its end. Maintain normal leg thickness and continuous shoulder-to-upper-leg anatomy.
This light backward foreleg is IN FRONT where it overlaps the far DARK foreleg. Keep far DARK foreleg reaching forwards-right exactly as it is. Keep both hind legs and their successfully reversed step exactly as they are. Do not move or redraw any hip, haunch, body region, collar, head or tail. The new pose must read near fore BACKWARD, far fore FORWARD, without changing ownership or shifting attachment. One complete dog; no labels, guide marks, background, shadows or added details. Genuine transparent background.
```
