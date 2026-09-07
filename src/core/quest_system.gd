class_name QuestSystem
extends RefCounted

static func available(state: GameState, quest: Dictionary) -> bool:
	return quest.requires == "" or state.completed.has(quest.requires)

static func accept(state: GameState, id: String) -> Dictionary:
	for quest in Content.table("quests"):
		if quest.id == id and available(state, quest) and not state.quests.has(id) and not state.completed.has(id):
			state.quests[id] = {"progress":0}
			if quest.get("map_on_accept",false):
				return state.add_map(starter(), "Surveyor's bulletin")
	return {}

static func starter() -> Dictionary:
	# A fixed original seed with treasure-bearing depth and an approachable guardian.
	for seed_value in 10000:
		var meta = GrottoGenerator.create(seed_value, 2, 2)
		if meta.depth == 3 and meta.starting_monster_rank == 1 and meta.boss_tier == 1 and meta.environment == "Ruins":
			return meta
	return GrottoGenerator.create(1,2,2)

static func event(state: GameState, type: String, amount: int = 1) -> void:
	for quest in Content.table("quests"):
		if state.quests.has(quest.id) and quest.event == type and not state.completed.has(quest.id):
			var record = state.quests[quest.id]
			record.progress = mini(int(quest.target), maxi(record.progress,amount) if type == "depth" else record.progress + amount)

static func claim(state: GameState, id: String) -> Dictionary:
	for quest in Content.table("quests"):
		if quest.id == id and state.quests.has(id) and not state.completed.has(id) and state.quests[id].progress >= quest.target:
			state.completed.append(id)
			state.give("gold",int(quest.gold))
			if quest.get("map_reward",false):
				return state.reward_map(int(state.player.level / 2), "Commission: " + quest.title)
	return {}
