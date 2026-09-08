extends SceneTree
var rows: Array = []
var failures: Array = []
func _init(): call_deferred("run")
func check(ok: bool, message: String):
	if not ok: failures.append(message); push_error(message)

func sample(label: String, level: int, gear: int, rank: int, tier: int, tactical: bool, boss: bool) -> Dictionary:
	var totals = {"scenario":label,"strategy":"tactical" if tactical else "attack_only","boss":boss,"level":level,"rank":rank,"tier":tier,"trials":200,"deaths":0,"turns":0.0,"damage":0.0,"mp_spent":0.0,"items":0.0,"encounters_before_healing":0.0}
	for i in 200:
		var state = BalanceStrategy.prepared(level,gear)
		var fight = Combat.new(state,Content.boss(tier) if boss else Content.monster("Cavern",rank,i%3),i*7919+33)
		while fight.outcome == "" and fight.turn < 120:
			fight.act(BalanceStrategy.choose(fight) if tactical else "attack")
		if fight.outcome != "victory": totals.deaths += 1
		totals.turns += fight.turn
		totals.damage += fight.damage_taken
		totals.mp_spent += fight.mana_spent
		totals.items += fight.items_used
		totals.encounters_before_healing += state.stats().max_hp/float(maxi(1,fight.damage_taken))
	for key in ["turns","damage","mp_spent","items","encounters_before_healing"]: totals[key] /= 200.0
	totals["death_rate"] = totals.deaths/200.0
	rows.append(totals)
	return totals

func run():
	for scenario in [["starter",1,0,1,1],["low",5,0,3,3],["mid",18,1,6,6],["high",35,2,10,10],["unprepared_high",5,0,10,10]]:
		var naive: Dictionary
		var tactical: Dictionary
		for boss in [false,true]:
			naive = sample(scenario[0],scenario[1],scenario[2],scenario[3],scenario[4],false,boss)
			tactical = sample(scenario[0],scenario[1],scenario[2],scenario[3],scenario[4],true,boss)
			if scenario[0] == "starter" and not boss: check(naive.death_rate == 0,"Starter normal encounters approachable")
			if scenario[0] == "unprepared_high": check(naive.death_rate > 0.95,"High ranks dangerous to unprepared characters")
			if boss and scenario[0] != "unprepared_high":
				check(tactical.death_rate < naive.death_rate,"Tactics improve keeper survival: "+scenario[0])
				check(tactical.death_rate < 0.3,"Prepared tactical keeper is viable: "+scenario[0])
	# Continuous starter expedition: no rest or level-up refill between fights.
	var clears = {"attack_only":0,"tactical":0}
	for tactical in [false,true]:
		for seed_value in 100:
			var state = BalanceStrategy.prepared(1,0)
			for index in 11:
				var fight = Combat.new(state,Content.boss(1) if index == 10 else Content.monster("Cavern",1,index%3),seed_value*103+index)
				while fight.outcome == "" and fight.turn < 120: fight.act(BalanceStrategy.choose(fight) if tactical else "attack")
				if fight.outcome != "victory": break
				state.gain_xp(fight.enemy.xp)
				if index == 10: clears["tactical" if tactical else "attack_only"] += 1
	check(clears.attack_only == 0,"Repeated Attack cannot ignore expedition attrition")
	check(clears.tactical >= 85,"Prepared tactical starter expedition can be completed")
	var file = FileAccess.open("res://test-output/balance-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures":failures,"samples":rows,"starter_expedition_clears_per_100":clears},"\t"))
	print("BALANCE: ",failures.size()," failures; starter expedition clears: ",clears)
	quit(0 if failures.is_empty() else 1)
