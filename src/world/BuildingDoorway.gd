extends Area3D
class_name BuildingDoorway

signal player_transitioned(door_id: String)

@export var door_id: String = "castle_door"
@export var prompt_text: String = "[E] Enter Castle"
@export var target_position: Vector3 = Vector3(0.0, -100.0, 8.0)
@export var target_rotation_y: float = 180.0
@export var is_interior_exit: bool = false
@export var target_cam_distance: float = 12.0
@export var target_cam_pitch: float = 40.0
@export var target_cam_yaw: float = 45.0
@export var interior_name: String = "Castle Grand Hall"

var _is_transitioning: bool = false
var _prompt_label: Label3D = null

func _ready() -> void:
	name = "Doorway_" + door_id
	add_to_group("interactable")
	collision_layer = 1 << 5 # Layer 6: Interactable
	collision_mask = 0
	_setup_shape()
	_setup_visual_marker()

func _setup_shape() -> void:
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(2.6, 3.2, 2.6)
	col.shape = shape
	col.position.y = 1.6
	add_child(col)

func _setup_visual_marker() -> void:
	_prompt_label = Label3D.new()
	_prompt_label.text = "🚪 " + prompt_text
	_prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt_label.position.y = 2.4
	_prompt_label.font_size = 24
	_prompt_label.outline_size = 6
	_prompt_label.outline_modulate = Color(0.02, 0.03, 0.05)
	_prompt_label.modulate = Color(1.0, 0.95, 0.5)
	add_child(_prompt_label)

func get_prompt_text() -> String:
	return prompt_text

func interact(player: Node3D) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	
	var hud = get_tree().get_first_node_in_group("hud")
	var main = get_tree().get_first_node_in_group("main")
	
	AudioManager.play_sfx("door_open", 0.05, 0.0)
	
	if player and "is_input_locked" in player:
		player.is_input_locked = true
		player.velocity = Vector3.ZERO
		
	if hud and hud.has_method("fade_screen"):
		await hud.fade_screen(true, 0.22)
	else:
		await get_tree().create_timer(0.22).timeout
		
	# Reposition player
	if player and is_instance_valid(player):
		player.global_position = target_position
		player.velocity = Vector3.ZERO
		if "rotation_degrees" in player:
			player.rotation_degrees.y = target_rotation_y
			
	# Update camera distance & orientation in main
	if main:
		if "target_cam_distance" in main:
			main.target_cam_distance = target_cam_distance
		if "target_cam_pitch" in main:
			main.target_cam_pitch = target_cam_pitch
		if "target_cam_yaw" in main:
			main.target_cam_yaw = target_cam_yaw
			
	# Door close sound on arrival
	AudioManager.play_sfx("door_close", 0.05, 0.0)
	
	await get_tree().create_timer(0.08).timeout
	
	if hud and hud.has_method("fade_screen"):
		await hud.fade_screen(false, 0.22)
		
	if player and is_instance_valid(player) and "is_input_locked" in player:
		player.is_input_locked = false
		
	_is_transitioning = false
	player_transitioned.emit(door_id)
