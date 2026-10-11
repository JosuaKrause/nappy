"""Adds the stall rig's logging to a scratch checkout. Never applied to the branch itself.

usage: instrument.py <checkout> [--judgements]
"""
import sys

root = sys.argv[1]
judgements = "--judgements" in sys.argv


def patch(path, edits):
    p = root + "/" + path
    s = open(p).read()
    for old, new in edits:
        n = s.count(old)
        assert n == 1, (path, n, old[:80])
        s = s.replace(old, new)
    open(p, "w").write(s)


patch("src/events/event_director.gd", [
    ("var _crew_rng := RandomNumberGenerator.new()\n",
     "var _crew_rng := RandomNumberGenerator.new()\nvar looks := 0\n"),
    ("\t_since_the_last_look = 0.0\n\tif at.distance_to(",
     "\t_since_the_last_look = 0.0\n\tlooks += 1\n\tif at.distance_to("),
    ("\t\tvar sited := _siting.ahead_of(plan.def, rng, _everything_but(plans, plan), at, heading,\n"
     "\t\t\t\tband.x, band.y)\n",
     "\t\tvar _a0 := Time.get_ticks_usec()\n"
     "\t\tvar sited := _siting.ahead_of(plan.def, rng, _everything_but(plans, plan), at, heading,\n"
     "\t\t\t\tband.x, band.y)\n"
     "\t\tprint(\"ASK look=%d %s usec=%d sited=%s\" % [looks, plan.def.id, Time.get_ticks_usec() - _a0, sited != null])\n"),
])

judge_line = ("\t\tprint(\"JUDGE n=%d judgements=%d offers=%d\" % [_director.looks, EventScheduler.judgements, _siting.offers_worked_out])\n"
              if judgements else "")
patch("src/events/event_manager.gd", [
    ("func _physics_process(delta: float) -> void:\n",
     "var _bs_tick := 0\nvar _bs_site := 0\n"
     "func _physics_process(delta: float) -> void:\n"
     "\t_bs_tick += 1\n\t_bs_site = 0\n\tvar _e0 := Time.get_ticks_usec()\n"
     "\t_bs_physics(delta)\n"
     "\tprint(\"EVT tick=%d usec=%d site=%d\" % [_bs_tick, Time.get_ticks_usec() - _e0, _bs_site])\n\n"
     "func _bs_physics(delta: float) -> void:\n"),
    ("\tvar moved := _director.site_what_is_on_her_way(delta, body.global_position, body.velocity,\n"
     "\t\t\t_plans)\n",
     "\tvar _l0 := _director.looks\n\tvar _s0 := Time.get_ticks_usec()\n"
     "\tvar moved := _director.site_what_is_on_her_way(delta, body.global_position, body.velocity,\n"
     "\t\t\t_plans)\n"
     "\t_bs_site = Time.get_ticks_usec() - _s0\n"
     "\tif _director.looks != _l0:\n"
     "\t\tprint(\"LOOK n=%d tick=%d usec=%d pos=%s walk=%d crew=%d place=%d\" % [_director.looks, _bs_tick, _bs_site, "
     "str(body.global_position), _director._walk_rng.state, _director._crew_rng.state, _director._place_rng.state])\n"
     + judge_line +
     "\tfor _p in moved:\n"
     "\t\tprint(\"SITED tick=%d %s pos=%s path=%s facing=%s role=%d\" % [_bs_tick, _p.def.id, str(_p.position), str(_p.path), str(_p.facing), _p.role])\n"),
])
print("instrumented", root, "judgements" if judgements else "")
