class_name GameUI
extends CanvasLayer
var game: Node
var root: Control
var overlay: Control
var body: VBoxContainer
var hud: Label
var location_label: Label
var tip: Label
var toast_label: Label
var toast_time = 0.0
var screen = ""
var selected_map = ""
var book_filter = ""
var only_favourites = false
var sort_level = false
const GOLD = Color("e4c58a")
const INK = Color("dce6df")

func _init(controller: Node) -> void:
	game = controller

func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.theme = make_theme()
	var title = Label.new()
	title.text = "LANTERN ATLAS"
	title.position = Vector2(34,23)
	title.add_theme_font_size_override("font_size",29)
	title.add_theme_color_override("font_color",GOLD)
	root.add_child(title)
	location_label = Label.new()
	location_label.position = Vector2(35,72)
	location_label.add_theme_font_size_override("font_size",17)
	root.add_child(location_label)
	var side = PanelContainer.new()
	side.position = Vector2(925,25)
	side.size = Vector2(330,752)
	root.add_child(side)
	var margin = MarginContainer.new()
	for key in ["margin_left","margin_right","margin_top","margin_bottom"]: margin.add_theme_constant_override(key,20)
	side.add_child(margin)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation",10)
	margin.add_child(column)
	label(column,"THE SURVEYOR",20,GOLD)
	hud = label(column,"",16)
	column.add_child(HSeparator.new())
	button(column,"B   Treasure atlas",show_book)
	button(column,"I    Satchel & equipment",show_inventory)
	button(column,"J    Commission journal",func(): show_board(false))
	button(column,"Return to Bellwether",func():
		if game.world.mode == "dungeon" and game.battle == null: game.return_home()
		else: toast("You are already in town."))
	button(column,"Save progress",func(): game.save_game(true))
	column.add_child(HSeparator.new())
	label(column,"FIELD NOTES",15,GOLD)
	tip = label(column,"",14,Color("aabfb9"))
	tip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button(column,"Controls & field guide",show_help)
	label(column,"An original grotto RPG · v0.1",12,Color("819c99"))
	toast_label = Label.new()
	toast_label.position = Vector2(210,33)
	toast_label.size = Vector2(680,68)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.add_theme_font_size_override("font_size",16)
	toast_label.add_theme_color_override("font_color",GOLD)
	root.add_child(toast_label)
	update_hud()

func make_theme() -> Theme:
	var theme = Theme.new()
	theme.default_font_size = 16
	theme.set_color("font_color","Label",INK)
	theme.set_color("font_color","Button",INK)
	theme.set_color("font_disabled_color","Button",Color("657d80"))
	for state_name in ["normal","hover","pressed","disabled","focus"]:
		var style = StyleBoxFlat.new()
		style.bg_color = Color("25444c") if state_name == "normal" else Color("39616a")
		if state_name == "disabled": style.bg_color = Color("1a2c32")
		style.set_corner_radius_all(5)
		style.content_margin_left = 12
		style.content_margin_right = 12
		style.content_margin_top = 9
		style.content_margin_bottom = 9
		if state_name == "focus":
			style.bg_color = Color(0,0,0,0)
			style.set_border_width_all(2)
			style.border_color = GOLD
		theme.set_stylebox(state_name,"Button",style)
	var panel = StyleBoxFlat.new()
	panel.bg_color = Color("142a32")
	panel.set_corner_radius_all(9)
	panel.set_border_width_all(1)
	panel.border_color = Color("39535a")
	theme.set_stylebox("panel","PanelContainer",panel)
	return theme

func _process(delta: float) -> void:
	toast_time -= delta
	toast_label.visible = toast_time > 0

