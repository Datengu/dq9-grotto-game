# Lantern Atlas

A standalone offline Godot 4 RPG about collecting places. Walk through Bellwether, accept a physical bulletin-board commission, prepare at shops, explore a permanent seeded grotto, defeat its keeper and bring another chart home.

All names, dialogue, items, monsters and geometric artwork are original placeholders. No Dragon Quest assets, game code, ROMs, music or other original game files are used. The generator follows documented mechanical relationships; it is not seed-compatible with DQIX.

## Play on Windows

Open **build/LanternAtlas-v0.3.0/LanternAtlas.exe**. No engine installation or network is required. Or extract **build/LanternAtlas-v0.3.0-Windows.zip** and run the executable. Keep the accompanying Godot license notices when distributing it. The earlier v0.2 build is kept separately.

- WASD / arrows: walk. E: interact with board, entrances, counters, treasure or stairs. Walk through an interior doorway to exit automatically.
- B: atlas. I: satchel/equipment. J: journal. Esc: pause/close. M: discovered map. F1: help. F2: camera tuning.
- Battle keys 1-5: attack, Spark, Mend, Guard, flee. Mouse buttons also work.

Walk north from the fountain to the board. Accept *A light below the hill* and the other two commissions. Enter Brass & Blade, approach Orin's counter, buy a copper sabre for 65 crowns, then equip it with I. Rest is free at The Warm Window. Use B to launch your first expedition.

Gold stairs descend; blue stairs ascend. Chests start on floor three; the keeper has a separate chamber below. Defeat it for a new permanent map, return home and claim commissions at the physical board. Old maps retain their layouts, chest locations/ranks and identity. Keepers and chest contents reset for each expedition; roaming enemies replenish nearby and despawn at a distance.

## Included in v0.3

The foundation playtest fixes automatic building exits, physics/render interpolation and continuous enemy navigation, and adds a limited local encounter population. Save format 2 and chart generators 1/2 remain unchanged. See [foundation validation](docs/FOUNDATION-WORK.md) for evidence and the remaining open work.

Full-screen 3D exploration, a smooth perspective follow camera, continuous capsule movement, two visual followers, roaming enemies and varied deterministic floor footprints. Five enterable service buildings, two patrolling neighbours, reactive dialogue, a personal inn room, six commissions, permanent atlas, favourites, notes, search/sorting, statistics and share codes. Five environments, 12 quality brackets, 2-16 exploration floors plus keeper, 12 monster ranks, ten chest ranks and 12 original keeper tiers. Solo turn-based combat, HP/MP, XP/levels, poison, equipment, supplies, shops, ranked loot and backup saves.

Chest rewards pause for acknowledgement. Enemy intentions are shown in combat: Guard charged strikes, use Spark against shields, and budget healing. Level-ups increase capacity without replenishing expedition resources.

The atlas seed desk lets you experiment with seed and final quality without raising your character's level. Buying equipment does not automatically equip it.

## Saves

Normal save folder: **%APPDATA%\Lantern Atlas\**. Files: atlas-save.json and atlas-save.json.bak. Progress autosaves after durable changes and on normal window close; an explicit Save button is also available. Loading starts safely in town and retains loot/progression. It does not suspend the current floor. Explored floor sketches remain in your atlas. Existing v1 saves and charts are supported: old layouts stay on generator v1; newly acquired charts use v2.

Damaged primary saves fall back to the previous valid backup. Unsupported or unrecoverable saves are preserved and saving pauses with an in-game message. For manual recovery, close the game, copy the folder somewhere safe and restore a known-good backup. To start fresh, rename both files after backing them up. Avoid running two game instances against the same save.

## Development and testing

Open project.godot in **Godot 4.6.3 standard**, then press F5. No add-ons or external runtime packages are required. The local engine is in .tools/godot.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run-tests.ps1
powershell -ExecutionPolicy Bypass -File scripts/run-tests.ps1 -Visual
powershell -ExecutionPolicy Bypass -File scripts/run-tests.ps1 -Count 10000
powershell -ExecutionPolicy Bypass -File scripts/test-exported.ps1
powershell -ExecutionPolicy Bypass -File scripts/build.ps1
```

Tests use isolated files under test-output, never your real character. The visual test captures rendered screenshots. On a fresh checkout, download the official [Godot 4.6.3 Windows editor](https://github.com/godotengine/godot-builds/releases/tag/4.6.3-stable) into .tools/godot. scripts/fetch-template.mjs uses Node 22+ to retrieve the Windows release member of the official template archive. Alternatively install normal export templates and update the custom template path. Tools and builds are ignored by Git.

See [architecture](docs/ARCHITECTURE.md), [mechanics research](docs/MECHANICS.md), [testing evidence](docs/TESTING.md) and [roadmap](docs/ROADMAP.md).

This is an early 3D vertical slice. Models and environments are original geometric placeholders; exact DQIX floor algorithms and camera constants are not reproduced. Followers are visual; combat is still solo. Networking, crafting, audio, controller support and finished art remain future work. See [reference study and camera tuning](docs/EXPLORATION-REFERENCES.md) for the design translation and limitations.
