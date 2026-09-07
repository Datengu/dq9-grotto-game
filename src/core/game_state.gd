class_name GameState
extends RefCounted
var player: Dictionary
var maps: Array = []
var quests: Dictionary = {}
var completed: Array = []
var hub: Dictionary = {"boss_wins": 0, "expeditions": 0}
var discovery_counter = 0
var reward_counter = 0
var campaign_seed = 1
var save_error = ""

func _init() -> void:
	player = {"level": 1, "xp": 0, "hp": 90, "mp": 24, "gold": 120, "poison": 0,
		"revocations": 0, "inventory": {"field_blade":1,"trail_coat":1,"salve":5,"tonic":2,"remedy":2},
		"equipment": {"weapon":"field_blade","armour":"trail_coat"}}
	campaign_seed = int(Time.get_unix_time_from_system()) % 2147483646

func stats() -> Dictionary:
	var level = int(player.level)
	return {"max_hp": 78 + level * 12, "max_mp": 21 + level * 3,
		"attack": 12 + level * 3 + int(Content.item(player.equipment.weapon).get("attack",0)),
		"defence": 3 + level * 2 + int(Content.item(player.equipment.armour).get("defence",0)), "speed":8 + level}

func rest() -> void:
	player.hp = stats().max_hp
	player.mp = stats().max_mp
	player.poison = 0

func gain_xp(amount: int) -> int:
	player.xp += amount
	var gained = 0
	while player.level < 99 and player.xp >= xp_needed():
		player.xp -= xp_needed()
		player.level += 1
		gained += 1
		player.hp = mini(stats().max_hp, player.hp + 35)
		player.mp = mini(stats().max_mp, player.mp + 9)
	return gained

func xp_needed() -> int:
	return 25 + int(player.level) * 20

func give(id: String, amount: int = 1) -> void:
	if id == "gold":
		player.gold += amount
	else:
		player.inventory[id] = int(player.inventory.get(id, 0)) + amount

func use_item(id: String) -> bool:
	if int(player.inventory.get(id, 0)) <= 0:
		return false
	var item = Content.item(id)
	if item.get("slot", "") != "supply":
		return false
	player.inventory[id] -= 1
	player.hp = mini(stats().max_hp, player.hp + int(item.get("heal",0)))
	player.mp = mini(stats().max_mp, player.mp + int(item.get("mana",0)))
	if item.get("cure",false):
		player.poison = 0
	return true

func equip(id: String) -> bool:
	var item = Content.item(id)
	if int(player.inventory.get(id, 0)) < 1 or not item.get("slot","") in ["weapon","armour"]:
		return false
	player.equipment[item.slot] = id
	return true

func trade(id: String, sell: bool = false) -> bool:
	var item = Content.item(id)
	if item.is_empty():
		return false
	if sell:
		var reserved = 1 if player.equipment.values().has(id) else 0
		if int(player.inventory.get(id,0)) <= reserved:
			return false
		player.inventory[id] -= 1
		player.gold += maxi(1,int(item.price / 2))
	else:
		if player.gold < item.price or hub.boss_wins < item.get("unlock", 0):
			return false
		player.gold -= item.price
		give(id)
	return true

func find_map(id: String) -> Dictionary:
	for entry in maps:
		if entry.meta.id == id:
			return entry
	return {}

func add_map(meta: Dictionary, source: String) -> Dictionary:
	var existing = find_map(meta.id)
	if not existing.is_empty():
		return existing
	discovery_counter += 1
	var entry = {"meta": meta.duplicate(true), "source": source, "order": discovery_counter,
		"discovered_at": Time.get_datetime_string_from_system(), "favourite":false,"notes":"",
		"visits":0,"deepest":0,"clears":0,"treasure":[],"monsters":[],"floor_notes":{}}
	maps.append(entry)
	return entry

