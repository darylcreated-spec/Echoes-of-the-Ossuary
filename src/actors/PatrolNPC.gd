extends CharacterBody3D
class_name PatrolNPC

@export var npc_name: String = "Citadel Guard"
@export var npc_title: String = "Royal Sentry"
@export var model_path: String = "res://assets/characters/adventurers/Knight.glb"
@export var model_scale: Vector3 = Vector3(0.55, 0.55, 0.55)
@export var patrol_speed: float = 2.4
@export var waypoints: Array = []
@export var wait_time_at_waypoint: float = 3.0

var _model: Node3D = null
var _anim_player: AnimationPlayer = null
var _current_waypoint_idx: int = 0
var _wait_timer: float = 0.0
var _is_waiting: bool = false
var _label: Label3D = null

func _ready() -> void:
	add_to_group("patrol_npc")
	add_to_group("interactable")
	collision_layer = 1 # Environment/character layer
	collision_mask = 1
	
	_build_visuals()
	_build_interaction()
	
	if waypoints.is_empty():
		waypoints.append(global_position)
		waypoints.append(global_position + Vector3(0, 0, 8.0))

func _build_visuals() -> void:
	_model = AssetLoader.load_or_generate_model(model_path, "character", npc_name)
	_model.scale = model_scale
	add_child(_model)
	
	_anim_player = _model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_play_anim("Walking_A", true)
	
	# Floating Name Tag & Prompt
	_label = Label3D.new()
	_label.text = "🛡️ " + npc_name + "\n[E] Speak"
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position.y = 2.0
	_label.font_size = 24
	_label.outline_size = 6
	_label.outline_modulate = Color(0.02, 0.03, 0.05)
	_label.modulate = Color(0.9, 0.95, 1.0)
	add_child(_label)

func _build_interaction() -> void:
	var area = Area3D.new()
	area.name = "InteractArea"
	area.collision_layer = 1 << 5 # Layer 6: Interactable
	area.collision_mask = 0
	var shape = CylinderShape3D.new()
	shape.radius = 2.2
	shape.height = 3.0
	var col = CollisionShape3D.new()
	col.shape = shape
	col.position.y = 1.5
	area.add_child(col)
	add_child(area)

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= 26.0 * delta
	else:
		velocity.y = -0.5

	if waypoints.is_empty():
		move_and_slide()
		return

	if _is_waiting:
		_wait_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, patrol_speed * 3.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, patrol_speed * 3.0 * delta)
		move_and_slide()
		if _wait_timer <= 0.0:
			_is_waiting = false
			_current_waypoint_idx = (_current_waypoint_idx + 1) % waypoints.size()
			_play_anim("Walking_A", true)
		return

	var target = waypoints[_current_waypoint_idx]
	var diff = target - global_position
	diff.y = 0.0
	var dist = diff.length()

	if dist < 0.6:
		# Reached waypoint
		_is_waiting = true
		_wait_timer = wait_time_at_waypoint
		_play_anim("Idle", true)
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		var dir = diff.normalized()
		velocity.x = dir.x * patrol_speed
		velocity.z = dir.z * patrol_speed
		
		# Smoothly rotate model toward movement direction
		var target_rot = rad_to_deg(atan2(dir.x, dir.z))
		if _model:
			_model.rotation_degrees.y = lerp_angle(deg_to_rad(_model.rotation_degrees.y), deg_to_rad(target_rot), delta * 6.0)
			_model.rotation_degrees.y = rad_to_deg(_model.rotation_degrees.y)
		
		# Ensure walk animation is playing
		if _anim_player and (_anim_player.current_animation != "Walking_A" or not _anim_player.is_playing()):
			_play_anim("Walking_A", true)

	move_and_slide()

func _play_anim(anim_name: String, loop: bool = true) -> void:
	if not _anim_player:
		return
	var target_anim = anim_name
	if not _anim_player.has_animation(target_anim):
		for a in _anim_player.get_animation_list():
			if anim_name.to_lower() in a.to_lower():
				target_anim = a
				break
	if _anim_player.has_animation(target_anim):
		var anim_res = _anim_player.get_animation(target_anim)
		if anim_res and loop:
			anim_res.loop_mode = Animation.LOOP_LINEAR
		_anim_player.play(target_anim, 0.2, 1.0)

func interact(player: Node) -> void:
	if player:
		var look_vec = player.global_position - global_position
		look_vec.y = 0.0
		if _model and look_vec.length() > 0.1:
			_model.rotation_degrees.y = rad_to_deg(atan2(look_vec.x, look_vec.z))
	_is_waiting = true
	_wait_timer = 4.0
	_play_anim("Cheer", false)
	AudioManager.play_sfx("footstep", 0.08, 0.0)
	
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_toast"):
		hud.show_toast(npc_name + ": \"Move along, citizen! The Royal Highway remains secure under our watch.\"")
