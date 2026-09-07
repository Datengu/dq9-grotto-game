class_name WorldView
extends Node2D
signal interaction(kind: String, payload: Variant)
signal moved
var mode = "hub"
var building: Dictionary = {}
var floor_data: Dictionary = {}
var meta: Dictionary = {}
var player = Vector2i(13,10)
var drawn_player = Vector2(13,10)
var blocked = false
var step_timer = 0.0
var time = 0.0
var discovered: Dictionary = {}
var opened: Array = []
var defeated: Array = []
var boss_dead = false
var npcs: Array = []
var hub = Content.table("hub")
var hint = ""
var font = ThemeDB.fallback_font
const ORIGIN = Vector2(34,139)

func _ready() -> void:
	npcs = hub.npcs.duplicate(true)

func tile_size() -> int:
	return 24 if mode == "dungeon" else 30

func show_hub() -> void:
	mode = "hub"
	player = Vector2i(13,10)
	drawn_player = Vector2(player)
	queue_redraw()

func enter_building(info: Dictionary) -> void:
	building = info
	mode = "interior"
	player = Vector2i(13,14)
	drawn_player = Vector2(player)
	queue_redraw()

func show_floor(data: Dictionary, metadata: Dictionary, progress: Dictionary, from_below: bool = false) -> void:
	mode = "dungeon"
	floor_data = data
	meta = metadata
	opened = progress.opened
	defeated = progress.defeated
	discovered = progress.seen
	boss_dead = progress.boss_dead
	var spawn: Array = data.stairs if from_below and not data.stairs.is_empty() else data.entrance
	player = Vector2i(spawn[0],spawn[1])
	drawn_player = Vector2(player)
	reveal()
	queue_redraw()

func _process(delta: float) -> void:
	time += delta
	step_timer -= delta
	drawn_player = drawn_player.lerp(Vector2(player),minf(1,delta * 20))
	if not blocked and step_timer <= 0:
		var direction = Vector2i.ZERO
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP): direction = Vector2i.UP
		elif Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN): direction = Vector2i.DOWN
		elif Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT): direction = Vector2i.LEFT
		elif Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT): direction = Vector2i.RIGHT
		if direction != Vector2i.ZERO:
			step(direction)
			step_timer = 0.105
	if mode == "hub":
		for npc in npcs:
			npc.pos = npc.route[int(time / 2.3) % npc.route.size()]
	hint = nearest().get("label", "WASD / arrows to walk")
	queue_redraw()

func walkable(p: Vector2i) -> bool:
	if mode == "dungeon":
		return p.x >= 0 and p.x < 35 and p.y >= 0 and p.y < 23 and floor_data.tiles[p.y * 35 + p.x] == 1
	if mode == "interior":
		return p.x >= 7 and p.x <= 19 and p.y >= 5 and p.y <= 15 and not (p.y == 8 and p.x >= 9 and p.x <= 17)
	if p.x < 1 or p.x > 25 or p.y < 1 or p.y > 17:
		return false
	for b in hub.buildings:
		var r = b.rect
		if Rect2i(r[0],r[1],r[2],r[3]).has_point(p): return false
	if p == Vector2i(13,6) or Rect2i(12,11,3,2).has_point(p): return false
	return true

func step(direction: Vector2i) -> void:
	var target = player + direction
	if not walkable(target): return
	player = target
	if mode == "dungeon":
		reveal()
		for i in floor_data.enemies.size():
			if not defeated.has(i) and as_pos(floor_data.enemies[i].pos) == player:
				interaction.emit("enemy",i)
		if not boss_dead and not floor_data.boss.is_empty() and as_pos(floor_data.boss) == player:
			interaction.emit("boss",0)
	moved.emit()

func reveal() -> void:
	for y in range(maxi(0,player.y-6),mini(23,player.y+7)):
		for x in range(maxi(0,player.x-6),mini(35,player.x+7)):
			if Vector2(x,y).distance_to(Vector2(player)) < 6.3:
				discovered[str(y * 35 + x)] = true

func as_pos(value: Array) -> Vector2i:
	return Vector2i(value[0],value[1])

func near(value: Array) -> bool:
	var p = as_pos(value)
	return absi(player.x - p.x) + absi(player.y - p.y) <= 1

