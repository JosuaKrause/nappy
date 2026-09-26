## M153 — The spike view is its own debug layer · built 2026-09-15

*(2026-09-15, [PLAYTEST-76](../playtests/PLAYTEST-76.md): "spike view should be independent of
debug layer 4 it should be its own debug layer and turned off by default unless --spikes is
set" — "spike recording should only be on while the layer is on. that means toggling the layer
twice will lead to a blank frame array".)* Two agent commits on `feature/m153-spike-layer`,
reviewed on the PR.

**What it is.** The frame-time graph (M148) has its own key, `6`, and its own switch,
`_layer_graph_on`, false by default and true at boot under `--spikes` or when `--layers` names
`6`; `parse_layers()` accepts one to six and still refuses `4`, which no flag reaches. `4` and
`_set_readout_visible()` no longer touch the graph, and its ring is pushed above the readout's
own early return, so a readout toggled off no longer silences a graph toggled on. The graph
is still built only where the readout is. Turning the layer off empties the ring
(`FrameGraph.clear()`), so `6` twice starts from a blank graph; the title screen hides the graph
as it hides the readout and shows it again on the disc with the ring intact, since the
independence asked for is from the `4` key and not from the title. The run log's `spike` line
stays on `--spikes` alone (M144), read as not what "recording" named; overturn it there if it
was. `docs/TELEMETRY.md` lists six layers and `README.md`'s `--layers`, `--debug` and
`--spikes` rows follow. The agent's choices, open to overturn: `--layers 6` starts the layer on
rather than merely being accepted, the way `5` starts the route lines; and the sixth key's
entry in the debug-layer suite now answers `6` where it asserted nothing, with `7` taking the
role of the key that answers nothing.
