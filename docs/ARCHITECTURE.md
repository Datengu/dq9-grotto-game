# Architecture — v0.3

Godot 4.6.3, compatibility renderer, original procedural 3D meshes, built-in UI. The gameplay/data layer from v0.1 remains; the obsolete 2D world renderer was replaced.

| Responsibility | Location |
|---|---|
| Transitions and rewards | `src/main.gd` |
| Scene/runtime coordination and actor registry | `src/world/exploration_world.gd` |
| Continuous capsule movement and animation driver | `src/world/explorer_actor.gd`, `actor_model.gd` |
| Perspective tracking and selective scenery fading | `src/world/follow_camera.gd`, `camera_occlusion.gd` |
| Party trail and navigation | `src/world/follower_trail.gd`, `grid_navigation.gd`, `surface_navigation.gd` |
| Visible enemy state machine | `src/world/enemy_brain.gd` |
| Local runtime population and eligibility | `src/world/encounter_population.gd`, `src/core/content.gd`, `data/encounters.json` |
| Original world meshes/materials | `src/world/geometry_3d.gd`, `hub_geometry.gd`, `dungeon_geometry.gd` |
| Atlas, quests, inventory, combat and service screens | `src/ui/game_ui.gd` |
| Optional discovered map | `src/ui/cartography_overlay.gd` |
| Character/equipment/atlas records | `src/core/game_state.gd` |
| Validated saves and backup recovery | `src/core/save_store.gd` |
| Quests, combat, content and loot | `src/core/quest_system.gd`, `combat.gd`, `content.gd`, `loot_system.gd` |
| Metadata, version dispatch and fixed integer RNG | `src/generation/grotto_generator.gd`, `seed_rng.gd` |
| Frozen old floor generation | `src/generation/floor_generator.gd` |
| Growing room graph with cropped footprint | `src/generation/floor_generator_v2.gd` |
| Tuning/content | `data/*.json`, especially `exploration.json` and `balance.json` |

## Lifetimes

**Chart identity:** immutable generator version, seed and final quality identify a chart. Codes are `LA1-<hex seed>-<quality>` or `LA2-<hex seed>-<quality>`. Base quality records acquisition provenance. Names are not keys; different final qualities in one bracket can produce the same structure. A chart is never replaced by a new generator silently.

**Player knowledge:** visits, deepest floor, clears, observed monsters/treasure, favourites, notes and explored floor sketches. Fog now survives expeditions and save/load. Loaded charts reproduce their original geometry.

**Expedition state:** opened chests and keeper completion persist while backtracking, then reset for a new expedition. Roaming enemies have unique runtime IDs and metadata-derived eligibility; a local population manager samples connected navigation positions and removes distant actors. Defeated IDs suppress only those actors; fresh populations use new IDs on floor re-entry. Generated legacy spawn records remain immutable but do not instantiate the runtime population. Battle and loot random streams are independent of floor generation. Every chest and keeper pays once per expedition.

**Scene:** meshes, colliders, actors, follower trail, camera and UI. Physical actor positions are continuous and never change immutable generated floor data. Floor collision and AI navigation derive from that data. The dungeon bounding rectangle is an internal array bound, not a rendered board.

**Timing:** simulation and actor movement run in physics ticks. Godot interpolates actor transforms for rendering; the independent world-space camera follows that interpolated transform in its render callback with its own automatic interpolation disabled. Spawn/teleport paths reset interpolation. Doorway transitions are deferred outside physics mutation and backed by collision plus safe-position containment.

## Generation and save compatibility

Generator v1 remains byte-for-byte protected by three known geometry fingerprints. V2 grows a connected graph in unbounded integer coordinates, connects chambers, optionally adds loops, then crops to actual occupied extents. Quality bracket and floor depth affect room-count and corridor-length distributions. Rare small high-quality and large low-quality layouts remain possible. Its own three fingerprints freeze issued v2 charts. Metadata generation and quality/chest rules remain common immutable definitions; future incompatible changes require a new version and dispatch path.

Save format 2 accepts formats 1 and 2 and both generator versions. Migration adds missing explored knowledge, preserves map metadata and clamps HP/MP to the rebalanced capacities. Character XP, levels, equipment, inventory, quests and money survive. Existing XP already accumulated is retained, so an older character may level after its next XP reward. Loading resumes in town; this is not an expedition suspension system. Unknown versions fail explicitly and leave files preserved.

## Co-op preparation, without networking

Actors carry stable IDs and roles, and enemy decisions accept an actor registry. AI selects a player actor rather than a hardcoded global hero. `authority_enabled` gates enemy decisions; `snapshot()` exposes a runtime tick, map/floor identity, actor positions, enemy state and expedition flags separately from seeded geometry. These are boundaries for future host authority, not a complete replication protocol. Network transport, command validation, ownership, reconciliation, remote movement and multi-character combat are not implemented. Combat and durable saves still belong to the current local campaign.

## Extension points

NPC services/routes remain data records. Quests consume events; more specific target IDs can be added as needed. Materials retain their future crafting role. Actor models can be replaced with rigged assets without changing movement. Split atlas/shop/combat UI into dedicated modules as those screens grow. The controller orchestrates these systems rather than calculating generation, AI or damage itself.
