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
var rules = Content.table("balance").abilities
var damage_taken = 0
var mana_spent = 0
var items_used = 0

func intent() -> String:
	return intent_for(turn+1)

func intent_for(number: int) -> String:
	if enemy.boss:
		match number % 4:
			2: return "charge"
			3: return "crush"
			0: return enemy.ability
	return enemy.ability if number % 3 == 0 else "attack"

func intent_text() -> String:
	match intent():
		"charge": return "Gathering power — a heavy strike follows next turn."
		"crush": return "HEAVY STRIKE incoming — Guard sharply reduces the blow."
		"brace": return "Preparing a shield — Spark pierces its protection."
		"venom": return "Venom strike incoming — Guard prevents poison."
		"spark": return "An arcane burst is coming."
	return "Preparing a physical strike."

func _init(game_state: GameState, opponent: Dictionary, seed_value: int) -> void:
	state = game_state
	enemy = opponent.duplicate(true)
	rng = SeedRng.new(seed_value)
	log.append("%s bars the way." % enemy.name)

func act(action: String) -> bool:
	if outcome != "":
		return false
	if not action in ["attack","spark","mend","guard","flee"] and not action.begins_with("item:"): return false
	if action == "spark" and state.player.mp < rules.spark_cost or action == "mend" and state.player.mp < rules.mend_cost:
		return false
	if action.begins_with("item:") and int(state.player.inventory.get(action.substr(5),0)) < 1:
		return false
	if action.begins_with("item:") and Content.item(action.substr(5)).get("slot","") != "supply": return false
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
		var poison_damage = maxi(3,int(state.stats().max_hp*0.04))
		damage_taken += mini(poison_damage,state.player.hp-1)
		state.player.hp = maxi(1,state.player.hp - poison_damage)
		state.player.poison -= 1
		log.append("Poison drains %d HP." % poison_damage)
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
			state.player.mp -= int(rules.spark_cost)
			mana_spent += int(rules.spark_cost)
			damage = int(rules.spark_base + state.player.level * rules.spark_per_level) + rng.between(-2,4)
		"mend":
			state.player.mp -= int(rules.mend_cost)
			mana_spent += int(rules.mend_cost)
			state.player.hp = mini(state.stats().max_hp,state.player.hp + int(rules.mend_base + state.player.level * rules.mend_per_level))
			log.append("You cast Mend. Warm light restores your HP.")
		"guard":
			state.player.mp = mini(state.stats().max_mp,state.player.mp + int(rules.guard_mana))
			log.append("You brace and recover %d MP." % rules.guard_mana)
		"flee":
			if rng.between(1,100) <= 80:
				outcome = "fled"
				log.append("You slip away.")
			else:
				log.append("Your escape is blocked!")
		_:
			if action.begins_with("item:"):
				state.use_item(action.substr(5))
				items_used += 1
				log.append("You use %s." % Content.item(action.substr(5)).name)
	if damage > 0:
		if enemy_guard:
			if action != "spark": damage = maxi(1,int(damage * 0.45))
			enemy_guard = false
		enemy.hp = maxi(0, enemy.hp - damage)
		log.append("Your %s deals %d damage." % ["Spark" if action == "spark" else "attack",damage])

func enemy_action() -> void:
	var damage = maxi(1,int(enemy.attack) - int(state.stats().defence / 2) + rng.between(-2,2))
	var ability = intent_for(turn)
	if ability == "charge":
		log.append("%s gathers power. A crushing blow comes next!" % enemy.name)
		return
	if ability == "brace":
		enemy_guard = true
		log.append("%s braces. Its next hit taken is reduced." % enemy.name)
		return
	if ability == "spark":
		damage = maxi(damage,int(enemy.attack*0.9)) + 4
	if ability == "crush": damage = int(damage*rules.crush_multiplier)
	if guarded:
		damage = maxi(1,int(damage * rules.guard_multiplier))
	damage_taken += mini(damage,state.player.hp)
	state.player.hp = maxi(0,state.player.hp - damage)
	if ability == "venom" and not guarded:
		state.player.poison = 4
	log.append("%s uses %s: %d damage%s." % [enemy.name,ability,damage," + poison" if ability == "venom" and not guarded else ""])
