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
	result["max_hp"] = 14 + rank * 9 + int(family.get("hp_bonus", 0))
	result["hp"] = result.max_hp
	result["attack"] = 6 + rank * 3
	result["defence"] = 1 + rank * 2
	result["speed"] = 5 + rank + int(family.get("speed_bonus", 0))
	result["xp"] = 12 + rank * 7
	result["gold"] = 8 + rank * 5
	result["boss"] = false
	return result

static func boss(tier: int) -> Dictionary:
	var result: Dictionary = table("bosses")[tier - 1].duplicate(true)
	result["rank"] = tier
	result["max_hp"] = 55 + tier * 25
	result["hp"] = result.max_hp
	result["attack"] = 10 + tier * 4
	result["defence"] = 3 + tier * 2
	result["speed"] = 5 + tier
	result["xp"] = 70 + tier * 40
	result["gold"] = 60 + tier * 35
	result["boss"] = true
	return result
