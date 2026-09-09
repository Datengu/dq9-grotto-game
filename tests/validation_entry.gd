extends Node
## Test-export entry only. Release templates lack the editor's --script option.
## Install the existing SceneTree test driver, without duplicating its assertions.
func _ready() -> void:
	var test_name = "playthrough_3d"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scenario="): test_name = arg.trim_prefix("--scenario=")
	var allowed = ["playthrough_3d","exploration_tests","doorway_tests","population_tests","motion_probe","version_tests","navigation_tests","existing_save_tests"]
	if not OS.get_cmdline_user_args().has("--test-play") or not allowed.has(test_name):
		push_error("Validation export requires --test-play and a supported --scenario.")
		get_tree().quit(2)
		return
	TestOutput.path()
	get_tree().set_script(load("res://tests/"+test_name+".gd"))
	queue_free()
