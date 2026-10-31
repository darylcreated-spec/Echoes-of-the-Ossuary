extends Area3D
class_name SpikeTrap

enum TrapState {
	RETRACTED,
	WARNING,
	EXTENDED
}

@export var damage: float = 18.0
@export var cycle_time: float = 3.0

var current_state: TrapState = TrapState.RETRACTED
var _timer: float = 0.0
var _visual_tile: Node3D = null
var _spikes_node: Node3D = null

func _ready() -> void:
	collision_layer = 1 << 6 # Hazard
	collision_mask = (1 << 1) | (1 << 2) # Player & Enemies
	
	_setup_visuals()
	body_entered.connect(_on_body_entered)

func _setup_visuals() -> void:
	_visual_tile = AssetLoader.load_or_generate_model("res://assets/dungeon/floor_tile_big_spikes.glb", "dungeon", "floor_spikes")
	add_child(_visual_tile)
	_spikes_node = _visual_tile.find_child("Spikes", true, false)
	
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(1.8, 0.6, 1.8)
	col.shape = box
	col.position.y = 0.3
	add_child(col)
	
	# Initial retracted position
	if _spikes_node:
		_spikes_node.position.y = -0.5

func _physics_process(delta: float) -> void:
	_timer += delta
	var cycle_mod = fmod(_timer, cycle_time)
	
	if cycle_mod < cycle_time * 0.6:
		# Retracted
		if current_state != TrapState.RETRACTED:
			_set_state(TrapState.RETRACTED)
	elif cycle_mod < cycle_time * 0.8:
		# Warning: slight rise
		if current_state != TrapState.WARNING:
			_set_state(TrapState.WARNING)
	else:
		# Extended: fully up and lethal
		if current_state != TrapState.EXTENDED:
			_set_state(TrapState.EXTENDED)

func _set_state(new_state: TrapState) -> void:
	current_state = new_state
	if not _spikes_node:
		return
		
	var tween = _spikes_node.create_tween()
	match current_state:
		TrapState.RETRACTED:
			tween.tween_property(_spikes_node, "position:y", -0.5, 0.25).set_trans(Tween.TRANS_QUAD)
		TrapState.WARNING:
			tween.tween_property(_spikes_node, "position:y", -0.15, 0.15)
		TrapState.EXTENDED:
			tween.tween_property(_spikes_node, "position:y", 0.0, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_check_overlapping_damage()

func _check_overlapping_damage() -> void:
	for body in get_overlapping_bodies():
		_deal_trap_damage(body)

func _on_body_entered(body: Node3D) -> void:
	if current_state == TrapState.EXTENDED:
		_deal_trap_damage(body)

func _deal_trap_damage(body: Node3D) -> void:
	if body.is_in_group("player"):
		# Titan's Stride Boon gives trap immunity
		if GameManager.has_boon("titan_stride"):
			return
		if body.has_method("take_damage"):
			body.take_damage(damage, Vector3.UP * 4.0, false, self)
		CombatJuice.add_trauma(0.18)
	elif body.has_method("take_damage"):
		body.take_damage(damage, Vector3.UP * 4.0, false, self)
