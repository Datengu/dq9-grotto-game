class_name Content
extends RefCounted
static var cache: Dictionary = {}

static func table(key: String):
	if not cache.has(key):
		cache[key] = JSON.parse_string(FileAccess.get_file_as_string("res://data/%s.json" % key))
	return cache[key]

static func item(id: String) -> Dictionary:
	return table("items").get(id, {})

static func monster(environment: String, rank: int, variant: int = 0) -> Dictionary:
	var family = table("monsters")[environment][variant % 3]
	var result: Dictionary = family.duplicate(true)
	result["rank"] = rank
	result["name"] = ("" if rank < 4 else ["", "", "", "Ancient ", "Dread ", "Elder "][mini(5, int(rank / 2))]) + str(family.name)
	var b = table("balance").monster
	result["max_hp"] = int(b.hp_base + rank*b.hp_linear + rank*rank*b.hp_quadratic) + int(family.get("hp_bonus", 0))
	result["hp"] = result.max_hp
	result["attack"] = int(b.attack_base + rank*b.attack_linear + rank*rank*b.attack_quadratic)
	result["defence"] = int(b.defence_base + rank*b.defence_linear)
	result["speed"] = 5 + rank + int(family.get("speed_bonus", 0))
	result["xp"] = 12 + rank * 7
	result["gold"] = 8 + rank * 5
	result["boss"] = false
	return result

static func boss(tier: int) -> Dictionary:
	var result: Dictionary = table("bosses")[tier - 1].duplicate(true)
	result["rank"] = tier
	var b = table("balance").boss
	result["max_hp"] = int(b.hp_base + tier*b.hp_linear + tier*tier*b.hp_quadratic)
	result["hp"] = result.max_hp
	result["attack"] = int(b.attack_base + tier*b.attack_linear + tier*tier*b.attack_quadratic)
	result["defence"] = int(b.defence_base + tier*b.defence_linear)
	result["speed"] = 5 + tier
	result["xp"] = 70 + tier * 40
	result["gold"] = 60 + tier * 35
	result["boss"] = true
	return result
