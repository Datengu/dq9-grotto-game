class_name TestOutput
extends RefCounted
## Exported resources are read-only. Test artifacts go beside the validation
## executable; source tests use the ignored project test-output directory.
static func path(name: String = "") -> String:
	var base = OS.get_executable_path().get_base_dir().path_join("test-output") if OS.has_feature("foundation_validation") else ProjectSettings.globalize_path("res://test-output")
	DirAccess.make_dir_recursive_absolute(base)
	return base.path_join(name)
