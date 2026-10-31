extends Node3D
class_name OverworldGate

@export var open_angle: float = 95.0
@export var trigger_distance: float = 6.5
@export var auto_open: bool = true

var _gate_model: Node3D = null
var _left_door: Node3D = null
var _right_door: Node3D = null
var _center_col: CollisionShape3D = null
var _is_open: bool = false
var _tween: Tween = null
var _target_player: Node3D = null

func _init() -> void:
	name = "FortifiedArchGate"
	_setup_model()
	_setup_collision()
	_setup_trigger()

func _ready() -> void:
	if not _gate_model:
		_setup_model()
		_setup_collision()
		_setup_trigger()

func is_open() -> bool:
	return _is_open

func _setup_model() -> void:
	var scene = load("res://assets/overworld/arch_gate.gltf")
	if scene:
		_gate_model = scene.instantiate()
		_gate_model.scale = Vector3.ONE * 1.6
		add_child(_gate_model)
		_left_door = _gate_model.find_child("arch_gate_left", true, false)
		_right_door = _gate_model.find_child("arch_gate_right", true, false)

func _setup_collision() -> void:
	var static_body = StaticBody3D.new()
	static_body.name = "GateColliders"
	static_body.collision_layer = 1
	static_body.collision_mask = 0
	
	# Left stone pillar collider
	var left_shape = BoxShape3D.new()
	left_shape.size = Vector3(2.0, 6.0, 2.0)
	var left_col = CollisionShape3D.new()
	left_col.shape = left_shape
	left_col.position = Vector3(-3.4, 3.0, 0.0)
	static_body.add_child(left_col)
	
	# Right stone pillar collider
	var right_shape = BoxShape3D.new()
	right_shape.size = Vector3(2.0, 6.0, 2.0)
	var right_col = CollisionShape3D.new()
	right_col.shape = right_shape
	right_col.position = Vector3(3.4, 3.0, 0.0)
	static_body.add_child(right_col)
	
	# Center Iron Portcullis Gate Barrier (Prevents walking through closed bars)
	var center_shape = BoxShape3D.new()
	center_shape.size = Vector3(4.8, 4.8, 0.6)
	_center_col = CollisionShape3D.new()
	_center_col.shape = center_shape
	_center_col.position = Vector3(0.0, 2.4, 0.0)
	static_body.add_child(_center_col)
	
	add_child(static_body)

func _setup_trigger() -> void:
	var trigger = Area3D.new()
	trigger.name = "ProximityTrigger"
	trigger.collision_layer = 0
	trigger.collision_mask = 2 # Player physics layer
	
	var shape = SphereShape3D.new()
	shape.radius = trigger_distance
	var col = CollisionShape3D.new()
	col.shape = shape
	col.position = Vector3(0.0, 1.0, 0.0)
	trigger.add_child(col)
	
	trigger.body_entered.connect(_on_body_entered)
	trigger.body_exited.connect(_on_body_exited)
	add_child(trigger)

	# Manual [E] Interaction Area
	var interact_area = Area3D.new()
	interact_area.name = "InteractionArea"
	interact_area.collision_layer = 1 << 5 # Layer 6: Interactable
	interact_area.collision_mask = 0
	var i_shape = SphereShape3D.new()
	i_shape.radius = 3.2
	var i_col = CollisionShape3D.new()
	i_col.shape = i_shape
	i_col.position = Vector3(0.0, 1.0, 0.0)
	interact_area.add_child(i_col)
	add_child(interact_area)

func get_prompt_text() -> String:
	return "[E] Close Gate" if _is_open else "[E] Open Gate"

func interact(player: Node = null) -> void:
	if _is_open:
		close_gate()
	else:
		open_gate()
	if player and "hud" in player and player.hud and player.hud.get("interact_prompt"):
		player.hud.interact_prompt.text = get_prompt_text()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_target_player = body
		if auto_open and not _is_open:
			open_gate()

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_target_player = null
		if _is_open:
			close_gate()

func open_gate() -> void:
	if _is_open:
		return
	_is_open = true
	
	if _center_col:
		_center_col.set_deferred("disabled", true)
		
	if _tween and _tween.is_valid():
		_tween.kill()
		
	_tween = create_tween()
	_tween.set_parallel(true)
	if _left_door:
		_tween.tween_property(_left_door, "rotation_degrees:y", open_angle, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if _right_door:
		_tween.tween_property(_right_door, "rotation_degrees:y", -open_angle, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
	_play_sfx("door_open", 0.0)

func close_gate() -> void:
	if not _is_open:
		return
	_is_open = false
	
	if _tween and _tween.is_valid():
		_tween.kill()
		
	_tween = create_tween()
	_tween.set_parallel(true)
	if _left_door:
		_tween.tween_property(_left_door, "rotation_degrees:y", 0.0, 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if _right_door:
		_tween.tween_property(_right_door, "rotation_degrees:y", 0.0, 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		
	_tween.chain().tween_callback(func():
		if not _is_open and _center_col:
			_center_col.set_deferred("disabled", false)
	)
	
	_play_sfx("door_close", -2.0)

func _play_sfx(sfx_key: String, volume_db: float = 0.0) -> void:
	if not is_inside_tree():
		return
	var am = get_tree().root.get_node_or_null("AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx(sfx_key, 0.08, volume_db)