func reward_map(previous_level: int, source: String) -> Dictionary:
	reward_counter += 1
	var seed_value = SeedRng.new(campaign_seed + reward_counter * 99991).next()
	var base = GrottoGenerator.base_quality(player.level, player.revocations, previous_level)
	return add_map(GrottoGenerator.create(seed_value, base), source)

func serialise() -> Dictionary:
	return {"save_version":1,"player":player,"maps":maps,"quests":quests,"completed":completed,
		"hub":hub,"discovery_counter":discovery_counter,"reward_counter":reward_counter,"campaign_seed":campaign_seed}

func restore(data: Dictionary) -> bool:
	data = normalise_numbers(data)
	if int(data.get("save_version",0)) != 1:
		return false
	for key in ["player","quests","hub"]:
		if not data.get(key) is Dictionary:
			return false
	if not data.get("maps") is Array or not data.get("completed") is Array:
		return false
	for key in player.keys():
		if not data.player.has(key):
			return false
	if not data.player.inventory is Dictionary or not data.player.equipment is Dictionary:
		return false
	for slot in ["weapon","armour"]:
		var id = data.player.equipment.get(slot,"")
		if not id is String or Content.item(id).get("slot","") != slot:
			return false
	for id in data.player.inventory:
		if Content.item(id).is_empty() or not data.player.inventory[id] is int or data.player.inventory[id] < 0:
			return false
	for key in ["level","xp","hp","mp","gold","poison","revocations"]:
		if not data.player[key] is int or data.player[key] < 0:
			return false
	if data.player.level < 1 or data.player.level > 99:
		return false
	for key in ["boss_wins","expeditions"]:
		if not data.hub.get(key) is int or data.hub[key] < 0:
			return false
	for quest in data.quests.values():
		if not quest is Dictionary or not quest.get("progress") is int:
			return false
	for entry in data.maps:
		if not entry is Dictionary or not entry.get("meta") is Dictionary:
			return false
		for key in ["id","seed","base_quality","final_quality","grotto_rank","depth","starting_monster_rank","boss_tier","environment","displayed_level","name","generator_version"]:
			if not entry.meta.has(key):
				return false
		if int(entry.meta.generator_version) != GrottoGenerator.VERSION:
			return false
		for key in ["seed","base_quality","final_quality","grotto_rank","depth","starting_monster_rank","boss_tier","displayed_level"]:
			if not entry.meta[key] is int:
				return false
		if entry.meta.seed < 0 or entry.meta.seed > 2147483646 or entry.meta.final_quality < 2 or entry.meta.final_quality > 248:
			return false
		var expected = GrottoGenerator.create(entry.meta.seed,entry.meta.base_quality,entry.meta.final_quality)
		if expected != entry.meta:
			return false
		for key in ["visits","deepest","clears","order"]:
			if not entry.get(key) is int or entry[key] < 0: return false
		for key in ["source","discovered_at","notes"]:
			if not entry.get(key) is String: return false
		for key in ["treasure","monsters"]:
			if not entry.get(key) is Array: return false
		if not entry.get("favourite") is bool or not entry.get("floor_notes") is Dictionary:
			return false
	player = data.player.duplicate(true)
	maps = data.maps.duplicate(true)
	quests = data.quests.duplicate(true)
	completed = data.completed.duplicate(true)
	hub = data.hub.duplicate(true)
	discovery_counter = int(data.get("discovery_counter", maps.size()))
	reward_counter = int(data.get("reward_counter",0))
	campaign_seed = int(data.get("campaign_seed",1))
	return true

static func normalise_numbers(value: Variant) -> Variant:
	# JSON numbers are floats in Godot. Rehydrate integral fields before they
	# become map identity, integer RNG inputs, counters or dictionary records.
	if value is float and is_finite(value) and value == floor(value):
		return int(value)
	if value is Array:
		var result: Array = []
		for element in value: result.append(normalise_numbers(element))
		return result
	if value is Dictionary:
		var result: Dictionary = {}
		for key in value: result[key] = normalise_numbers(value[key])
		return result
	return value
