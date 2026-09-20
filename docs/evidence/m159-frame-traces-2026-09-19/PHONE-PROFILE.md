# Phone CPU attribution preparation

There is no phone measurement in this record. Device discovery on the host returns no connected
device, and the desktop baseline repetitions do not establish enough stability for small toggle
comparisons. The atlas JSON measures the native Apple M2 build. It cannot supply phone category
shares, browser WebGL costs or threadless atlas timing.

## Connection and comparable-run gate

Use the phone browser that exhibits the problem, with its model, OS, browser version, orientation,
viewport, display refresh, power state and temperature context recorded. Keep the current Web
export's `variant/thread_support=false` and `gl_compatibility`; a native mobile export measures
a different execution environment. Record the tested commit and debug/release build mode.

`./tools/serve-web.sh 8060` exports the project's debug Web preset and serves its files. A
browser profiler can attach to that page through the phone's remote browser debugging tools.
Its main-thread timeline separates browser/JavaScript/WASM execution from compositor and GPU
activity, but an unsymbolized WASM stack does not name GDScript functions. Do not infer the five
script categories below from such a stack.

For GDScript function timing, connect this debug export to the native Godot editor's debugger.
The installed Godot accepts `--debug-server <uri>` and `--remote-debug <uri>`; the
[engine's WebSocket module](https://github.com/godotengine/godot/blob/4.7/modules/websocket/register_types.cpp)
registers `ws://` for the editor server and `ws://`/`wss://` for clients. The
[Web startup API](https://github.com/godotengine/godot/blob/4.7/platform/web/js/engine/engine.js)
passes `EngineConfig.args` to the engine and accepts startup configuration overrides.

The connection recipe to validate with a device is:

1. Start the native editor for this checkout with `--editor --path . --debug-server
   ws://0.0.0.0:6007`, and keep its debug server open. Use a trusted local network and the
   laptop's LAN address on the phone; `localhost` on the phone names the phone.
2. Serve the debug export with `tools/serve-web.sh`. In the generated, ignored
   `build/web/index.html` only, set the engine configuration's `args` before engine startup to
   `["--remote-debug", "ws://LAPTOP_LAN_IP:6007", "--", "--frame-trace", "--after", "12",
   "--no-title", "--seed", "4242", "--walk", "3s2e2w2e2w1e", "--no-telemetry"]`.
   Replace the address with the actual laptop address. Preserve the exact generated-page patch
   beside the result. The local server uses HTTP and the existing threadless preset; an HTTPS
   page needs a compatible secure debugger transport instead of mixed-content WebSocket traffic.
3. Verify the editor identifies the phone's debug session and lists real script functions before
   recording a result. A page that merely renders, a desktop browser session, or a profiler with
   no script rows does not pass this connection gate. This connection recipe is not device-tested
   in the present evidence. Do not deploy the diagnostic HTML.
4. First repeat the same phone route with the profiler stopped. Require the full active window
   and repeatable baselines before toggles. Then repeat with profiler autostart enabled, retaining
   the same five-second warmup and six-second comparison window. Keep the debugger connection,
   readout, graph, telemetry, seed and inputs identical across this overhead comparison. Keep
   ordinary loss and meter behavior enabled; no screenshots, bursts or invincibility.

The [Godot profiler](https://docs.godotengine.org/en/stable/tutorials/scripting/debug/the_profiler.html)
is disabled by default because it adds work. Its Frame Time measure differs from Average Time
per call; Inclusive includes callees and Self excludes them. Retain both views and call counts
for the selected frames. Do not add inclusive parent and child costs together. An instrumented
slowdown is part of the measurement report, not a shipping regression or an optimization win.

## Call-site map for ordinary city play

| Requested category | Current function to inspect | Attribution boundary |
| --- | --- | --- |
| Baby's crowd contribution sweep | `Crowd.excitement_sources_at()` in `src/crowd/crowd.gd`, reached through `Baby._update_excitement()` → `City.excitement_sources_at()` | Inclusive sweep contains all agents' `contribution_at()` calls. With telemetry disabled this route has the baby's caller; telemetry's `total_excitement_at()` otherwise adds another sweep. `Baby._physics_process()` is broader meter/sleep work, not the crowd-only cost. |
| Halo's rendered-frame source sweep | `ExcitementHalo.select_sources()` in `src/ui/excitement_halo.gd` | Includes live event and crowd contribution queries and ranking; its parent's `_process()` also updates halo states. Shared `CrowdAgent.contribution_at()` totals alone cannot distinguish halo from baby. |
| Event streaming and director | `EventManager._physics_process()` in `src/events/event_manager.gd`; its `stream_around()`, `_retire_finished()`, `_place_what_is_owed_ahead()` and `_summon_the_sighted_row()` family | Inspect individual child functions and `ResistanceDirector._process()` separately. The whole manager tick also checks detentions, hard failures and other event rules. |
| Crowd movement and traffic | `CrowdAgent._process()` in `src/crowd/crowd_agent.gd`, plus `Crowd._physics_process()` and `space_out_the_traffic()` in `src/crowd/crowd.gd` | Per-agent motion is rendered-frame work; queue/signal processing is physics work. Do not count a traffic child twice beside its inclusive parent. |
| Debug presentation | `Main._process()`'s readout branch; `FrameCost.sample()`/`readout_lines()`, `Main._nearest_event_text()`, `FrameGraph.push()`/`_draw()`, `DebugLayers._process()`/`_draw()` | `Main._process()` also collects atlases, updates daylight and handles phase state, so its whole time is not a debug cost. Compare layers only after repeat baselines stabilize. Native text/render work can sit outside script rows. |

Keep engine physics, rendering/browser work and remaining scripts as explicit residuals. These
five categories do not partition the entire frame, and the profiler's function totals do not
provide a caller-specific split for every shared helper. If one remaining mixed function dominates,
the next instrument is one bounded timing span around that whole call site, not a timer in each
agent's contribution query.

## Artifact and decision gate

Save the profiler CSV and a small companion record containing the source commit, browser/device
metadata, exact launch configuration, warmup/window boundaries, profiler frame range, call counts,
and whether profiling is enabled. Godot's
[CSV exporter](https://github.com/godotengine/godot/blob/4.7/editor/debugger/editor_profiler.cpp)
writes inclusive function totals in seconds and omits frame-number/call-count columns; record the
selected frame range and counts separately rather than treating CSV row numbers as engine frame
IDs. Preserve the browser timeline too if it supplies the rendering/residual side of the split.
Export artifacts after recording, without a gameplay capture. Require populated artifacts with
the expected script names before calling the phone attribution complete.

If contribution sweeps are material on the phone, a later squared-distance rejection experiment
must preserve horn/startle reach and maximum forward stretch and show identical meter attribution.
No caching, tick-rate change, atlas residency policy or pacing setting follows from the host
measurements in this directory. The atlas record also needs actual threadless execution, release
events and memory evidence before comparing policies.
