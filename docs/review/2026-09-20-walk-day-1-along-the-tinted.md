**Walk day 1 along the tinted kerbs and look at both sides of every street.** Any body that
leaves her less than 28px of lane is a wall by fit — the café tables, the market stall, the
roadworks, the ice cream van and the parked van — so none of them stands on the sidewalk the
route walks, and they are drawn to the far side of that same street. The walked side carries
the dog walker, the shouting man, a playground and the poster crew, who stand against the
building and leave the curb side free. Turn on `5` for the route lines, since the curb tint marks
both sides: **is there anywhere a body on the purple line's own sidewalk cannot be walked
past?** `tools/run.sh --seed 129420 --day 9` had a van closing the walked sidewalk at tile 90,74
before the rule. Record is `DECISIONS.md`, M129, no body closes the walked sidewalk. **On a
square, the poster crew pastes onto a free-standing advertising column**
(`tools/run.sh --seed 4242 --day 11 --spawn event:poster_crew_square --no-save` stands her by
one): does it read as an advertising column, is it too short beside the man, and can she
walk into the drawn column, which is not solid — only the worker is? Two more
questions a rig cannot answer. **Is the far side visible enough to
be the answer** — a wall across the road is only a route decision if she can see it before she
commits to the side she is on. And **does the shouting man read as something to time** rather
than as a thing in the way: he stays on the route because his beat reaches the crossing at the
junction, so the answer to him is to walk on while he paces away, or to cross where his beat
ends. `tools/run.sh --seed 4242 --day 1`, layer 5 for the routes and layer 4 for the readout.