func nearest() -> Dictionary:
	if mode == "hub":
		if near(hub.board): return {"kind":"board","payload":0,"label":"E  ·  Read the expedition bulletin"}
		for b in hub.buildings:
			if near(b.door): return {"kind":"door","payload":b,"label":"E  ·  Enter " + b.name.to_lower()}
		for npc in npcs:
			if near(npc.pos): return {"kind":"npc","payload":npc,"label":"E  ·  Talk to " + npc.name}
	elif mode == "interior":
		if near([13,9]): return {"kind":"service","payload":building,"label":"E  ·  Speak to " + building.keeper}
		if near([13,15]): return {"kind":"exit","payload":0,"label":"E  ·  Return to Bellwether"}
		if building.id == "inn" and near([18,12]): return {"kind":"book","payload":0,"label":"E  ·  Open your atlas at the writing desk"}
	else:
		for i in floor_data.chests.size():
			if not opened.has(i) and near(floor_data.chests[i].pos):
				return {"kind":"chest","payload":i,"label":"E  ·  Open rank %d chest" % floor_data.chests[i].rank}
		if not floor_data.boss.is_empty() and near(floor_data.boss) and not boss_dead:
			return {"kind":"boss","payload":0,"label":"E  ·  Challenge the keeper"}
		if near(floor_data.entrance):
			return {"kind":"up","payload":0,"label":"E  ·  " + ("Leave the grotto" if floor_data.index == 0 else "Ascend one floor")}
		if not floor_data.stairs.is_empty() and near(floor_data.stairs):
			return {"kind":"down","payload":0,"label":"E  ·  Descend"}
		if boss_dead and near(floor_data.boss): return {"kind":"return","payload":0,"label":"E  ·  Follow the light home"}
	return {}

func interact() -> void:
	var target = nearest()
	if not target.is_empty(): interaction.emit(target.kind,target.payload)

