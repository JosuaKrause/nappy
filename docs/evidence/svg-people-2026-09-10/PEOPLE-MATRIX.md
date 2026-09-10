# M108 — Eight-direction people SVG review

The sheets show current editable SVG sources at native scale and at exactly 3x, over opaque
neutral ground. No picture is fitted to its cell. The eight-facing sheets show each authored
projection and the explicitly permitted west mirror; crosses mark the drawing anchor.

| Review group | Eight facings | Individual SVG sources |
|---|---|---|
| Crowd walker, carrying mother and chatting mother | [Native](people-rig-1x.png), [3x](people-rig-3x.png) | [Native layers](people-rig-sources-1x.png), [3x layers](people-rig-sources-3x.png) |
| Dog-walker person, yeller, busker, poster crew, café sitter, van victim and protester | [Native](people-street-1x.png), [3x](people-street-3x.png) | [Native sources](people-street-sources-1x.png), [3x sources](people-street-sources-3x.png) |
| Robber, gunman, leaf blower and checkpoint guards | [Native](people-actions-1x.png), [3x](people-actions-3x.png) | [Native sources](people-actions-sources-1x.png), [3x sources](people-actions-sources-3x.png) |

[The existing protester pointing poses](people-pointing-native-and-3x.png) show all eight
action directions at native and 3x scale. These are eight unchanged authored sources,
`events/protester_point_{n,ne,e,se,s,sw,w,nw}.svg`, with 44×52 canvas and (22,52) feet anchor.
Their suffixes name the pointing arm's direction; the protester remains front-facing.
They are prepared for M65, a protester points at the objective.

## Direction and registration

N uses `back`, NE `back_diagonal`, E `side`, SE `front_diagonal`, and S `front`.
SW, W and NW mirror SE, E and NE respectively around the stated drawing anchor.
All people stay upright. These mirrors preserve the silhouette and event identity; handedness is
not a gameplay property, and the paper markings are abstract strokes rather than readable text.
No rear paper face carries the front's printed marks.

Paths in the table are relative to `assets/`. In every row, `{view}` expands to
`front`, `back`, `side`, `front_diagonal` and `back_diagonal`.

