class_name FloorGenerator
extends RefCounted
const WIDTH = 35
const HEIGHT = 23

static func carve(tiles: Array, x: int, y: int) -> void:
	if x > 0 and y > 0 and x < WIDTH - 1 and y < HEIGHT - 1:
		tiles[y * WIDTH + x] = 1

static func corridor(tiles: Array, a: Vector2i, b: Vector2i, horizontal: bool) -> void:
	var corner = Vector2i(b.x, a.y) if horizontal else Vector2i(a.x, b.y)
	for ends in [[a, corner], [corner, b]]:
		var p: Vector2i = ends[0]
		var target: Vector2i = ends[1]
		while p != target:
			carve(tiles, p.x, p.y)
			p += Vector2i(signi(target.x - p.x), signi(target.y - p.y))
		carve(tiles, target.x, target.y)

static func generate(meta: Dictionary, index: int) -> Dictionary:
	var rng = SeedRng.new(int(meta.seed) + int(meta.grotto_rank) * 104729 + (index + 1) * 7919)
	var tiles: Array = []
	tiles.resize(WIDTH * HEIGHT)
	tiles.fill(0)
	var rooms: Array = []
	var boss_floor = index == int(meta.depth)
	var rank = GrottoGenerator.floor_rank(meta, index)
	if boss_floor:
		for y in range(5, 18):
			for x in range(7, 28):
				carve(tiles, x, y)
		return {"width": WIDTH, "height": HEIGHT, "tiles": tiles, "entrance": [17,17],
			"stairs": [], "chests": [], "enemies": [], "boss": [17,8], "rank": rank,
			"unusual": "", "index": index}
	# Nine jittered chambers; a randomized spanning tree guarantees connectivity.
	for gy in 3:
		for gx in 3:
			var w = rng.between(5, 9)
			var h = rng.between(3, 5)
			var x0 = 1 + gx * 11 + rng.between(0, 10 - w)
			var y0 = 1 + gy * 7 + rng.between(0, 6 - h)
			for y in range(y0, y0 + h):
				for x in range(x0, x0 + w):
					carve(tiles, x, y)
			rooms.append(Vector2i(x0 + int(w / 2), y0 + int(h / 2)))
	var visited = [rng.between(0, 8)]
	while visited.size() < 9:
		var edges: Array = []
		for a in visited:
			for b in 9:
				if not visited.has(b) and absi(int(a / 3) - int(b / 3)) + absi(a % 3 - b % 3) == 1:
					edges.append([a, b])
		var edge: Array = rng.pick(edges)
		corridor(tiles, rooms[edge[0]], rooms[edge[1]], rng.between(0, 1) == 0)
		visited.append(edge[1])
	# Extra links create alternative routes; environment changes corridor character.
	for i in rng.between(1, 3):
		corridor(tiles, rng.pick(rooms), rng.pick(rooms), meta.environment == "Ruins" or rng.between(0,1) == 0)
	var start: Vector2i = rooms[rng.between(0, 8)]
	var distances = reachable(tiles, [start.x, start.y])
	var finish = start
	var farthest = 0
	for p in rooms:
		var d = int(distances.get(p.y * WIDTH + p.x, 0))
		if d > farthest:
			farthest = d
			finish = p
	var available: Array = []
	for y in range(1, HEIGHT - 1):
		for x in range(1, WIDTH - 1):
			var p = Vector2i(x, y)
			if tiles[y * WIDTH + x] == 1 and p != start and p != finish and p.distance_to(start) > 3:
				available.append([x, y])
	var chests: Array = []
	var enemies: Array = []
	var unusual = ""
	if index >= 2:
		var chest_range = Content.table("generation").chest_ranges[rank - 1]
		for i in rng.between(1, 3):
			var selected = rng.between(0, available.size() - 1)
			chests.append({"pos": available.pop_at(selected), "rank": rng.between(chest_range[0], chest_range[1])})
	var special = rng.between(1, 160) == 1 and rank >= 5
	if special:
		unusual = "Lumen colony"
	for i in rng.between(3, 5):
		var selected = rng.between(0, available.size() - 1)
		enemies.append({"pos": available.pop_at(selected), "rank": rank, "variant": 2 if special else rng.between(0, 2), "rare": special})
	return {"width": WIDTH, "height": HEIGHT, "tiles": tiles, "entrance": [start.x, start.y],
		"stairs": [finish.x, finish.y], "chests": chests, "enemies": enemies, "boss": [],
		"rank": rank, "unusual": unusual, "index": index}

static func reachable(tiles: Array, start: Array) -> Dictionary:
	var origin = int(start[1]) * WIDTH + int(start[0])
	var seen = {origin: 0}
	var queue = [origin]
	var head = 0
	while head < queue.size():
		var p: int = queue[head]
		head += 1
		for v in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var x = p % WIDTH + v.x
			var y = int(p / WIDTH) + v.y
			var n = y * WIDTH + x
			if x >= 0 and x < WIDTH and y >= 0 and y < HEIGHT and tiles[n] == 1 and not seen.has(n):
				seen[n] = seen[p] + 1
				queue.append(n)
	return seen
