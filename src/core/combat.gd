class_name Combat
extends RefCounted
var state: GameState
var enemy: Dictionary
var rng: SeedRng
var turn = 0
var outcome = ""
var log: Array = []
var guarded = false
var enemy_guard = false

func _init(game_state: GameState, opponent: Dictionary, seed_value: int) -> void:
	state = game_state
	enemy = opponent.duplicate(true)
	rng = SeedRng.new(seed_value)
	log.append("%s bars the way." % enemy.name)

func act(action: String) -> bool:
	if outcome != "":
		return false
	if action == "spark" and state.player.mp < 4 or action == "mend" and state.player.mp < 5:
		return false
	if action.begins_with("item:") and int(state.player.inventory.get(action.substr(5),0)) < 1:
		return false
	if action == "flee" and enemy.boss:
		log.append("The keeper seals this chamber. Fight or fall.")
		return false
	turn += 1
	guarded = action == "guard"
	var first = guarded or state.stats().speed + rng.between(0,4) >= enemy.speed + rng.between(0,4)
	if not first:
		enemy_action()
	if state.player.hp > 0:
		player_action(action)
	if first and enemy.hp > 0 and outcome == "":
		enemy_action()
	if state.player.poison > 0 and state.player.hp > 0 and outcome == "":
		state.player.hp = maxi(1,state.player.hp - 3)
		state.player.poison -= 1
		log.append("Poison drains 3 HP.")
	if state.player.hp <= 0:
		outcome = "defeat"
	elif enemy.hp <= 0:
		outcome = "victory"
	return true

func player_action(action: String) -> void:
	var damage = 0
	match action:
		"attack":
			damage = maxi(2, state.stats().attack - int(enemy.defence / 2) + rng.between(-2,3))
		"spark":
			state.player.mp -= 4
			damage = 22 + state.player.level * 3 + rng.between(-2,4)
		"mend":
			state.player.mp -= 5
			state.player.hp = mini(state.stats().max_hp,state.player.hp + 38 + state.player.level * 3)
			log.append("You cast Mend. Warm light restores your HP.")
		"guard":
			state.player.mp = mini(state.stats().max_mp,state.player.mp + 3)
			log.append("You brace and recover 3 MP.")
		"flee":
			if rng.between(1,100) <= 80:
				outcome = "fled"
				log.append("You slip away.")
			else:
				log.append("Your escape is blocked!")
		_:
			if action.begins_with("item:"):
				state.use_item(action.substr(5))
				log.append("You use %s." % Content.item(action.substr(5)).name)
	if damage > 0:
		if enemy_guard:
			damage = maxi(1,int(damage * 0.55))
			enemy_guard = false
		enemy.hp = maxi(0, enemy.hp - damage)
		log.append("Your %s deals %d damage." % ["Spark" if action == "spark" else "attack",damage])

func enemy_action() -> void:
	var damage = maxi(1,int(enemy.attack) - int(state.stats().defence / 2) + rng.between(-2,2))
	var ability: String = enemy.ability if turn % 3 == 0 else "attack"
	if ability == "brace":
		enemy_guard = true
		log.append("%s braces. Its next hit taken is reduced." % enemy.name)
		return
	if ability == "spark":
		damage += 5
	if guarded:
		damage = maxi(1,int(damage * 0.4))
	state.player.hp = maxi(0,state.player.hp - damage)
	if ability == "venom" and not guarded:
		state.player.poison = 4
	log.append("%s uses %s: %d damage%s." % [enemy.name,ability,damage," + poison" if ability == "venom" and not guarded else ""])
