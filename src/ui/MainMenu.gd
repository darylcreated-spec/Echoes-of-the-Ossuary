extends Control
class_name MainMenu

signal start_descent_requested()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_start_button_pressed() -> void:
	AudioManager.play_sfx("dash", 0.05, 1.0)
	start_descent_requested.emit()
	hide()

func _on_quit_button_pressed() -> void:
	get_tree().quit()
