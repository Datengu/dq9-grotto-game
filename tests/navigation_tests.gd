extends SceneTree
var failures: Array = []
var tested = 0
func _init(): call_deferred("run")
func check(ok: bool, message: String):
	if not ok: failures.append(message); push_error(message)
func run():
	var start_time = Time.get_ticks_msec()
	for version in [1,2]:
		for seed_index in 60:
			var quality = 2+seed_index*4
			var meta = GrottoGenerator.create(seed_index*7919,quality,quality,version)
			var floors = GrottoGenerator.generate(meta)
			for index in [0,int(meta.depth)-1]:
				var floor_data = floors[index]
				var nav = SurfaceNavigation.new(); nav.setup(floor_data,1.8); nav.build_surface()
				for tick in 40:
					if nav.ready(): break
					await physics_frame
				check(nav.ready(),"Navmesh becomes ready v%d seed%d B%d" % [version,seed_index,index+1])
				var from = nav.world(Vector2i(floor_data.entrance[0],floor_data.entrance[1]))
				var to = nav.world(Vector2i(floor_data.stairs[0],floor_data.stairs[1]))
				var path = nav.path(from,to)
				check(not path.is_empty() and Vector2(path[-1].x-to.x,path[-1].z-to.z).length() < 0.65,"Stairs reached by physical navmesh v%d seed%d B%d" % [version,seed_index,index+1])
				if version == 2 and seed_index == 0:
					var a = nav.closest(from+Vector3(0.31,0,0.24))
					var b = nav.closest(from+Vector3(1.37,0,0.81))
					var direct = nav.path(a,b)
					check(direct.size() == 2,"Open room movement has direct continuous path")
					check(Vector2(direct[-1].x-b.x,direct[-1].z-b.z).length() < 0.01,"Arbitrary endpoint is preserved")
				tested += 1
	var file = FileAccess.open(TestOutput.path("navigation-report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"floors":tested,"failures":failures,"duration_ms":Time.get_ticks_msec()-start_time},"\t"))
	print("NAVIGATION: ",tested," floors, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