func update_hud() -> void:
	if hud == null: return
	var p = game.state.player
	var s = game.state.stats()
	hud.text = "Level %d     ·     %d crowns\n\nHP   %d / %d      MP   %d / %d\nAttack  %d    Defence  %d\nSpeed   %d    ·    XP   %d / %d%s" % [p.level,p.gold,p.hp,s.max_hp,p.mp,s.max_mp,s.attack,s.defence,s.speed,p.xp,game.state.xp_needed(),"\nPOISONED · Clearleaf cures" if p.poison > 0 else ""]
	if game.world.mode == "dungeon":
		var meta = game.active_map.meta
		location_label.text = "%s   ·   Lv. %d" % [meta.name,meta.displayed_level]
		tip.text = "FLOOR %d / %d\n%s · Monster rank %d\n\n%s\n\nChests and stairs stay in place.\nE · Stairs or treasure" % [game.floor_index+1,meta.depth+1,meta.environment,game.world.floor_data.rank,"Keeper's chamber" if game.floor_index == meta.depth else "Find the golden descending stairs."]
	else:
		location_label.text = "BELLWETHER   /   " + ("A place to return to" if game.world.mode == "hub" else game.world.building.name)
		tip.text = "%d permanent maps · %d keepers defeated\n\n%s\n\nWASD / arrows · Walk   E · Interact\nB · Atlas    I · Satchel    J · Journal" % [game.state.maps.size(),game.state.hub.boss_wins,"Begin at the bulletin board, north of the fountain." if game.state.maps.is_empty() else "Visit a shop, equip your gear, then choose a map from the atlas."]

func label(parent: Node, text: String, size: int = 16, color: Color = INK) -> Label:
	var node = Label.new()
	node.text = text
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size",size)
	node.add_theme_color_override("font_color",color)
	parent.add_child(node)
	return node

func button(parent: Node, text: String, callback: Callable, disabled: bool = false) -> Button:
	var node = Button.new()
	node.text = text
	node.disabled = disabled
	node.pressed.connect(callback)
	parent.add_child(node)
	return node

func row(parent: Node) -> HBoxContainer:
	var node = HBoxContainer.new()
	node.add_theme_constant_override("separation",12)
	parent.add_child(node)
	return node

func scroll(parent: Node, height: float = 390) -> VBoxContainer:
	var scroller = ScrollContainer.new()
	scroller.custom_minimum_size.y = height
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroller)
	var column = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",12)
	scroller.add_child(column)
	return column

func clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func modal(title: String, subtitle: String, id: String) -> VBoxContainer:
	close()
	screen = id
	game.world.blocked = true
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)
	var dim = ColorRect.new()
	dim.color = Color(0.025,0.04,0.05,0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var panel = PanelContainer.new()
	panel.position = Vector2(140,90)
	panel.size = Vector2(1000,620)
	overlay.add_child(panel)
	var margin = MarginContainer.new()
	for key in ["margin_left","margin_right","margin_top","margin_bottom"]: margin.add_theme_constant_override(key,26)
	panel.add_child(margin)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation",12)
	margin.add_child(body)
	var heading = row(body)
	var heading_label = label(heading,title,26,GOLD)
	heading_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if id != "combat": button(heading,"Close  ·  Esc",close)
	label(body,subtitle,15,Color("a4bdb8"))
	body.add_child(HSeparator.new())
	return body

func close() -> void:
	if is_instance_valid(overlay):
		root.remove_child(overlay)
		overlay.queue_free()
		overlay = null
	screen = ""
	if game.world != null: game.world.blocked = game.battle != null
	update_hud()

func toast(message: String) -> void:
	toast_label.text = message
	toast_time = 6.0
	update_hud()

func announce_map(entry: Dictionary) -> void:
	selected_map = entry.meta.id
	var box = modal("NEW TREASURE MAP ACQUIRED","A new place, now yours to keep.","reward")
	label(box,"✦",62,GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label(box,entry.meta.name,28,GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label(box,"Level %d  ·  %s  ·  %d floors + keeper\n\nRecorded as map %03d in your permanent atlas.\nSource: %s\n\nThe chart will always lead back to the same place." % [entry.meta.displayed_level,entry.meta.environment,entry.meta.depth,entry.order,entry.source],19).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button(box,"Open this page in the atlas",show_book)
	button(box,"Keep exploring",close)

func show_book() -> void:
	if game.battle != null: return
	var box = modal("The treasure atlas","Every chart is a permanent place. Revisit, learn, collect.","book")
	var toolbar = row(box)
	var search = LineEdit.new()
	search.placeholder_text = "Search name, environment or seed…"
	search.text = book_filter
	search.custom_minimum_size.x = 410
	toolbar.add_child(search)
	button(toolbar,"Favourites" if not only_favourites else "Show all",func(): only_favourites = not only_favourites; show_book())
	button(toolbar,"Sort: level" if sort_level else "Sort: discovery",func(): sort_level = not sort_level; show_book())
	button(toolbar,"Seed desk",show_seed_desk)
	var columns = row(box)
	var list_side = VBoxContainer.new()
	list_side.custom_minimum_size.x = 335
	columns.add_child(list_side)
	var entries = scroll(list_side,410)
	var detail_side = VBoxContainer.new()
	detail_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(detail_side)
	var details = scroll(detail_side,410)
	var fill = func():
		clear_children(entries)
		var maps = game.state.maps.duplicate()
		if sort_level: maps.sort_custom(func(a,b): return a.meta.displayed_level < b.meta.displayed_level)
		for entry in maps:
			if only_favourites and not entry.favourite: continue
			if not book_filter.is_empty() and not book_filter.to_lower() in (entry.meta.name + entry.meta.environment + str(entry.meta.seed)).to_lower(): continue
			var text = "%s %03d  ·  Lv.%d  ·  %s\n%s\n%s" % ["★" if entry.favourite else "◇",entry.order,entry.meta.displayed_level,entry.meta.environment,entry.meta.name,"Cleared %d times" % entry.clears if entry.clears > 0 else "Uncompleted"]
			var b = button(entries,text,func(): selected_map = entry.meta.id; fill_map_details(details,entry))
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if entries.get_child_count() == 0: label(entries,"No charts here yet. Accept 'A light below the hill' at the town's physical bulletin board.")
	fill.call()
	search.text_changed.connect(func(value): book_filter = value; fill.call())
	var selected = game.state.find_map(selected_map)
	if selected.is_empty() and not game.state.maps.is_empty(): selected = game.state.maps[0]
	if not selected.is_empty(): fill_map_details(details,selected)
	else: label(details,"Your journeys will fill these pages.",24,GOLD)

func fill_map_details(box: VBoxContainer, entry: Dictionary) -> void:
	clear_children(box)
	var m = entry.meta
	label(box,m.name,24,GOLD)
	label(box,"LEVEL %d   /   %s\n%d exploration floors + keeper chamber" % [m.displayed_level,m.environment,m.depth],18)
	label(box,"Visits %d   ·   Deepest B%d   ·   Clears %d\nKeeper: %s\nDiscovered #%03d · %s" % [entry.visits,entry.deepest,entry.clears,Content.boss(m.boss_tier).name if entry.clears > 0 else "Unidentified",entry.order,entry.discovered_at.substr(0,10)],16)
	var buttons = row(box)
	button(buttons,"Begin expedition",func(): game.begin_expedition(entry),game.world.mode == "dungeon")
	button(buttons,"★ Favourite" if entry.favourite else "☆ Favourite",func(): entry.favourite = not entry.favourite; game.save_game(); show_book())
	button(box,"Advanced chart details / share code",func(): show_map_details(entry))
	label(box,"TREASURE & FIELD OBSERVATIONS",14,GOLD)
	label(box,"\n".join(entry.treasure) if not entry.treasure.is_empty() else "No treasure recorded yet. Chests begin on B3.",15)
	label(box,"Known inhabitants: " + (", ".join(entry.monsters) if not entry.monsters.is_empty() else "unexplored"),15)
	label(box,"Personal notes",14,GOLD)
	var notes = TextEdit.new()
	notes.custom_minimum_size.y = 75
	notes.text = entry.notes
	box.add_child(notes)
	button(box,"Save note",func(): entry.notes = notes.text.left(2000); game.save_game(); toast("Atlas note saved."))

func show_map_details(entry: Dictionary) -> void:
	var m = entry.meta
	var box = modal("Chart details","Generation v1 · Our seeds are not compatible with Dragon Quest IX tools.","details")
	var fields = "Seed: %d\nBase quality: %d    Final quality: %d    Grotto rank: %d\nDisplayed level: %d    Depth: %d + boss\nStarting monster rank: %d    Deepest monster rank: %d\nBoss tier: %d    Environment: %s" % [m.seed,m.base_quality,m.final_quality,m.grotto_rank,m.displayed_level,m.depth,m.starting_monster_rank,GrottoGenerator.floor_rank(m,int(m.depth)-1),m.boss_tier,m.environment]
	label(box,fields,18)
	var ranks = {}
	for f in GrottoGenerator.generate(m):
		for chest in f.chests: ranks[str(chest.rank)] = int(ranks.get(str(chest.rank),0)) + 1
	label(box,"Treasure potential (chests by rank): " + JSON.stringify(ranks),17,GOLD)
	var code = LineEdit.new()
	code.text = m.id
	code.editable = false
	box.add_child(code)
	label(box,"Share this code at the seed desk to recreate the map. Quality is separate from displayed level; a strong treasure map can have an easier boss.",16)
	button(box,"Back to atlas",show_book)

func show_seed_desk() -> void:
	var box = modal("The seed desk","Optional experiments · Add a reproducible chart without replacing your collection.","seeds")
	label(box,"Paste a Lantern Atlas share code (LA1-XXXXXXXX-QQQ).\nOr enter a decimal seed and final quality below. These create charts only; they do not raise your character's level.",18)
	var code = LineEdit.new()
	code.placeholder_text = "LA1-00000000-002"
	box.add_child(code)
	var values = row(box)
	label(values,"Seed",16)
	var seed_input = SpinBox.new()
	seed_input.max_value = 2147483646
	seed_input.custom_minimum_size.x = 250
	values.add_child(seed_input)
	label(values,"Final quality",16)
	var quality = SpinBox.new()
	quality.min_value = 2
	quality.max_value = 248
	quality.value = 2
	values.add_child(quality)
	button(box,"Record this chart",func():
		var seed_value = int(seed_input.value)
		var q = int(quality.value)
		if not code.text.strip_edges().is_empty():
			var parts = code.text.strip_edges().split("-")
			if parts.size() != 3 or parts[0] != "LA1" or not parts[1].is_valid_hex_number() or not parts[2].is_valid_int():
				toast("Use a code such as LA1-00000000-002."); return
			seed_value = parts[1].hex_to_int()
			q = parts[2].to_int()
		if seed_value < 0 or seed_value > 2147483646 or q < 2 or q > 248:
			toast("Seed must be 0–2147483646; quality must be 2–248."); return
		var entry = game.state.add_map(GrottoGenerator.create(seed_value,q,q),"Seed desk experiment")
		game.save_game()
		announce_map(entry))
	button(box,"Back to atlas",show_book)

func show_board(physical: bool = true) -> void:
	if game.battle != null: return
	var box = modal("The expedition bulletin" if physical else "Commission journal","Accept and turn in work at the physical board in Bellwether." if not physical else "Local work. Unfamiliar places. A reason to light the lantern.","board")
	var list = scroll(box,435)
	for quest in Content.table("quests"):
		if not QuestSystem.available(game.state,quest): continue
		var complete = game.state.completed.has(quest.id)
		var active = game.state.quests.has(quest.id)
		label(list,quest.title + ("  ·  COMPLETE" if complete else ""),21,GOLD)
		label(list,"%s  ·  %d crowns%s\n%s" % [quest.category,quest.gold," + treasure map" if quest.get("map_reward",false) or quest.get("map_on_accept",false) else "",quest.description],16)
		if active and not complete:
			label(list,"Progress: %d / %d" % [game.state.quests[quest.id].progress,quest.target],16)
			button(list,"Claim reward",func(): game.claim_quest(quest.id),not physical or game.state.quests[quest.id].progress < quest.target)
		elif not complete:
			button(list,"Accept commission",func(): game.accept_quest(quest.id),not physical)
		list.add_child(HSeparator.new())

func show_inventory() -> void:
	if game.battle != null: return
	var box = modal("The travelling satchel","Equip gear here, or use supplies between battles. Equipped items cannot be sold.","inventory")
	label(box,"Weapon: %s   /   Armour: %s" % [Content.item(game.state.player.equipment.weapon).name,Content.item(game.state.player.equipment.armour).name],17,GOLD)
	var list = scroll(box,390)
	for id in game.state.player.inventory:
		var count = int(game.state.player.inventory[id])
		if count <= 0: continue
		var item = Content.item(id)
		var line = row(list)
		var desc = label(line,"%s  ×%d\n%s" % [item.name,count,item.description],16)
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if item.slot in ["weapon","armour"]:
			button(line,"Equipped" if game.state.player.equipment.values().has(id) else "Equip",func(): game.state.equip(id); game.save_game(); show_inventory(),game.state.player.equipment.values().has(id))
		elif item.slot == "supply":
			button(line,"Use",func(): game.state.use_item(id); game.save_game(); show_inventory())

func show_service(info: Dictionary) -> void:
	var box = modal(info.keeper + " · " + info.service,info.dialogue,"service")
	if info.id == "inn":
		label(box,"A hot meal, a clean bed, and a desk for your atlas.\n\nRest restores HP and MP and removes poison.\nYour survey guild covers the room for now.",20)
		button(box,"Rest until morning · Free",func(): game.state.rest(); game.save_game(); close(); toast("Rested. Your lantern burns brightly again."))
		button(box,"Open your atlas",show_book)
	elif info.id == "shrine":
		label(box,"The Still Flame watches over returning explorers.\n\nFallen explorers return here automatically, losing 10% of their crowns. Their atlas and belongings remain safe.",20)
		button(box,"Cleanse poison · Free",func(): game.state.player.poison = 0; game.save_game(); close(); toast("The flame leaves your spirit clear."))
	else:
		var tabs = row(box)
		button(tabs,"Buy",func(): show_shop(info,false))
		button(tabs,"Sell",func(): show_shop(info,true))
		fill_shop(box,info,false)

func show_shop(info: Dictionary, sell: bool) -> void:
	var box = modal(info.keeper + " · " + ("Sell" if sell else "Buy"),"%d crowns · Bought equipment must be equipped in your satchel." % game.state.player.gold,"service")
	var tabs = row(box)
	button(tabs,"Buy",func(): show_shop(info,false))
	button(tabs,"Sell",func(): show_shop(info,true))
	fill_shop(box,info,sell)

func fill_shop(box: Node, info: Dictionary, sell: bool) -> void:
	var list = scroll(box,350)
	for id in Content.table("items"):
		var item = Content.item(id)
		if sell:
			var reserved = 1 if game.state.player.equipment.values().has(id) else 0
			if game.state.player.inventory.get(id,0) <= reserved: continue
		else:
			if info.id == "weapon" and item.slot != "weapon": continue
			if info.id == "armour" and item.slot != "armour": continue
			if info.id == "items" and item.slot != "supply": continue
		var line = row(list)
		var locked = game.state.hub.boss_wins < item.get("unlock",0) and not sell
		var desc = label(line,"%s%s\n%s" % [item.name," · requires %d keeper wins" % item.unlock if locked else "",item.description],16)
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var price = maxi(1,int(item.price / 2)) if sell else int(item.price)
		button(line,"%s · %d c" % ["Sell" if sell else "Buy",price],func():
			if game.state.trade(id,sell): game.save_game(); show_shop(info,sell)
			else: toast("Trade unavailable."),locked or (not sell and game.state.player.gold < price))

func show_combat() -> void:
	var fight: Combat = game.battle
	var box = modal(fight.enemy.name,"KEEPER ENCOUNTER" if fight.enemy.boss else "A wandering inhabitant · Rank %d" % fight.enemy.rank,"combat")
	label(box,"Enemy HP  %d / %d      |      Your HP  %d / %d      MP  %d / %d" % [fight.enemy.hp,fight.enemy.max_hp,game.state.player.hp,game.state.stats().max_hp,game.state.player.mp,game.state.stats().max_mp],20,GOLD)
	var stage = Control.new()
	stage.custom_minimum_size = Vector2(900,95)
	box.add_child(stage)
	var portrait = CreaturePortrait.new()
	portrait.info = fight.enemy
	portrait.position = Vector2(450,49)
	stage.add_child(portrait)
	var lines = fight.log.slice(maxi(0,fight.log.size()-5))
	label(box,"\n".join(lines),17).custom_minimum_size.y = 120
	var actions = row(box)
	button(actions,"1  Attack",func(): game.combat_action("attack"))
	button(actions,"2  Spark · 4 MP",func(): game.combat_action("spark"),game.state.player.mp < 4)
	button(actions,"3  Mend · 5 MP",func(): game.combat_action("mend"),game.state.player.mp < 5)
	button(actions,"4  Guard · +3 MP",func(): game.combat_action("guard"))
	button(actions,"5  Flee",func(): game.combat_action("flee"),fight.enemy.boss)
	var supplies = row(box)
	for id in ["salve","tonic","remedy","heartfruit"]:
		var count = int(game.state.player.inventory.get(id,0))
		button(supplies,"%s ×%d" % [Content.item(id).name,count],func(): game.combat_action("item:"+id),count <= 0)
	label(box,"Guard reduces incoming damage, blocks poison and restores MP. Keepers use their special ability every third turn.",14,Color("a4bdb8"))

func show_help() -> void:
	if game.battle != null: return
	var box = modal("A surveyor's field guide","Welcome to Bellwether. Your first chart is waiting at the bulletin board.","help")
	var list = scroll(box,400)
	label(list,"01  A commission",21,GOLD)
	label(list,"Walk north from the fountain to the paper-covered board. Press E, accept 'A light below the hill', and record your first treasure map. Accept the other two jobs before leaving.")
	label(list,"02  Prepare in town",21,GOLD)
	label(list,"Walk to a shop door and press E to enter. Approach the counter and press E to trade. A copper sabre costs 65 crowns; a ring vest costs 60. Equip purchases with I. The inn offers free recovery.")
	label(list,"03  A place to keep",21,GOLD)
	label(list,"Press B to inspect your atlas and begin an expedition. Walk into visible monsters to fight. E opens nearby chests and uses stairs. Blue stairs go up; gold stairs go down. Chests begin on floor three. Descend again to find the keeper.")
	label(list,"04  Bring the light home",21,GOLD)
	label(list,"Defeat the keeper for another map. Use the return button or the keeper's portal to go home, rest, and claim completed commissions at the board. Revisit maps to farm their fixed chest ranks and monsters.")
	label(list,"Controls & saving",21,GOLD)
	label(list,"WASD / arrows: move · E: interact · B: atlas · I: inventory · J: journal · Esc: close\nBattle: 1 attack · 2 Spark · 3 Mend · 4 Guard · 5 flee\nProgress autosaves after discoveries, rewards, purchases and floor changes. Loading resumes safely in town. Expedition enemies and chests reset on a new visit. A backup save is kept. No network is required.")
