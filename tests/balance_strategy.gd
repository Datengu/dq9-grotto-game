class_name BalanceStrategy
extends RefCounted
static func choose(fight: Combat) -> String:
	var state = fight.state
	var p = state.player
	var maximum = state.stats().max_hp
	# Only information visible to a player: HP, MP, supplies and announced intent.
	if fight.intent() == "crush": return "guard"
	if p.hp < maximum*0.48:
		if p.mp >= 6: return "mend"
		if p.inventory.get("heartfruit",0) > 0: return "item:heartfruit"
		if p.inventory.get("salve",0) > 0: return "item:salve"
	if p.mp < 6 and p.inventory.get("tonic",0) > 0: return "item:tonic"
	if p.poison > 1 and p.inventory.get("remedy",0) > 0: return "item:remedy"
	if fight.enemy_guard and p.mp >= 11: return "spark"
	if fight.enemy.boss and p.mp >= 12 and fight.intent() == "charge": return "spark"
	if fight.intent() == "venom" and p.hp < maximum*0.6: return "guard"
	return "attack"

static func prepared(level: int, gear: int) -> GameState:
	var state = GameState.new()
	state.player.level = level
	state.player.equipment.weapon = ["copper_sabre","warden_spear","starsteel"][gear]
	state.player.equipment.armour = ["ring_vest","warden_mail","moonplate"][gear]
	state.player.inventory = {"salve":5,"tonic":2,"remedy":2,"heartfruit":0 if gear == 0 else 3}
	state.rest()
	return state
