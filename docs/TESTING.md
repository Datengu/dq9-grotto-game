# Validation — v0.1

Run on Windows with Godot 4.6.3, 7 September 2026. Detailed machine-readable results are checked in under `docs/validation`. Regenerate local reports with `scripts/run-tests.ps1`; use `-Count 10000` for a larger stress sample and `-Visual` for screenshots.

## Generation, saves and combat

**1,000 grottos, 10,598 floors, zero failed checks.** The suite cycles through every final quality from 2 to 248 with different deterministic seeds. It verifies:

- Same inputs reproduce the same structure; distinct seeds differ; three fixed SHA-256 geometry fingerprints protect generator v1.
- Every walkable tile is connected; entrances reach stairs; every required stair/boss exists; chest and encounter locations are reachable and exclusive.
- Quality-bracket depth/boss/monster eligibility, four-floor monster increments, valid ranked chests and the no-chests-on-B1/B2/boss rule.
- All persistent fields round-trip, quests reveal/reward maps exactly once, and the atlas retains identity, observations, favourites and visits.
- Loading and revisiting recreate the original dungeon, malformed/future data are rejected, corrupt primaries recover from backups and a subsequent save preserves the good backup.
- Basic combat availability, guard, victory, ended-combat behaviour, boss escape restrictions, buying/equipping/selling, healing and inn recovery.

This is a deterministic quality sweep, **not a forecast of maps acquired during ordinary player progression**. The monster-rank histogram includes boss chambers. Results cover all exploration depths 2–16, monster ranks 1–12, boss tiers 1–12 and chest ranks 1–10.

| Environment | Grottos |
|---|---:|
| Cavern | 298 |
| Ruins | 403 |
| Ember | 101 |
| Tidal | 103 |
| Frost | 95 |

The sample produced 55 unusual Lumen-colony floors and 314 rank-ten chests. Those are our generator's results, not claims about DQIX frequencies. Full depth, boss, monster and chest histograms are in the JSON report.

## Rendered playable-loop test

`tests/playthrough.gd` instantiates the actual game scene, walks through collision-valid routes, interacts with the physical board/doors/counter/stairs/chests, and activates actual UI buttons. It takes **556 movement steps and resolves 13 battles**, then checks three retained maps, boss completion, quest claims, an exact old-map revisit, save and reload. No stat or inventory boosts are injected. The first expedition ends at character level five. Campaign reward seeds depend on the new-save seed, so subsequent chart names vary.

This is a runtime-driven automated playthrough, not a claim of extensive human playtesting. Rendered screenshots were visually inspected for readability. That inspection found and fixed atlas filtering with an empty search, sidebar overflow, and a combat placeholder that lacked a creature portrait. Earlier tests also exposed JSON integer rehydration and a revisit test selecting the wrong atlas page; both were corrected.

Screenshots: [town](screenshots/hub.png), [collection after expedition](screenshots/atlas-after-expedition.png), [treasure floor](screenshots/treasure-floor.png), [combat](screenshots/combat.png).

## Windows package

Exported with the official Windows x86-64 release template and embedded game pack. `LanternAtlas.exe` was launched from its build directory independently of the source and completed a headless startup smoke test with exit code zero. The zip includes the native executable, player guide and Godot license notices.

The restricted host reports a Godot root-certificate-store access error during startup. The game makes no network requests; this did not prevent rendering, saves, tests or the release executable from running. No script/parse errors remain in the final tests.

## Practical limits

Early combat is deliberately forgiving; late-game farming and economy balance need longer sessions. Full UI coverage, alternate screen sizes, controller/accessibility input and many-hour saves remain future tests. Original-game geometry and random-call fidelity are not validated. The current room/corridor family is spatially valid but needs more biome variety. Visible enemies are stationary; NPCs have small patrol routes.
