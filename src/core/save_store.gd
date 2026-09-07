class_name SaveStore
extends RefCounted
const PATH = "user://atlas-save.json"

static func write(state: GameState, path: String = PATH) -> bool:
	var file = FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		state.save_error = "Save could not be written: %s" % error_string(FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(state.serialise(), "\t"))
	file.flush()
	file.close()
	if FileAccess.file_exists(path):
		var parser = JSON.new()
		var valid = parser.parse(FileAccess.get_file_as_string(path)) == OK
		if valid and parser.data is Dictionary and GameState.new().restore(parser.data):
			var backup_error = DirAccess.copy_absolute(path, path + ".bak")
			if backup_error != OK:
				state.save_error = "Could not preserve backup; original save kept."
				return false
	var err = DirAccess.rename_absolute(path + ".tmp", path)
	state.save_error = "" if err == OK else "Save rename failed: %s" % error_string(err)
	return err == OK

static func read(state: GameState, path: String = PATH) -> bool:
	for candidate in [path, path + ".bak"]:
		if FileAccess.file_exists(candidate):
			var parser = JSON.new()
			var error = parser.parse(FileAccess.get_file_as_string(candidate))
			if error == OK and parser.data is Dictionary and state.restore(parser.data):
				if candidate != path:
					state.save_error = "Recovered the previous backup save."
				return true
	if FileAccess.file_exists(path):
		state.save_error = "Save is damaged or from an unsupported version. Original file preserved."
	return false
