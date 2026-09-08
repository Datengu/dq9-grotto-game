extends SceneTree
func _init(): call_deferred("run")
func shot(name):
	for i in 20: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-output/"+name+".png")
func run():
	var game = load("res://src/main.tscn").instantiate()
	root.add_child(game)
	await shot("3d-hub")
	game.world.enter_building(Content.table("hub").buildings[0])
	await shot("3d-interior")
	var entry = game.state.add_map(GrottoGenerator.create(14292,35,35),"test")
	game.begin_expedition(entry)
	await shot("3d-dungeon")
	game.floor_index = 2
	game.enter_floor()
	await shot("3d-depth")
	game.queue_free()
	await process_frame
	quit()
