# azure-hawk — Two kinds of charge: no badge for a charger already in the world, and every charger audited · 2026-11-25 · not from an entry

Built straight from the player's note #1774 (bouncy-owl), filed in the same pull request: there are
two kinds of charge. An off-screen charger shows up with a screen-edge badge, then enters the
screen already charging, always. An on-screen charger shows no badge, gives its warning when she
comes too close, and then may charge under the rules already set. The player said the rule was
already recorded: teal-trout (every charger is neutral, then warns, then charges; velvet-marten
#699), its scope call that a pursuer arriving already charging falls outside that three-stage rule
(velvet-marten #705), and a thing from off screen warned first under its badge and then placed just
off screen (calm-kestrel #559; busy-quail #569). #1774 restates it.

## What it overturns

tawny-wombat (PR #1759) gave a charger already in the world a badge whenever its charge began with
none of it in her sight (`EventInstance._begin_the_charge()` setting `_charged_out_of_sight`, read
through `was_warned_of()`): the orchestrator's pick on the board question
badge-for-chargers-off-screen, made when deleting the badge's old measuring took away the badge
every charger had when it closed on her from out of her sight. That pick went against the recorded
rule: such a charger is an on-screen one and never shows a badge. Deleted with it: the flag,
`_begin_the_charge()` (the figure's `charge_began()` now tells `ChargeRecord.begin()` directly)
and `_is_in_her_sight()`, which only it read. `tests/test_events_pursuit.gd`'s case for it now
pins that the man a vehicle lets out raises no badge whether his charge begins in her sight or
after she has walked 420px away (it fails on main, where the second case raised one).

## The audit

Every charger in the catalogue and the escape, by the kind its way into play makes it:

| Charger | Kind | How it comes, and its warning | Verdict |
| --- | --- | --- | --- |
| `charging_dog` placed on the map, past day 3 | on screen | Notices her inside its radius only with its whole warning picture in the camera's view (`_would_stand_in_her_view()`), warns 1.75s, charges if she stays | fits |
| `alley_robbery`, the chalk-mark guard (the same row), day 13's waiting `task_guard` | on screen | The same view-gated radius warning | fits |
| `roadblock`'s hunting guard, a day's and the escape's (`escape_roadblock()`) | on screen | The same, with the guard at his post on her side as the warning picture (`warning_guard_rect()`) | fits |
| Day 13's task guard set on her by the done task | on screen in her view, off screen out of it | In view, his hand raised for 1s, then a charge; out of view, retired unseen and sent as `task_guard_sent` under a badge, arriving charging (`ResistanceDirector._set_the_task_guard_on_her()`) | fits |
| The men an investigating patrol car, a hunting unmarked van or a hunting night raid lets out | on screen | Hand raised for 1s where he got out, then a charge whatever she does | **fixed**: the vehicle stopped for her on distance and a clear line alone, and its notice (187.5px for the patrol, 225px for the vans, at the shipped charger reach) is past the view's 180px half-height, so a man could get out, raise his hand and charge all out of her sight. With tawny-wombat's badge gone he would have fit neither kind. A vehicle now stops only where it and its men at its door would stand whole in her view (`EventInvestigation`, `EventInstance._would_stand_in_her_view()`); `tests/test_heat.gd`'s `_test_a_hunting_van_lets_its_men_out_only_in_her_view` fails without the check. A man who raised his hand in view and whose charge begins after she walked out of it carries no badge: he warned her on screen |
| `door_guard` at a checkpoint door | on screen | The guard of the hut across the road, or the alley post's, raises his hand from the frame she crosses the door's line; he steps out and charges only if she stays across | fits; no code gates it on the view, since the hut stands across the road from the line she crosses |
| `masked_pursuer` on the escape's stairs | off screen | Set off by a place: his badge, then he exists out of her sight at the foot of his shaft, running his line from his first tick | fits |
| The day-3 `charging_dog`, and the dogs sent the same way later | off screen | Half-second badge, then created just out of sight on its running approach at her | fits |
| `robber_giving_chase`, `van_guard_giving_chase`, `policeman_giving_chase`, `guardsman_giving_chase`, `task_guard_sent` | off screen | Badge alone, then created just out of sight arriving chasing (`ARRIVES_CHASING`) | fits |
| `military_convoy`: day 13's column, a convoy sent ahead of her, the escape's trucks | off screen | Badge, then created out of sight in the lane beside her, already driving | fits; only a developer's authored scene places one with no badge |

Not chargers, so outside the two kinds: `loose_dog` (runs down her sidewalk with no pursuit and does
not telegraph its coming, PLAYTEST-145 20), `cat_dash`, `cyclist` and `fire_truck` (warned first,
not pursuers), the patrol car and the vans themselves (a car never charges; a parked van takes her
only at its core), `reversing_lorry`.

## Weighed

- **The vehicle's view test** asks for its whole drawn box and its men's raised hands at its door on
  her side, widened along its flank by the spacing two men get out at, all inside the view. The
  plainer test, the vehicle's own box alone, can leave a man standing past the view's edge beside
  a low car. A man's picture is the guard's raised hand (`EventFootprints.raised_hand_size()`),
  which every man let out draws.
- **The vehicle latches having seen her** (as before) and now stops at the first frame it is also
  clear of a junction box and in her view, so a car that saw her out of view drives on until both
  hold.
