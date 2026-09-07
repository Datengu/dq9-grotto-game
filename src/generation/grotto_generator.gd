class_name GrottoGenerator
extends RefCounted
const VERSION = 1

static func base_quality(hero_level: int, revocations: int, previous_level: int) -> int:
	return clampi(hero_level + 5 * mini(10, revocations) + previous_level, 2, 248)

static func final_quality(base: int, rng: SeedRng) -> int:
	var deviation = int(base / 10)
	var result = base + rng.between(-deviation, deviation)
	if result > base and base % 10 != 0:
		result -= 1
	return clampi(result, 2, 248)

static func create(seed_value: int, base: int, fixed_final: int = -1) -> Dictionary:
	base = clampi(base, 2, 248)
	var quality = fixed_final if fixed_final >= 2 else final_quality(base, SeedRng.new(seed_value + 7103))
	quality = clampi(quality, 2, 248)
	var config = Content.table("generation")
	var bracket: Array = []
	var grotto_rank = 0
	for row in config.quality_brackets:
		grotto_rank += 1
		if quality <= row[0]:
			bracket = row
			break
	# Within a bracket, seed identifies structure. Quality remains acquisition provenance.
	var rng = SeedRng.new(seed_value + grotto_rank * 104729)
	var depth = rng.between(int(bracket[1]), int(bracket[2]))
	var rank = rng.between(int(bracket[3]), int(bracket[4]))
	var weights: Array = []
	for i in range(int(bracket[5]) - 1, int(bracket[6])):
		weights.append(config.boss_weights[i])
	var boss_tier = int(bracket[5]) + rng.weighted(weights)
	var environment: String = config.environments[rng.weighted(config.environment_weights)]
	var level = clampi(3 * (depth + rank + boss_tier - 4) + rng.between(-5, 5), 1, 99)
	var prefix = rng.pick(config.prefixes[mini(3, int((rank - 1) / 3))])
	var locale = config.locales[environment][mini(2, int((depth - 2) / 5))]
	var suffix = rng.pick(config.suffixes[mini(2, int((boss_tier - 1) / 4))])
	return {"generator_version": VERSION, "seed": seed_value, "base_quality": base,
		"final_quality": quality, "grotto_rank": grotto_rank, "depth": depth,
		"starting_monster_rank": rank, "boss_tier": boss_tier, "environment": environment,
		"displayed_level": level, "name": "%s %s of %s" % [prefix, locale, suffix],
		"id": "LA1-%08X-%03d" % [seed_value, quality]}

static func floor_rank(metadata: Dictionary, index: int) -> int:
	return mini(12, int(metadata.starting_monster_rank) + int(index / 4))

static func generate(metadata: Dictionary) -> Array:
	assert(int(metadata.generator_version) == VERSION, "Unsupported generator version")
	var result: Array = []
	for i in range(int(metadata.depth) + 1):
		result.append(FloorGenerator.generate(metadata, i))
	return result
