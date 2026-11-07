extends SceneTree

func _init() -> void:
	var option_name = "option_1"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--icon="):
			option_name = arg.trim_prefix("--icon=")
	var src_path = ProjectSettings.globalize_path("res://assets/pwa/options/%s.jpg" % option_name)
	var img = Image.new()
	if img.load(src_path) == OK:
		for sz in [144, 180, 512]:
			var resized: Image = img.duplicate()
			resized.resize(sz, sz, Image.INTERPOLATE_LANCZOS)
			resized.save_png(ProjectSettings.globalize_path("res://assets/pwa/icon_%d.png" % sz))
			if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("res://build/web")):
				resized.save_png(ProjectSettings.globalize_path("res://build/web/index.%dx%d.png" % [sz, sz]))
		if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("res://build/web")):
			var icon180: Image = img.duplicate()
			icon180.resize(180, 180, Image.INTERPOLATE_LANCZOS)
			icon180.save_png(ProjectSettings.globalize_path("res://build/web/index.apple-touch-icon.png"))
			icon180.save_png(ProjectSettings.globalize_path("res://build/web/index.icon.png"))
		print(" -> Applied PWA Icon set from: ", option_name)
	quit()
