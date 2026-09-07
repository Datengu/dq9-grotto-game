class_name LootSystem
extends RefCounted

static func roll(rank: int, rng: SeedRng) -> Dictionary:
	var rows = Content.table("loot")[str(rank)]
	var weights: Array = []
	for row in rows:
		weights.append(row[1])
	var chosen = rows[rng.weighted(weights)]
	return {"id":chosen[0],"amount":int(chosen[2])}
