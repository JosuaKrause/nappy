# M108 people SVG review matrix

Rendered source sheets: [native 1x](people-all-1x.png) and [enlarged 3x](people-all-3x.png). The
sheets contain every new people SVG in this batch, sorted by filename. Native canvases are the
runtime sizes; the 3x sheet is for joins, clipping and directional review. Individual scratch
rasters remain in `/private/tmp/svg-people-2026-09-10`.

The facing convention is N = back, NE = back diagonal, E = side, SE = front diagonal, S = front,
with SW, W and NW using the explicitly permitted mirror of SE, E and NE respectively. A star in the
symmetry column means the authored east-side source is mirrored around the bottom-centre anchor.
Existing unsuffixed canonical files remain unchanged and are the current runtime bindings.

| Family and states | Authored files | Native canvas / anchor | Layers and identity | Facing coverage | Current binding |
|---|---|---|---|---|---|
| Crowd walker | `walker_front/back/side_{body,trim}.svg`; `walker_{front,back}_diagonal_{body,trim}.svg` | 18x38; (9,38) | Body is tintable coat; trim is untinted head, hands, legs and shoes | N/NE/E/SE/S authored; NW/W/SW mirror NE/E/SE* | Live canonical family in `src/crowd/crowd_agent.gd`; named projections prepared |
| Mother carrying | `mother_carrying_{front,back,side,front_diagonal,back_diagonal}_{a,b}.svg` | front/back 24x46 (12,46); side/diagonal 26x46 (13,46) | Rust coat, two gait frames, visible baby bundle and feet | N/NE/E/SE/S authored; NW/W/SW mirror NE/E/SE* | Prepared for finale; no current caller |
| Chatting mother, walking | `chatting_mother_walking_{front,back,side,front_diagonal,back_diagonal}.svg` plus canonical alias | 54x46; (27,46) composite anchor | Sage mother, tan pram, walking arms and grounded case | N/NE/E/SE/S authored; NW/W/SW mirror NE/E/SE* | Canonical asset live in `src/events/event_instance.gd`; named projections prepared |
| Chatting mother, talking | `chatting_mother_talking_{front,back,side,front_diagonal,back_diagonal}.svg` plus canonical alias | 54x46; (27,46) composite anchor | Same mother/pram identity; raised conversation arm and mouth mark | N/NE/E/SE/S authored; NW/W/SW mirror NE/E/SE* | Canonical asset live in `src/events/event_instance.gd`; named projections prepared |
| Dog walker person | `person_{front,back,side,front_diagonal,back_diagonal}.svg` plus canonical alias | 18x42; (9,42) | Generic event passer-by layer; lead remains code-drawn | N/NE/E/SE/S authored; NW/W/SW mirror NE/E/SE* | Canonical asset live in `src/events/event_instance.gd`; companion dog projections belong to the animal worktree |
| Yeller | `yeller_{front,back,side,front_diagonal,back_diagonal}.svg` plus canonical alias | 26x44; (13,44) | Brown long coat, raised arm, beard and open mouth | N/NE/E/SE/S authored; NW/W/SW mirror NE/E/SE* | Canonical asset live in `src/events/event_instance.gd`; named projections prepared |
| Busker | `busker_{front,back,side,front_diagonal,back_diagonal}.svg` plus canonical alias | 30x44; (15,44) | Green coat, connected orange guitar, neck, and open case | N/NE/E/SE/S authored; NW/W/SW mirror NE/E/SE* | Canonical asset live in `src/events/event_instance.gd`; named projections prepared |
| Poster crew | `poster_crew_{front,back,side,front_diagonal,back_diagonal}.svg` plus canonical alias | 30x44; (15,44) | Sage worker, elevated cream poster, red marks, paste bucket | N/NE/E/SE/S authored; NW/W/SW mirror NE/E/SE* | Canonical asset live in `src/events/event_instance.gd`; named projections prepared |
| Café sitter | `cafe_sitter_{front,back,side,front_diagonal,back_diagonal}.svg` plus canonical alias | 16x30; (8,30) | Seated torso and head with no standing legs; table remains caller-owned | N/NE/E/SE/S authored; NW/W/SW mirror NE/E/SE* | Canonical asset live in `src/events/event_instance.gd`; named projections prepared |
| Van victim | `van_victim_{front,back,side,front_diagonal,back_diagonal}.svg` plus canonical alias | 18x42; (9,42) | Slumped brown torso and lowered held posture | N/NE/E/SE/S authored; NW/W/SW mirror NE/E/SE* | Canonical asset live in `src/events/event_instance.gd`; named projections prepared |
| Robber, waiting | `robber_waiting_{front,back,side,front_diagonal,back_diagonal}.svg` plus canonical alias | 22x44; (11,44) | Dark hood, face void, hands-in-coat waiting silhouette | N/NE/E/SE/S authored; NW/W/SW mirror NE/E/SE* | Canonical asset live in `src/events/event_instance.gd`; named projections prepared |
| Robber, lunging | `robber_lunging_{front,back,side,front_diagonal,back_diagonal}.svg` plus canonical alias | 34x44; (17,44) | Same hood and palette; crouched legs, forward arms; rear view drives both arms forward | N/NE/E/SE/S authored; NW/W/SW mirror NE/E/SE* | Canonical asset live in `src/events/event_instance.gd`; named projections prepared |
| Protester | `protester_{front,back,side,front_diagonal,back_diagonal}.svg` plus canonical alias | 22x52; (11,52) | Brown protest body and elevated placard; pointing family remains the existing eight-view set | N/NE/E/SE/S authored; NW/W/SW mirror NE/E/SE* | Canonical asset live in `src/events/event_instance.gd`; named projections prepared |
| Gunman | `gunman_{front,back,side,front_diagonal,back_diagonal}.svg` plus canonical alias | 30x26; (15,26) | Low crouched actor, rifle direction and cover wall | N/NE/E/SE/S authored; NW/W/SW mirror NE/E/SE* | Canonical asset live in `src/events/event_instance.gd`; named projections prepared |
| Leaf blower | `leaf_blower_{front,back,side,front_diagonal,back_diagonal}.svg` plus canonical alias | 34x42; (17,42) | Yellow groundskeeper, blower body, hose and nozzle | N/NE/E/SE/S authored; NW/W/SW mirror NE/E/SE* | Canonical asset live in `src/events/event_instance.gd`; named projections prepared |
| Checkpoint guard, standing | `guard_standing_{front,back,side,front_diagonal,back_diagonal}.svg` plus canonical alias | 22x44; (11,44) | Green uniform, cap and badge stripe | N/NE/E/SE/S authored; NW/W/SW mirror NE/E/SE* | Canonical asset live in `src/events/event_instance.gd`; named projections prepared |
| Checkpoint guard, lunging | `guard_lunging_{front,back,side,front_diagonal,back_diagonal}.svg` plus canonical alias | 36x44; (17,44) | Same uniform, wide departing stride and extended arm | N/NE/E/SE/S authored; NW/W/SW mirror NE/E/SE* | Canonical asset available for checkpoint design; named projections prepared |

## Review notes

All 83 new SVG sources and their 83 Godot `.import` sidecars are present. The four diagonal
carrying frames include the mother's head/hair as well as the baby bundle; the busker's SE view
faces east with a shifted torso, connected guitar neck/body and grounded case; and the robber's
rear lunging pose is centered with both arms driving forward. No runtime source or canonical
asset was changed, and no PNG was generated or committed.