| Family and states | Authored paths | Native canvas; drawing anchor | Identity and layer order | Binding |
|---|---|---|---|---|
| Crowd walker | `crowd/walker_{view}_{body,trim}.svg` | 18×38; (9,38) | Tintable coat body first, untinted head/hands/legs/shoes above. Composed sheets use sage coat tint. | Cardinal body/trim sources are live; diagonals are prepared. |
| Mother carrying, gait a/b | `rig/mother_carrying_{view}_{a,b}.svg` | Front/back 24×46, (12,46); side/diagonal 26×46, (13,46) | Rust coat and navy wrap; arms support the baby. Rear torso and near arm occlude most of the bundle. | Prepared for M102, the finale. |
| Chatting mother, walking | `events/chatting_mother_walking_{view}.svg` | 54×46; (27,46) composite | Sage mother, tan pram, joined handle and visible wheels. Northward pram sits behind the mother; southward pram overlaps her lower body. | Named views prepared; unsuffixed walking source is live. |
| Chatting mother, talking | `events/chatting_mother_talking_{view}.svg` | 54×46; (27,46) composite | Same pram and posture registration, with raised conversation arm and visible mouth where facing the viewer. | Named views prepared; unsuffixed talking source is live. |
| Dog-walker person | `events/person_{view}.svg` | 18×42; (9,42) | Blue coat, hands and trouser legs; dog and lead remain separate caller-owned elements. | Named views prepared; unsuffixed person is live. |
| Yeller | `events/yeller_{view}.svg` | 26×44; (13,44) | Long brown coat, beard, open mouth and raised arm; rear body hides the face. | Named views prepared; unsuffixed source is live. |
| Busker | `events/busker_{view}.svg` | 30×44; (15,44) | Green coat, orange guitar and open case. Guitar narrows side-on; rear torso hides most of it and shows the shoulder strap. | Named views prepared; unsuffixed source is live. |
| Poster crew | `events/poster_crew_{view}.svg` | 30×44; (15,44) | Sage overalls, paper held aloft, brush and paste bucket. Paper has distinct front, edge and blank rear planes. | Named views prepared; unsuffixed source is live. |
| Café sitter | `events/cafe_sitter_{view}.svg` | 16×30; (8,30) | Mauve torso and blue lap, bent arm, no standing legs. Table and ground relationship remain caller-owned. | Named views prepared; unsuffixed source is live. |
| Van victim | `events/van_victim_{view}.svg` | 18×42; (9,42) | Brown slumped torso, lowered head and held upper arm. | Named views prepared; unsuffixed source is live. |
| Robber, waiting | `events/robber_waiting_{view}.svg` | 22×44; (11,44) | Dark hood and coat, hands within coat; face opening is hidden from rear views. | Named views prepared; unsuffixed waiting source is live. |
| Robber, lunging | `events/robber_lunging_{view}.svg` | 34×44; (17,44) | Same hood, departing stride and reaching arm. Front reach extends down the picture; rear reach projects above the shoulder; side and oblique reaches project outward. | Named views prepared; unsuffixed lunging source is live. |
| Protester | `events/protester_{view}.svg` | 22×52; (11,52) | Brown clothing and raised placard, with projected paper and blank reverse. | Named views prepared; unsuffixed source is live. Existing eight `protester_point_*` poses remain available. |
| Gunman | `events/gunman_{view}.svg` | 30×26; (15,26) | Low uniformed shooter; rifle and cover share the firing axis. End-on barrel is foreshortened; cover occludes the shooter according to view. | Named views prepared; unsuffixed source is live. |
| Leaf blower | `events/leaf_blower_{view}.svg` | 34×42; (17,42) composite | Yellow workwear and cap, supported blower unit and directional nozzle. Tube shortens end-on and is partly hidden from rear views. | Named views prepared; unsuffixed source is live. |
| Checkpoint guard, standing | `checkpoints/guard_standing_{view}.svg` | 22×44; (11,44) | Green uniform, cap and front breast stripe, with projected shoulders and sleeves. | Named views prepared; unsuffixed source is live. |
| Checkpoint guard, lunging | `checkpoints/guard_lunging_{view}.svg` | 36×44; **(17,44)** | Same uniform with wide stride and directional reach. Mirrors use the off-centre anchor, not canvas centre. | Prepared for M56, the checkpoint hunting posture. |

Composite anchors register the whole picture, rather than the anatomical centre of a person.
The pram, case, cover and blower retain their native footprints; these sources do not redefine
collision, caller-drawn shadows or route obstruction. Ground contact follows the authored depth
of each object, so far wheels and feet can sit above the drawing anchor.

## Source review and verification

The reviewed inventory contains 95 SVG sources: 83 directional additions and 12 existing
cardinal crowd/carrying sources, plus the separate eight-source pointing action family.
Each has its Godot `.import` sidecar. The source sheets expose
all individual layers; the facing sheets additionally verify tinted crowd composition and
west mirrors for every state, including both carrying gait frames.

Every current source is parsed as XML and rasterized directly using Godot
`Image.load_svg_from_string(source, 1.0)` and `Image.load_svg_from_string(source, 3.0)`.
The saved RGBA images are alpha-composited over `#c9c3b3` with filename and direction labels.
Native sheets establish scale and recognition; 3x sheets establish joins, overlap and clipping.
The review uses the current source files, including the original cardinal carrying and crowd
frames, without reusing illustrated textures.

The chatting mother's tan pram reuses the corresponding authored player-pram projection geometry,
with the event's tan/brown palette. The front/diagonal view shows the baby beneath the hood;
the rear hood hides the baby. Mother and pram remain a single 54×46 event source.

`./tools/check.sh` imports and boots the checkout headlessly. `./tools/lint.sh` validates
tracked XML and current documentation. This is source-art evidence: no runtime heading selector
or gameplay behavior is added, and there is no illustrated PNG conversion. The PNG files here
are review sheets only. Unsuffixed canonical event/checkpoint assets remain unchanged.