func text_at(text: String, pos: Vector2, size: int = 14, color: Color = Color("d8d8c9")) -> void:
	draw_string(font,pos,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func tile_rect(p: Vector2, scale_value: float = 1.0) -> Rect2:
	return Rect2(ORIGIN + p * tile_size(),Vector2.ONE * tile_size() * scale_value)

func _draw() -> void:
	draw_style_box(panel_style(Color("101f26")),Rect2(18,112,884,610))
	if mode == "hub": draw_hub()
	elif mode == "interior": draw_interior()
	elif not floor_data.is_empty(): draw_dungeon()
	var center = ORIGIN + (drawn_player + Vector2(0.5,0.5)) * tile_size()
	actor(center,Color("eed5a1"),"hero",tile_size() * 0.39)
	draw_circle(center + Vector2(7,-10),3,Color("f8df88"))
	draw_style_box(panel_style(Color("142832")),Rect2(34,736,850,42))
	text_at(hint,Vector2(53,763),16,Color("e9d6a7"))

func panel_style(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style

func draw_hub() -> void:
	for y in 18:
		for x in 27:
			var path = x in [4,5,6,12,13,14,21,22,23] or y in [6,7,8,9,10,15,16]
			var color = Color("52635a") if path else Color("344f44")
			if (x * 3 + y * 7) % 5 == 0: color = color.lightened(0.035)
			draw_rect(tile_rect(Vector2(x,y)).grow(-0.5),color)
	for b in hub.buildings:
		var r = b.rect
		var rect = Rect2(ORIGIN + Vector2(r[0],r[1]) * 30,Vector2(r[2],r[3]) * 30)
		draw_rect(Rect2(rect.position + Vector2(5,7), rect.size),Color("273c36"))
		draw_rect(rect,Color("bdac8a"))
		draw_rect(Rect2(rect.position,Vector2(rect.size.x,rect.size.y * 0.56)),Color(b.color))
		for stripe in range(1,5):
			draw_line(rect.position + Vector2(0,stripe * 11),rect.position + Vector2(rect.size.x,stripe * 11),Color(0,0,0,0.1),2)
		draw_rect(Rect2(rect.position + Vector2(18,rect.size.y - 30),Vector2(19,18)),Color("edcb78"))
		draw_rect(Rect2(rect.end - Vector2(38,30),Vector2(19,18)),Color("edcb78"))
		var door = ORIGIN + Vector2(b.door[0],b.door[1]) * 30
		draw_rect(Rect2(door-Vector2(0,23),Vector2(29,30)),Color("293b37"))
		text_at(b.name,rect.position + Vector2(8,rect.size.y * 0.56 + 19),12,Color("303b38"))
	# Fountain, flowers, benches, lamps and a conspicuous real board.
	draw_circle(ORIGIN + Vector2(13.5,12)*30,39,Color("82958b"))
	draw_circle(ORIGIN + Vector2(13.5,12)*30,29,Color("548e9b"))
	draw_arc(ORIGIN + Vector2(13.5,12)*30,20 + sin(time)*2,0,TAU,32,Color("a1c8c3"),2)
	for p in [Vector2(9,4),Vector2(18,4),Vector2(9,15),Vector2(18,15),Vector2(2,8),Vector2(25,8)]:
		var v = ORIGIN + (p + Vector2.ONE * 0.5) * 30
		draw_rect(Rect2(v - Vector2(3,8),Vector2(6,20)),Color("8d7d5d"))
		draw_circle(v-Vector2(0,9),7,Color("f0ce80"))
	var board = ORIGIN + Vector2(13,6) * 30
	draw_rect(Rect2(board-Vector2(9,9),Vector2(48,34)),Color("a5855c"))
	draw_rect(Rect2(board-Vector2(5,5),Vector2(40,23)),Color("3d4b40"))
	for i in 3: draw_rect(Rect2(board+Vector2(-1+i*12,-1),Vector2(8,14)),Color("e7d3a6"))
	text_at("COMMISSIONS",board+Vector2(-33,-18),13,Color("f1deb3"))
	for npc in npcs:
		var p = ORIGIN + (Vector2(npc.pos[0],npc.pos[1])+Vector2.ONE*0.5)*30
		actor(p,Color(npc.color),"hero",11)
		text_at(npc.name,p+Vector2(-20,-20),12)
	text_at("BELLWETHER  /  SURVEYOR'S QUARTER",ORIGIN+Vector2(260,548),13,Color("91a49b"))

func draw_interior() -> void:
	var room = Rect2(ORIGIN + Vector2(6,4)*30,Vector2(15,12)*30)
	draw_rect(room.grow(8),Color("8d8c77"))
	draw_rect(room,Color("665e4e"))
	for y in range(4,16):
		draw_line(ORIGIN+Vector2(6,y)*30,ORIGIN+Vector2(21,y)*30,Color("746951"),1)
	text_at(building.name,room.position+Vector2(26,30),22,Color("eadab6"))
	draw_rect(Rect2(ORIGIN+Vector2(9,8)*30,Vector2(9,1)*30),Color("a18b65"))
	actor(ORIGIN+Vector2(13.5,7.3)*30,Color(building.color).lightened(0.3),"hero",13)
	text_at(building.keeper,ORIGIN+Vector2(12.8,6.5)*30,16)
	for x in [7,18]:
		draw_rect(Rect2(ORIGIN+Vector2(x,5)*30,Vector2(2,2)*30),Color("baa780"))
		text_at("SUPPLIES" if building.id == "items" else "STOCK",ORIGIN+Vector2(x,6.2)*30,10,Color("354440"))
	if building.id == "inn":
		draw_rect(Rect2(ORIGIN+Vector2(8,11)*30,Vector2(3,3)*30),Color("829797"))
		draw_rect(Rect2(ORIGIN+Vector2(8,11)*30,Vector2(3,0.7)*30),Color("ddd3b9"))
		draw_rect(Rect2(ORIGIN+Vector2(18,12)*30,Vector2(1.5,1)*30),Color("a98d65"))
		draw_rect(Rect2(ORIGIN+Vector2(18.2,12.1)*30,Vector2(0.8,0.7)*30),Color("e3d4ae"))
		text_at("YOUR ROOM",ORIGIN+Vector2(8,10.6)*30,12)
	text_at("EXIT",ORIGIN+Vector2(12.9,15.9)*30,14,Color("efdaad"))

func draw_dungeon() -> void:
	var palette = {"Cavern":["3b3934","716b51"],"Ruins":["293b40","50646a"],"Ember":["412d2d","79574b"],"Tidal":["243d48","48727a"],"Frost":["364456","708c9d"]}[meta.environment]
	for y in 23:
		for x in 35:
			var index = y * 35 + x
			var rect = tile_rect(Vector2(x,y))
			if not discovered.has(str(index)):
				draw_rect(rect,Color("101b22"))
				continue
			var wall = floor_data.tiles[index] == 0
			var color = Color(palette[0] if wall else palette[1])
			if (x*13+y*7)%7 == 0: color = color.lightened(0.06)
			draw_rect(rect.grow(-0.4),color)
			if wall:
				draw_line(rect.position,rect.position+Vector2(24,0),color.lightened(0.13),2)
			elif (x+y)%6 == 0:
				draw_line(rect.position+Vector2(4,18),rect.position+Vector2(10,18),color.darkened(0.18),1)
	stairs_at(floor_data.entrance,false)
	if not floor_data.stairs.is_empty(): stairs_at(floor_data.stairs,true)
	for i in floor_data.chests.size():
		var chest = floor_data.chests[i]
		if not discovered.has(str(int(chest.pos[1])*35+int(chest.pos[0]))): continue
		var p = ORIGIN + Vector2(chest.pos[0],chest.pos[1])*24
		draw_rect(Rect2(p+Vector2(3,6),Vector2(18,14)),Color("716e5b") if opened.has(i) else Color("d4ae6b"))
		draw_line(p+Vector2(3,11),p+Vector2(21,11),Color("5c574a"),2)
		if not opened.has(i): draw_rect(Rect2(p+Vector2(10,10),Vector2(4,5)),Color("fff0a9"))
	for i in floor_data.enemies.size():
		var enemy = floor_data.enemies[i]
		if defeated.has(i) or not discovered.has(str(int(enemy.pos[1])*35+int(enemy.pos[0]))): continue
		var info = Content.monster(meta.environment,enemy.rank,enemy.variant)
		actor(ORIGIN+(Vector2(enemy.pos[0],enemy.pos[1])+Vector2.ONE*0.5)*24,Color(info.color),info.shape,10)
	if not floor_data.boss.is_empty() and discovered.has(str(int(floor_data.boss[1])*35+int(floor_data.boss[0]))):
		var p = ORIGIN+(Vector2(floor_data.boss[0],floor_data.boss[1])+Vector2.ONE*0.5)*24
		if boss_dead:
			draw_circle(p,18,Color("b9dab7"))
			text_at("HOME",p+Vector2(-19,4),11,Color("294638"))
		else:
			var boss = Content.boss(meta.boss_tier)
			draw_arc(p,26,0,TAU,32,Color("d7b97c"),2)
			actor(p,Color(boss.color),boss.shape,20)

func stairs_at(pos: Array, down: bool) -> void:
	if not discovered.has(str(int(pos[1])*35+int(pos[0]))): return
	var origin = ORIGIN + Vector2(pos[0],pos[1])*24
	draw_rect(Rect2(origin,Vector2.ONE*24),Color("203039"))
	for i in 4:
		draw_line(origin+Vector2(3+i*2,5+i*4),origin+Vector2(21,5+i*4),Color("e4c787") if down else Color("9cc9c3"),2)

func actor(p: Vector2, color: Color, shape: String, radius: float) -> void:
	paint_ellipse(p+Vector2(0,radius*0.75),Vector2(radius,radius*0.4),Color(0,0,0,0.25))
	match shape:
		"hero":
			draw_colored_polygon(PackedVector2Array([p+Vector2(-radius*0.7,radius),p+Vector2(radius*0.7,radius),p+Vector2(radius*0.45,-radius*0.5),p+Vector2(-radius*0.45,-radius*0.5)]),color.darkened(0.15))
			draw_circle(p-Vector2(0,radius*0.5),radius*0.5,Color("e2c69f"))
			draw_arc(p-Vector2(0,radius*0.5),radius*0.55,PI,TAU,12,color.darkened(0.3),4)
		"moth":
			paint_ellipse(p-Vector2(radius*0.6,0),Vector2(radius*0.65,radius),color)
			paint_ellipse(p+Vector2(radius*0.6,0),Vector2(radius*0.65,radius),color)
			draw_line(p-Vector2(0,radius),p+Vector2(0,radius),color.darkened(0.5),4)
		"golem":
			draw_rect(Rect2(p-Vector2(radius*0.75,radius),Vector2(radius*1.5,radius*1.8)),color)
			draw_rect(Rect2(p+Vector2(-radius*1.15,-radius*0.3),Vector2(radius*0.4,radius)),color.darkened(0.15))
			draw_rect(Rect2(p+Vector2(radius*0.75,-radius*0.3),Vector2(radius*0.4,radius)),color.darkened(0.15))
		"wolf":
			draw_colored_polygon(PackedVector2Array([p+Vector2(-radius,radius*0.6),p+Vector2(-radius,-radius),p+Vector2(0,-radius*0.4),p+Vector2(radius,-radius),p+Vector2(radius,radius*0.6),p+Vector2(0,radius)]),color)
		_:
			for side in [-1,1]:
				for i in 3: draw_line(p+Vector2(side*radius*0.5,i*radius*0.5-radius*0.5),p+Vector2(side*radius*1.25,i*radius*0.7-radius*0.5),color.darkened(0.2),2)
			draw_circle(p,radius*0.8,color)
	if shape != "hero":
		for side in [-1,1]: draw_circle(p+Vector2(side*radius*0.3,-radius*0.25),maxf(2,radius*0.12),Color("18282e"))

func paint_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points = PackedVector2Array()
	for i in 24: points.append(center+Vector2(cos(i*TAU/24),sin(i*TAU/24))*radii)
	draw_colored_polygon(points,color)


