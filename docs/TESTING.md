# Validation

## Current v0.3 foundation playtest

See [foundation validation](FOUNDATION-WORK.md#final-validation--focused-v03-playtest) and `docs/validation/v0.3` for the recovered work, full source-suite results, Windows release-engine expedition, existing v0.2 campaign, local populations and nine movement-cadence probes. The v0.2 record below is retained as historical evidence. `scripts/test-exported.ps1` now runs tests inside a separate release-engine export, resolving the old external-script harness limitation.

## Historical v0.2

Run on Windows with Godot 4.6.3 on 8 September 2026. Machine-readable evidence lives in `docs/validation/v0.2`; regenerate reports with `scripts/run-tests.ps1`. The interrupted implementation had already passed the complete suite; packaging resumed from that repository state. Final focused checks covered the last camera/UI changes, generator fingerprints and the exported build.

## Generation and persistence

The v2 stress sweep produced **1,000 grottos, 10,598 floors and 249,685 successful checks**, with zero failures. It covers every quality value 2–248, connectivity, required stairs and boss access, exclusive entity positions, valid monster/chest ranks, same-seed reproduction, quests, save/load, backup recovery and original-map revisits. Three geometry hashes protect v1; three additional v2 hashes are checked separately by `version_tests.gd`.

Among exploration floors, the sample contained 1,601 distinct width/height pairs. Mean bounding footprint was 871 internal cells for quality brackets 1–3 and 2,654 for brackets 10–12. Large low-rank and compact high-rank floors overlap. The sample includes 92 Lumen-colony floors. These are our generator's statistics, not DQIX frequencies; the sweep is uniform over quality thresholds rather than a forecast of ordinary map rewards. `-Count 10000` enables a larger sweep.

Migration tests load the v1 schema without an explored field, preserve old metadata/notes/favourites, keep the old geometry, save/reload a mixed v1/v2 atlas and retain discovered fog. A v1 chart also runs through the new 3D renderer with physical collision. Normal user saves were not changed by automated tests.

## Physical loop and rendering

The rendered `playthrough_3d.gd` run drives the real CharacterBody3D through navigation routes and uses game UI buttons. It walks to the board and weapon shop, accepts commissions, buys/equips the sabre, explores three floors, encounters roaming/chasing enemies, acknowledges treasure, defeats the keeper, claims quests, revisits the original chart and saves/reloads. It completed **10 battles and 5,210 physics movement frames**, retained three maps, and ended at level 3 with 55 HP. No stat or supply boosts were injected.

`exploration_tests.gd` covers all five doors, counters and return paths; an inn rest; patrolling NPC dialogue; acceleration/braking; normalised diagonal speed; physical wall collision; routes around walls; follower spacing and arrival; camera settling; wall-blocked detection; pursuit expiry; disengagement; alternate player actor IDs; runtime snapshots; and selective camera obstruction fading. Both the complete run and final focused rerun passed.

Rendered frames were inspected for town/interior scale, camera framing, corridor travel, readable dialogue, atlas, combat, acknowledged loot and scenery occlusion. Inspection corrected initial overexposure, oversized dialogue/camera panels and hidden-leader cases. This is an automated physics/UI playthrough with visual review, not extensive human playtesting.

## Repeatable combat balance

`balance_tests.gd` runs 200 deterministic trials for each of 20 scenario/strategy combinations: **4,000 individual battles**, plus 200 continuous starter expedition trials. Player gear and levels are explicit in the test, using varied original enemy families. Damage records actual HP removed; turns include healing/guard actions and end at victory or defeat. The sustainability estimate is HP divided by per-battle damage, not a replacement for an attrition simulation.

| Prepared state | Normal rank / keeper tier | Attack-only normal turns | Attack-only keeper death rate | Tactical keeper death rate |
|---|---:|---:|---:|---:|
| Level 1, copper/ring gear | 1 / 1 | 2.0 | 25% | 0% |
| Level 5, copper/ring gear | 3 / 3 | 3.0 | 100% | 0% |
| Level 18, warden gear | 6 / 6 | 3.0 | 100% | 0% |
| Level 35, starsteel/moonplate | 10 / 10 | 3.0 | 100% | 0% |
| Level 5, copper/ring gear, unprepared for high rank | 10 / 10 | 2.0, ending in defeat | 100% | 100% |

Tactical keeper fights averaged roughly 9–17 turns. The full report includes HP damage, MP spent, supplies, deaths and sustainability. Ten consecutive starter encounters followed by a keeper, without resting, yielded 0/100 clears for Attack-only and 100/100 for the prepared tactical strategy. These demonstrate resource pressure and preparation gaps; they do not establish many-hour economy balance or optimal strategies. Combat still has one opponent at a time.

## Windows delivery

The v0.2 native x86-64 executable contains the embedded game pack. The ZIP includes the matching executable, player guide, changelog, build manifest and Godot license notices. The executable's SHA-256 was checked against the copy inside the ZIP. The production executable was run independently of the source project with both a fresh character and a copied mixed-version save. Both runs rendered Bellwether, captured frames and exited successfully. An additional external-script release harness did not reach its assertions and was stopped; it is not counted as a passing test. The full playable loop was verified by the Godot runtime test described above. See `build-info.json` for its exact version, build time and hash.

The restricted host logs a root-certificate-store access error on startup. This offline game makes no network requests; the message did not prevent rendering, saves or tests. Final imports, checks and release startup reported no script or parse errors.

## Remaining coverage

Many-hour saves/economy, manual play across multiple GPUs, alternate window aspect ratios, controller/accessibility input, enemy groups, network replication and active combat companions remain future work. Original-game geometry/RNG/camera constants are not validated. The supplied recordings were studied qualitatively, and emulator overlays/speed changes were excluded from the reference interpretation.
