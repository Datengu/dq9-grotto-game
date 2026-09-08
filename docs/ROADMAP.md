# Vertical development roadmap

## v0.2: exploration correction completed

Physical 3D Bellwether and five service interiors; high-angle perspective follow camera; continuous collision-based movement; two visual followers; 3D generated floors, chest/stair geometry and original creatures; roaming/detecting/pursuing enemies; optional persistent discovered map; acknowledged chest rewards; stronger combat offence, telegraphed keeper strikes and expedition attrition. Old v1 charts remain intact; new v2 charts have varying graph-grown footprints. Camera, movement, AI and balance are tunable. Tests cover the full physical loop, legacy saves, generation and naive versus tactical combat.

## Next: refine this foundation

1. Play several real collection sessions and tune camera, movement, encounter density, escape pressure and expedition resource costs. Capture a longer enemy detection/chase reference if helpful.
2. Improve cave mesh contours and room/corridor transitions while keeping issued charts stable. Research original floor partitions and placement probabilities before changing generation again.
3. Replace procedural limb motion with original rigged animation; improve walk/idle/turn feedback and environmental lighting. Add original audio and accessibility/controller support.
4. Expand combat to enemy groups and mechanically active companions. Preserve the readable intent system and repeatable Attack-only/attrition benchmarks.
5. Add atlas completion/type/level/boss/treasure filters and better observation pages; map-specific quest events can follow.
6. Add save slots and optional expedition suspension, including roaming actor state. Current saves deliberately resume in town.

## Later

One crafting service, additional equipment slots, inn-room trophies and richer NPC routines, followed by character builds and vocations. Host-authoritative 2–4 player co-op is a separate milestone: actor IDs and state boundaries exist, but networking is not implemented. Mutations, rare floor ecology, map trading, procedural commissions and town expansion remain longer-term ideas.

Every generation change must distinguish documented rules, approximation and intentional invention. Keep quality, rank, level, depth, environment and treasure potential distinct; never silently overwrite a discovered place.
