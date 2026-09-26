## M109 — Northern diagonal stroller hand contact — 2026-09-12

PLAYTEST-65 asks to lower NE/NW slightly and explicitly retains the SE/SW hand gap because
closing it would make the stroller float. The selected north-diagonal correction is 2 screen
pixels downward. It is chosen visually across frozen P2 contact A, together C and contact B
assemblies, not inferred from an unrecorded landmark-distance measurement. The term is
`4*x*x*y*y*2` for northward normalized facing and zero for every southern facing. It peaks at
the two northern diagonals and fades smoothly to zero at N/E/W without consulting texture sectors.
The 24/17/9 axis distances, 0.7 projection, 7/6 scale and physical body remain unchanged.

The initial proposed normalization peaked above its stated bound; review replaced it with the
squared-axis product and added a bound sweep plus explicit SE/SW preservation checks. The
saved comparison, frozen sources and metadata reproduce exactly. Root import/boot and focused
stroller, orientation, visuals and presentation-mode checks verify integration; the static
review does not establish live-turn appearance.
