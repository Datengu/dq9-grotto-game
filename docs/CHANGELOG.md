# Lantern Atlas v0.2 — 3D exploration correction

- Replaced the 2D world layer with physical 3D Bellwether, five enterable services and 3D grotto floors. Original low-poly characters, buildings, creatures and materials.
- Added a local high-angle perspective camera, smooth acceleration/turning/collision and two visual followers. F2 tunes the camera; foreground scenery fades when it blocks the leader.
- Visible enemies now idle, wander, detect through line of sight, chase around walls, initiate encounters and give up. Escaping gives a re-engagement grace period.
- New v2 charts grow room graphs with varied footprints, room counts, corridor lengths and loops. Existing v1 charts retain their exact underlying layouts.
- Reduced exploration HUD clutter. M toggles a compact discovered map; explored sketches now survive revisits and saving. NPC dialogue sits over the lower part of the world.
- Chest openings require acknowledgement and clearly show the item and quantity. Defeated keepers reveal a visible homeward light.
- Rebalanced enemy offence, defence, HP and progression. Keepers telegraph charge/heavy-strike cycles; Guard and Spark have meaningful roles. Level-ups no longer refill expedition resources.
- Preserved quests, shops, equipment, atlas collection, farming, map rewards and safe-town loading. Save format 2 migrates format 1 and supports both chart generators.
- Added physical exploration, legacy migration, generation footprint and repeated combat strategy tests. Reference observations, camera tuning and fidelity limitations are documented.

This is still original geometric placeholder art. Followers do not yet participate in combat, battles contain one opponent, and networking, audio and controller support are not implemented. The procedural floor algorithm approximates DQIX-style relationships; it does not reproduce DQIX seeds or exact geometry.
