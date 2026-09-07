# Architecture

Godot 4.6.3, GDScript, compatibility renderer and built-in UI/font rendering. No external runtime dependencies. Drawing code creates original geometric figures.

| Responsibility | Location |
|---|---|
| Transitions and reward orchestration | `src/main.gd` |
| Movement, collision, hub, interiors, dungeon drawing | `src/world/world_view.gd` |
| Atlas, quests, shops, inventory, battle controls | `src/ui/game_ui.gd` |
| Creature portraits | `src/ui/creature_portrait.gd` |
| Character, equipment, atlas records | `src/core/game_state.gd` |
| JSON validation, replacement, backup recovery | `src/core/save_store.gd` |
| Quest acceptance, events, claims | `src/core/quest_system.gd` |
| Combat turns | `src/core/combat.gd` |
| Content and enemy stats | `src/core/content.gd`, `data/*.json` |
| Weighted loot | `src/core/loot_system.gd` |
| Metadata and progression quality | `src/generation/grotto_generator.gd` |
| Floor geometry | `src/generation/floor_generator.gd` |
| Stable integer RNG | `src/generation/seed_rng.gd` |

## Three lifetimes

**Chart identity:** generator version, seed, final quality and immutable metadata. Share code: `LA1-<hex seed>-<decimal final quality>`. Base quality is acquisition provenance. Seed plus bracket controls structure; different qualities in one bracket can produce identical structures. Names are not unique and are never keys.

**Player knowledge:** visits, clears, depth, observed inhabitants/treasure, discovery date/order, favourites and notes. Duplicate identity returns the existing record. No arbitrary collection capacity.

**Expedition:** generated floors with opened-chest, defeated-enemy and explored-tile sets. These reset on leaving town; backtracking retains them. Loot and battle random streams are independent of generation. Each chest and keeper pays at most once per expedition.

## Determinism contract

Specified Park–Miller integer arithmetic replaces engine RNG. Floor streams derive from seed, bracket and index. Immutable tables belong to generator v1. **Do not edit v1 generation logic/tables after distributing saves.** Add v2 and dispatch by saved version. The current loader rejects unsupported generators rather than silently changing discovered places.

Floors are 35×23. A spanning tree connects nine jittered chambers and additional corridors create loops. Tests flood-fill every floor. Stair endpoints and enemy/chest positions are exclusive. A separate boss chamber ends each grotto.

## Expansion boundaries

Quests consume depth/monster/chest/boss events; future events can add IDs and conditions. Hub services and routes are data records, ready for richer schedules. Materials have an inventory category for future recipes. Combat resolves independently of rendering.

Split the atlas/shop/combat presentation module as those screens grow. World rendering already separates hub/interior/dungeon methods. The controller orchestrates transitions and rewards, not procedural or combat calculations.
