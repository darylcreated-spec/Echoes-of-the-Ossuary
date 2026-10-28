extends Node3D
class_name UpgradeAltar

func interact(_player: Node3D) -> void:
	AudioManager.play_sfx("chest_open", 0.05, 0.8)
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_altar_modal"):
		hud.show_altar_modal()
