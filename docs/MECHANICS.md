# Grotto research and fidelity ledger

Research date: 7 September 2026. Public descriptions inform an original implementation. No ROM, disassembly, extracted game code, assets or original item/monster tables are included. Our generator is **not bit-compatible with DQIX**.

## Documented relationships reproduced

[Terence Fergusson's Grotto Mechanics Guide v1.00 (2010), sections 2.1–2.3](https://gamefaqs.gamespot.com/ds/937281-dragon-quest-ix-sentinels-of-the-starry-skies/faqs/61151) is the principal detailed source. We reproduce its quality brackets, depth/starting-rank ranges, weighted boss eligibility, four-floor rank increments, chest eligibility ranges and environment weights. Base quality combines hero progression and completed-map level. Final quality uses integer deviation and the positive-side rounding adjustment, bounded to 2–248. Displayed level derives from depth, starting rank and boss, with bounded variation. Chests start after two exploration floors; a separate boss chamber follows. Chest positions/ranks persist while contents renew.

The guide takes precedence over the [Dragon Quest Wiki overview](https://dragon-quest.org/wiki/Treasure_map_(Dragon_Quest_IX)), which gives different lower monster-rank bounds in some quality bands and a different minimum chest rank for monster rank 12. We use the guide's 4–10 chest range. This conflict is recorded rather than claiming emulator-verified fidelity.

## Executable rules

See `grotto_generator.gd` and independently written numeric definitions in `data/generation.json`. Tests cover quality boundaries and the rounding example at base quality 152. The hero has one progression track; revocation defaults to zero with no gameplay interface yet. Testing establishes our invariants, not original-game seed matches.

## Approximations and uncertainties

| Mechanic | Current implementation | Remaining work |
|---|---|---|
| Seed / RNG | 31-bit Park–Miller, separate floor streams | Research original seed reduction, equivalence and call order |
| Geometry | V1: nine jittered chambers. V2: dynamically grown/cropped room graph | Study partitioning, corridor and biome-specific rules |
| Chests | Unique reachable positions; eligible ranks sampled uniformly | Original placement preferences and rank probabilities unresolved |
| Populations | Three original families per environment, rank-scaled stats, fixed spawn identities with runtime roaming | Memory-budget constraints and support groups not reconstructed |
| Unusual floors | 1/160 chance on eligible rank-five-plus floors: Lumen colony, extra XP | Original placeholder, not original-game memory anomalies |
| Names | Original prefix by rank band, locale by environment/depth, suffix by boss band | Broader overlapping eligibility could carry more information |
| Visibility | Nearby tiles reveal through walls; sketches now survive revisits and saves | Map line of sight still approximate; enemy detection uses wall-aware sight |

## Intentional differences

Bellwether replaces overworld travel. A carried atlas launches expeditions; a physical board reveals the fixed original starter chart. Every keeper grants a normal map, including tier 12. Retreat is free outside combat. Defeat loses ten percent of crowns but preserves belongings/maps. Recovery is free in this slice; loading starts in town. The seed desk supports experiments without raising character level.

Our enemies, abilities, stats, weapons, loot, dialogue, names and colony rewards are original and balanced for a solo early-game character. Boss tiers identify our keeper roster; chest ranks contain our own loot.

## Next research

Prioritise public descriptions of floor partitions and rank probabilities. Record source revision, disagreements, confidence and independently authored test vectors before changing rules. The [DQIX community editor](https://github.com/DQIX/editor) identifies a partial community implementation as a future lead; no code was copied from it. Review provenance/licensing before any implementation study. Preserve all issued v1 charts when refining generation.

## v0.2 research follow-up — 8 September 2026

Rechecked the [Grotto Mechanics Guide](https://gamefaqs.gamespot.com/ds/937281-dragon-quest-ix-sentinels-of-the-starry-skies/faqs/61151), especially sections 2.3.2–2.3.3. It documents seed-fixed chest positions/ranks and original floors of differing size: the first four floors use 10×10 through 14×14, while deeper floors can reach 15×15 or 16×16. Its monster-population anomalies relate to storage constraints, not a simple independent rarity roll.

Our v2 graph is an explicit original approximation for the requested scalable physical footprints, not a reconstruction of those original floor-cell units, partitioning rules or memory behaviour. Quality-dependent topology beyond the documented depth tendencies is an intentional design extension requested for this pass. The frozen v1 generator remains available for every existing chart. Camera framing, following, town transitions and visible encounter movement were studied from the user's supplied recordings; see [reference observations](EXPLORATION-REFERENCES.md). No reference media are packaged.
