class_name SeedRng
extends RefCounted
## Park–Miller integers: fixed algorithm, independent of Godot RNG versions.
var state: int

func _init(value: int = 1) -> void:
	state = posmod(value, 2147483646) + 1

func next() -> int:
	state = (state * 48271) % 2147483647
	return state

func between(low: int, high: int) -> int:
	return low + next() % (high - low + 1)

func pick(values: Array):
	return values[between(0, values.size() - 1)]

func weighted(weights: Array) -> int:
	var total = 0
	for weight in weights:
		total += int(weight)
	var roll = between(1, total)
	for i in weights.size():
		roll -= int(weights[i])
		if roll <= 0:
			return i
	return weights.size() - 1
