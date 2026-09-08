class_name FloorGeneratorV2
extends RefCounted
## A graph grows in unbounded integer space; its footprint is cropped afterwards.
## v1 stays frozen in floor_generator.gd for existing charts.
static func generate(meta: Dictionary, index: int) -> Dictionary:
	var rng = SeedRng.new(int(meta.seed) + int(meta.grotto_rank) * 104729 + (index+1)*7919 + 2000003)
	var cells: Dictionary = {}
	var rooms: Array[Rect2i] = []
	var edges: Array = []
	var boss = index == int(meta.depth)
	var rank = GrottoGenerator.floor_rank(meta,index)
	var complexity = int(meta.grotto_rank)
	var room_count = rng.between(3 + int(complexity/4), 5 + int(complexity/2) + int(index/5))
	var anomaly = rng.between(1,12)
	if anomaly == 1: room_count += 4
	if anomaly == 2 and complexity >= 6: room_count = rng.between(3,5)
	if boss: room_count = 1
	rooms.append(Rect2i(0,0, rng.between(6,9) if not boss else 13, rng.between(5,8) if not boss else 13))
	var attempts = 0
	while rooms.size() < room_count and attempts < 1000:
		attempts += 1
		var parent_index = rng.between(0,rooms.size()-1)
		var parent = rooms[parent_index]
		var w = rng.between(5,9 + int(complexity/5))
		var h = rng.between(5,8 + int(complexity/5))
		var gap = rng.between(3,7 + int(complexity/3))
		var dir = rng.between(0,3)
		var origin: Vector2i
		match dir:
			0: origin = Vector2i(parent.end.x + gap,parent.position.y + rng.between(-3,3))
			1: origin = Vector2i(parent.position.x - gap - w,parent.position.y + rng.between(-3,3))
			2: origin = Vector2i(parent.position.x + rng.between(-3,3),parent.end.y + gap)
			_: origin = Vector2i(parent.position.x + rng.between(-3,3),parent.position.y - gap - h)
		var candidate = Rect2i(origin,Vector2i(w,h))
		var overlap = false
		for existing in rooms:
			if candidate.grow(2).intersects(existing): overlap = true; break
		if overlap: continue
		edges.append([parent_index,rooms.size()])
		rooms.append(candidate)
	for r in rooms:
		for y in range(r.position.y,r.end.y):
			for x in range(r.position.x,r.end.x):
				var corner = (x == r.position.x or x == r.end.x-1) and (y == r.position.y or y == r.end.y-1)
				if not corner or meta.environment == "Ruins" or boss: cells[Vector2i(x,y)] = true
	var loops = rng.between(0,maxi(0,int(complexity/4)))
	for i in loops:
		var a = rng.between(0,rooms.size()-1)
		var b = rng.between(0,rooms.size()-1)
		if a != b: edges.append([a,b])
	for edge in edges:
		var a = rooms[edge[0]].get_center()
		var b = rooms[edge[1]].get_center()
		var bend = Vector2i(a.x,b.y) if rng.between(0,1) == 0 else Vector2i(b.x,a.y)
		for ends in [[a,bend],[bend,b]]:
			var p: Vector2i = ends[0]
			while true:
				# Two-cell-wide passages comfortably fit a single-file party.
				for d in [Vector2i.ZERO,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.ONE]: cells[p+d] = true
				if p == ends[1]: break
				p += Vector2i(signi(ends[1].x-p.x),signi(ends[1].y-p.y))
	var low = Vector2i(100000,100000)
	var high = Vector2i(-100000,-100000)
	for p in cells:
		low = low.min(p)
		high = high.max(p)
	low -= Vector2i.ONE
	high += Vector2i.ONE
	var dimensions = high-low+Vector2i.ONE
	var tiles: Array = []
	tiles.resize(dimensions.x*dimensions.y)
	tiles.fill(0)
	for p in cells:
		var c: Vector2i = p-low
		tiles[c.y*dimensions.x+c.x] = 1
	var start = rooms[0].get_center()-low
	if boss: start = rooms[0].position-low+Vector2i(6,11)
	var data = {"width":dimensions.x,"height":dimensions.y,"tiles":tiles,"entrance":[start.x,start.y],
		"stairs":[],"boss":[],"chests":[],"enemies":[],"rank":rank,"index":index,"unusual":"",
		"room_count":rooms.size(),"links":edges.size(),"rooms":[]}
	for r in rooms:
		data.rooms.append([r.position.x-low.x,r.position.y-low.y,r.size.x,r.size.y])
	if boss:
		var goal = rooms[0].get_center()-low-Vector2i(0,3)
		data.boss = [goal.x,goal.y]
		return data
	var distances = reachable(data,data.entrance)
	var finish = start
	var longest = 0
	for r in rooms:
		var c = r.get_center()-low
		var distance = int(distances.get(c.y*dimensions.x+c.x,0))
		if distance > longest: longest = distance; finish = c
	data.stairs = [finish.x,finish.y]
	var spots: Array = []
	for r in rooms:
		for y in range(r.position.y+1,r.end.y-1):
			for x in range(r.position.x+1,r.end.x-1):
				var p = Vector2i(x,y)-low
				if p.distance_to(start) > 4 and p.distance_to(finish) > 1.5:
					spots.append([p.x,p.y])
	if index >= 2:
		var bounds = Content.table("generation").chest_ranges[rank-1]
		for i in rng.between(1,3):
			data.chests.append({"pos":spots.pop_at(rng.between(0,spots.size()-1)),"rank":rng.between(bounds[0],bounds[1])})
	var rare = rank >= 5 and rng.between(1,160) == 1
	if rare: data.unusual = "Lumen colony"
	for i in rng.between(2,mini(7,rooms.size()+1)):
		data.enemies.append({"pos":spots.pop_at(rng.between(0,spots.size()-1)),"rank":rank,"variant":2 if rare else rng.between(0,2),"rare":rare})
	return data

static func reachable(data: Dictionary, start: Array) -> Dictionary:
	var width = int(data.width)
	var origin = int(start[1])*width+int(start[0])
	var seen = {origin:0}
	var queue = [origin]
	var head = 0
	while head < queue.size():
		var p: int = queue[head]
		head += 1
		for d in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
			var x = p%width+d.x
			var y = int(p/width)+d.y
			var n = y*width+x
			if x >= 0 and y >= 0 and x < width and y < data.height and data.tiles[n] == 1 and not seen.has(n):
				seen[n] = seen[p]+1
				queue.append(n)
	return seen
