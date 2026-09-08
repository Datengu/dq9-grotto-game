# Foundation work toward v0.3

Baseline: local and GitHub `main` at `d93df33` (v0.2). Live issue bodies #1–#8 read on 8 September 2026; all open, no open PRs or issue comments. Work proceeds on `codex/foundation-transitions-motion`. No duplicate issues or generator reset.

## #2 — interior exits

Reproduced by walking straight from the weapon-shop entrance through the visible opening, without pressing E. The original actor fell to y = -121.31 in four simulated seconds. The old playthrough only approached the E interaction, so it missed this route.

The doorway now detects crossing before the edge, queues one transition outside physics mutation, returns to the correct building facing outward, and keeps deliberate interactions on E. An invisible collision backstop and last-safe-position bounds recovery prevent falling even if transition handling fails. Scene changes clear pending transitions safely.

Regression tests exercise all five buildings from straight and diagonal approaches, correct return positions/orientation, a disconnected transition listener, forced out-of-bounds recovery and normal shop interaction. The walking probe now exits with a lowest y of -0.014, consistent with the collision margin. Exported and visual validation are recorded as work progresses; implementation alone does not close an issue.

## #1 — physics/render timing

The v0.2 actor and limb transforms advanced only at physics ticks, while the render-frame camera read the current physics transform. Automatic interpolation was disabled. Enabling actor interpolation, following `get_global_transform_interpolated()` from the world-space camera, disabling interpolation on the camera itself and resetting interpolation after placement corrects the timing mismatch. Existing movement rates and smoothing strength are unchanged.

A live 144 FPS-cap sample (60 physics ticks) changed from 75 frozen actor-position frames among 129 sampled differences to zero. Rendered horizontal speed standard deviation fell from 4.92 to 0.23 m/s; screen-step standard deviation fell from 2.64 to 0.42 px. These initial traces sampled before node render callbacks, so screen-step numbers are diagnostic rather than a final image-jitter threshold. Follow-up probes sample after frame drawing and include 30/60/144 FPS caps and a deliberately low 10 Hz physics case.

Implementation follows the [Godot camera interpolation guidance](https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/advanced_physics_interpolation.html). Physics/gameplay still uses authoritative physics transforms; interpolated transforms are only for presentation.

## #3 — continuous navigation

Dungeon AI now uses a Recast-baked 3D navigation surface with radius clearance and funnel paths. Wander endpoints are arbitrary sampled points on that surface, and pursuit targets actual actor positions. The generation grid remains a floor definition and line-of-sight lookup, not a stream of tile-centre movement destinations. Idle, wandering, pursuit, returning, encounter contact and escape grace remain separate from chart identity.

Testing caught two integration problems: a map could report a first iteration before its region was available, and coarse corner clearance could lead an actor into a wall. Readiness now checks both region and map; baking uses conservative radius clearance and tighter contour error. Source faces are generated directly on the CPU. Navigation checks cover entrance-to-stair routes across 240 v1/v2 floors and preservation of arbitrary endpoints. The actual physics/UI expedition passes with five encounters. These tests do not change any issued chart geometry or metadata.
