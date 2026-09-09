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

## #4 — local encounter population

`EncounterPopulation` decides which runtime actors to spawn/despawn independently of the immutable generated floor. Eligibility comes from environment, floor rank (already derived from grotto quality and descent), and the Lumen-colony restriction. Keeper chambers remain free of roaming spawns. Existing generated enemy arrays stay in the versioned data for compatibility but no longer instantiate permanent actors.

`data/encounters.json` controls the four-enemy cap, local walkable-area density, 9–18 m spawn annulus, 26 m despawn distance, two-second refill interval, spacing and seven-second post-battle refill pause. Candidates must be connected on the navigation surface, separated from actors/stairs/chests, and outside direct camera visibility where practical. Sparse/compact areas can stay below the cap when no hidden valid candidate exists. This is an approximation of the requested DQIX population model, not a claim to reproduce its undocumented constants.

Encounters have runtime IDs and descriptors; battle creation reads these instead of indexing a generated spawn list. IDs remain unique across floor changes, so defeated actors from an earlier visit cannot suppress a new population. Population decisions accept an actor list; future multiplayer authority remains separate from the deterministic generator.

Targeted population validation observed nine spawns while traversing a large floor, with zero cap, radius, visibility or eligibility violations. It verifies distant actor removal, replenishment, biome/rank pools, unusual restrictions, no keeper-room population, unchanged generated data and a fresh runtime population on replay. The integrated rendered source expedition also passed, including contact encounters, keeper rewards, quests, replay and save/load.

## Interruption recovery — 9 September 2026

Recovered `codex/foundation-transitions-motion` at `3a3a36c`, with exit work committed in `4bf3eb7`, no staged changes, and the population/validation work preserved as local changes. GitHub still had all eight issues open and unchanged; `origin/main` remained v0.2. #1–#3 were implemented, #4 implemented but uncommitted, and #5–#8 untouched in this pass.

The interrupted Windows validation export had passed doorway, population and physical exploration assertions, but failed migration writes and screenshot capture because tests used packaged `res://` output paths. `TestOutput` now selects a writable absolute output directory beside the validation executable. This was a test-harness failure; production saves use their existing user-data location. The separate validation preset runs the same SceneTree assertions in the release engine; ordinary exports exclude tests and retain normal startup. Export validation now checks process results and script errors, including failed captures. Final evidence and issue disposition will be recorded after the remaining gates.

## Final validation — focused v0.3 playtest

- Full source suite: 1,000 grottos, 10,598 floors, **249,685 checks, zero failures**. Generation distributions match the v0.2 baseline; no generator or metadata algorithm changed.
- Balance: 4,000 individual simulated battles plus 200 starter-expedition trials pass the existing expectations. Attack-only cleared 0/100 ten-encounter starter expeditions; the prepared tactical policy cleared 100/100. These are retained benchmarks, not a new resolution of #6.
- Source and release-engine doorway checks: all five interiors, straight and diagonal approaches, correct outward return, deliberate E services, missing transition listener and bounds recovery pass.
- Navigation: 240 generated v1/v2 floors pass surface reachability and arbitrary endpoint checks. A real EnemyBrain/CharacterBody follows a 27 m wall detour, arrives at an arbitrary destination, has bounded per-tick steps and spends most movement samples between grid axes. Detection, pursuit expiry, disengagement and alternate player IDs pass.
- Population: nine observed spawns across a traversed floor, zero cap/spawn/visibility/eligibility violations, distant removal, replenishment and immutable replay pass in source and Windows release engine.
- Rendered release-engine expedition: **3,989 movement frames, eight battles, three retained maps**, ending at level 3 with 75 HP. Physical board, purchases/equipment, automatic exit, atlas departure, wandering/chasing contact encounters, three floors, acknowledged chests, keeper reward, quest claims, home return, same-map replay and save/load all pass. QA drives ordinary character commands and UI buttons, without stat/supply boosts.
- A read-only copy of the user's existing v0.2 campaign loads and traverses its first chart in source and release engine, then saves/reloads separately. All six chart identities and inventory remain; the input file hash is unchanged. Actual save contents are excluded from Git and build packages.
- Nine real-time release-engine motion probes pass: hub and grotto at 30/60/144 FPS caps with 60 Hz physics, both at 144 FPS with deliberately reduced 10 Hz physics, and an interior at 60 FPS. Each includes a turn after its steady-walking sample. Zero frozen rendered-position frames; steady speed stays 4.4 m/s; screen-step standard deviation is below 0.1 px. These measurements sample after drawing and use the engine's render delta for transform cadence.

The first wall-clock speed threshold produced a false failure when host/GPU scheduling delayed a post-draw callback and bunched the next one (29 ms then 4 ms), despite equal rendered transform steps and stable camera offset. Raw timestamps and wall-clock variability remain recorded; the test now checks transform cadence and screen-space movement, rather than pretending to benchmark OS scheduling. This does not promise frame pacing on every GPU or under external load.

The normal production export was launched separately and visually inspected in Bellwether. Rendered expedition frames were reviewed for interiors, rooms/corridors, keeper, chest feedback, existing-save traversal and the current combat overlay. Desktop input automation encountered concurrent local input, so hands-on input coverage is limited; the complete loop above is a scripted physics/UI playthrough with visual review, not an extensive human playthrough. User testing should concentrate on sustained walking/turning, diagonal doorway crossings, pursuit around corners and population density over several expeditions.

Machine-readable reports are in `docs/validation/v0.3`. Reproduce the source suite with `scripts/run-tests.ps1`; `scripts/test-exported.ps1` builds/runs the separate release validation preset. Use `-MotionOnly` for targeted cadence probes and `-ExistingSave <copied-save-path>` for optional continued-campaign coverage. Generated screenshots, raw traces and private save fixtures remain ignored. Normal saves use the established user-data folder; validation writes beside its own executable.

Scope: #1–#4 are the completed implementation/validation body. #5–#8 remain open. No new battle presentation, content, balance rules, generation version, networking or speculative co-op implementation was added. Compact areas can temporarily have fewer than four enemies when no hidden navigable spawn is available. Background host certificate-store warnings remain unrelated to this offline game's script/runtime checks.
