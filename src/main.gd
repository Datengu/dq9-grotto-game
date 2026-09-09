extends Node
var state: GameState
var world: ExplorationWorld
var ui: GameUI
var battle: Combat
var active_map: Dictionary = {}
var floors: Array = []
var floor_progress: Array = []
var floor_index = 0
var battle_enemy_index = -1
var expedition_rng: SeedRng
var save_allowed = true
var test_mode = false

func _ready() -> void:
	test_mode = OS.get_cmdline_user_args().has("--test-play") or OS.get_cmdline_user_args().has("--capture")
	state = GameState.new()
	if not test_mode:
		var loaded = SaveStore.read(state)
		if not loaded and not state.save_error.is_empty(): save_allowed = false
	world = ExplorationWorld.new()
	add_child(world)
	world.interaction.connect(on_interaction)
	ui = GameUI.new(self)
	add_child(ui)
	if not state.save_error.is_empty(): ui.toast(state.save_error)
	else: ui.toast("Welcome home. The expedition bulletin is north of the fountain.")
	get_tree().auto_accept_quit = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
		get_tree().quit()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	var key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if battle != null:
		var actions = {KEY_1:"attack",KEY_2:"spark",KEY_3:"mend",KEY_4:"guard",KEY_5:"flee"}
		if actions.has(key): combat_action(actions[key])
		return
	if key == KEY_ESCAPE:
		if ui.screen == "": ui.show_pause()
		else: ui.close()
		return
	if ui.screen != "": return
	match key:
		KEY_E: world.interact()
		KEY_B: ui.show_book()
		KEY_I: ui.show_inventory()
		KEY_J: ui.show_board(false)
		KEY_F1: ui.show_help()
		KEY_F2: ui.show_camera_settings()
		KEY_M: ui.map_visible = not ui.map_visible

func save_game(notify: bool = false) -> void:
	if test_mode: return
	if not save_allowed:
		ui.toast("Saving paused: an unreadable save was preserved. See README recovery instructions.")
		return
	if not SaveStore.write(state): ui.toast(state.save_error)
	elif notify: ui.toast("Progress saved. Loading brings you safely back to town.")
	ui.update_hud()

func on_interaction(kind: String, payload: Variant) -> void:
	if battle != null: return
	match kind:
		"board": ui.show_board()
		"door": world.enter_building(payload); ui.update_hud()
		"exit":
			var door = world.building.door
			world.show_hub(door)
			ui.update_hud()
		"npc":
			ui.show_dialogue(payload.name,payload.dialogue + (" Word of your journey has reached the square." if state.hub.boss_wins > 0 else ""))
		"service": ui.show_service(payload)
		"book": ui.show_book()
		"chest": open_chest(payload)
		"enemy": begin_battle(payload,false)
		"boss": begin_battle(-1,true)
		"down":
			if floor_index < floors.size()-1:
				floor_index += 1
				enter_floor()
		"up":
			if floor_index == 0: return_home()
			else:
				floor_index -= 1
				enter_floor(true)
		"return": return_home()

func accept_quest(id: String) -> void:
	var map = QuestSystem.accept(state,id)
	save_game()
	if map.is_empty(): ui.show_board()
	else: ui.announce_map(map)

func claim_quest(id: String) -> void:
	var before = state.completed.size()
	var map = QuestSystem.claim(state,id)
	save_game()
	if map.is_empty():
		ui.show_board()
		if state.completed.size() > before: ui.toast("Commission complete. Your reward is in your satchel.")
	else: ui.announce_map(map)

func begin_expedition(entry: Dictionary) -> void:
	if world.mode == "dungeon" or battle != null: return
	active_map = entry
	entry.visits += 1
	state.hub.expeditions += 1
	floors = GrottoGenerator.generate(entry.meta)
	floor_progress = []
	for floor_data in floors:
		var key = str(floor_data.index)
		if not entry.explored.has(key): entry.explored[key] = {}
		floor_progress.append({"opened":[],"defeated":[],"seen":entry.explored[key],"boss_dead":false})
	expedition_rng = SeedRng.new(state.campaign_seed + state.hub.expeditions * 65537 + entry.meta.seed)
	floor_index = 0
	ui.close()
	enter_floor()
	ui.toast("%s · Expedition %d. This place is yours to revisit." % [entry.meta.environment,entry.visits])

