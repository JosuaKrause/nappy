## M109 — Rotational smoothing for the grass base — 2026-09-12

PLAYTEST-65 applies the asphalt smoothing method to the soft grass base. The preparation recipe
now takes the radius-four blurred grass and averages its 0°, 90°, 180° and 270° orientations with
equal RGB-channel contributions. This is an offline base operation; clumps remain separate
transparent components placed by the engine.

The base's mean RGB-channel brightness is 109.2292, and all four edge means are 110.625.
Mean absolute difference between opposite edge pixels across both axes is 1.5833 on the 0–255
channel scale. Native and 4× repeats show a continuous soft green field without a directional
brightness step. The installed base hash is
566c0e7169f4fd34e81af5396d9a15a379e6e47ee853e68dbaace1c56fbb8a19.

The grass component pixels, source-ID contract, asphalt and damage artwork remain unchanged.
The quiet-square comparison uses the smoothed grass base while preserving its generated paving,
SVG input and brightness reference. The retained-input rebuild reproduces both evidence bundles,
and component verification, import/boot and lint pass. The runtime park review uses the retained
engine-layout capture recipe with the shared floor materials.