func enter_floor(from_below: bool = false) -> void:
	world.show_floor(floors[floor_index],active_map.meta,floor_progress[floor_index],from_below)
	active_map.deepest = maxi(active_map.deepest,floor_index+1)
	QuestSystem.event(state,"depth",mini(floor_index+1,active_map.meta.depth))
	if floors[floor_index].unusual != "":
		active_map.floor_notes[str(floor_index+1)] = floors[floor_index].unusual
		ui.toast("An unusual population: " + floors[floor_index].unusual)
	save_game()
	ui.update_hud()

func open_chest(index: int) -> void:
	if floor_progress[floor_index].opened.has(index): return
	floor_progress[floor_index].opened.append(index)
	var chest = floors[floor_index].chests[index]
	var loot = LootSystem.roll(chest.rank,expedition_rng)
	state.give(loot.id,loot.amount)
	QuestSystem.event(state,"chest")
	var item_name = "crowns" if loot.id == "gold" else Content.item(loot.id).name
	var note = "B%d · Rank %d · %s" % [floor_index+1,chest.rank,item_name]
	if not active_map.treasure.has(note): active_map.treasure.append(note)
	save_game()
	world.sync_entities()
	ui.show_chest(item_name,loot.amount,chest.rank)

func begin_battle(index: int, boss: bool) -> void:
	if boss and floor_progress[floor_index].boss_dead: return
	if not boss and floor_progress[floor_index].defeated.has(index): return
	if not boss and not world.encounters.has(index): return
	battle_enemy_index = index
	var enemy: Dictionary
	if boss: enemy = Content.boss(active_map.meta.boss_tier)
	else:
		var encounter = world.encounters[index]
		enemy = Content.monster(active_map.meta.environment,encounter.rank,encounter.variant)
		if encounter.rare:
			enemy.name = "Lumen " + enemy.name
			enemy.xp *= 4
	if not active_map.monsters.has(enemy.name): active_map.monsters.append(enemy.name)
	battle = Combat.new(state,enemy,expedition_rng.next())
	world.blocked = true
	ui.show_combat()

func combat_action(action: String) -> void:
	if battle == null: return
	if not battle.act(action): return
	ui.update_hud()
	if battle.outcome == "": ui.show_combat(); return
	var result = battle.outcome
	var enemy = battle.enemy
	battle = null
	ui.close()
	if result == "defeat":
		var lost = int(state.player.gold / 10)
		state.player.gold -= lost
		state.rest()
		return_home()
		world.enter_building(Content.table("hub").buildings[4])
		ui.toast("Ione brought you home. Lost %d crowns; your atlas and belongings are safe." % lost)
	elif result == "fled":
		world.disengage(battle_enemy_index)
		ui.toast("Escaped. No rewards earned.")
	else:
		var gained = state.gain_xp(enemy.xp)
		state.give("gold",enemy.gold)
		if enemy.boss:
			floor_progress[floor_index].boss_dead = true
			world.boss_dead = true
			active_map.clears += 1
			state.hub.boss_wins += 1
			QuestSystem.event(state,"boss")
			var entry = state.reward_map(active_map.meta.displayed_level,"Keeper of " + active_map.meta.name)
			ui.announce_map(entry)
			ui.toast("Keeper defeated! +%d XP, +%d crowns%s. Return home when ready." % [enemy.xp,enemy.gold," · LEVEL UP" if gained > 0 else ""])
		else:
			floor_progress[floor_index].defeated.append(battle_enemy_index)
			QuestSystem.event(state,"monster")
			var material = ""
			if expedition_rng.between(1,100) <= 30:
				state.give(enemy.material)
				material = " + " + Content.item(enemy.material).name
			ui.toast("Victory! +%d XP, +%d crowns%s%s" % [enemy.xp,enemy.gold,material," · LEVEL UP!" if gained > 0 else ""])
	world.sync_entities()
	world.encounter_grace = 2.5
	save_game()

func return_home() -> void:
	if battle != null: return
	ui.close()
	world.show_hub()
	active_map = {}
	floors = []
	floor_progress = []
	save_game()
	ui.toast("Back in Bellwether. Rest at the inn and report to the bulletin board.")
