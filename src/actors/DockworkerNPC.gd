class_name DockworkerNPC
extends CharacterBody3D

## DockworkerNPC
## Animated port stevedore hauling trade cargo between cargo cranes and warehouses.
## Carries physical cargo props and plays authentic walking and lifting animations.

@export var waypoints: Array[Vector3] = [
	Vector3(-66.0, 0.04, 76.0), # Near cargo crane
	Vector3(-50.0, 0.04, 80.0)  # Near warehouse depot
]
@export var walk_speed: float = 2.2

var _current_waypoint_idx: int = 0
var _wait_timer: float = 0.0
var _is_waiting: bool = false
var _carrying_crate: bool = true

var _character_model: Node3D = null
var _anim_player: AnimationPlayer = null
var _carried_prop: MeshInstance3D = null

var interact_prompt: String = "[E] Talk to Stevedore"

func _ready() -> void:
	add_to_group("npcs")
	add_to_group("interactable")
	_setup_character()

func _setup_character() -> void:
	var char_path = "res://assets/characters/adventurers/Barbarian.glb"
	if ResourceLoader.exists(char_path):
		var scene = load(char_path)
		if scene:
			_character_model = scene.instantiate()
			_character_model.scale = Vector3(0.9, 0.9, 0.9)
			add_child(_character_model)
			_anim_player = _find_animation_player(_character_model)

	if not _character_model:
		var dummy = MeshInstance3D.new()
		var cap = CapsuleMesh.new()
		cap.radius = 0.35
		cap.height = 1.7
		dummy.mesh = cap
		dummy.position.y = 0.85
		add_child(dummy)

	# Carried Cargo Crate / Barrel
	_carried_prop = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(0.55, 0.5, 0.55)
	_carried_prop.mesh = b_mesh
	_carried_prop.position = Vector3(0.0, 0.95, 0.45)
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.48, 0.32, 0.16)
	_carried_prop.material_override = wood_mat
	add_child(_carried_prop)

	# Collision shape for CharacterBody3D
	var col = CollisionShape3D.new()
	var cap_shape = CapsuleShape3D.new()
	cap_shape.radius = 0.4
	cap_shape.height = 1.8
	col.shape = cap_shape
	col.position.y = 0.9
	add_child(col)

	var lbl = Label3D.new()
	lbl.position.y = 2.45
	AssetLoader.style_world_label3d(lbl, "⚓ Stevedore Thatch\n[E] Speak", 48, Color(0.88, 0.95, 1.0))
	add_child(lbl)

	_play_walk_anim()

func _physics_process(delta: float) -> void:
	if waypoints.is_empty():
		return

	if _is_waiting:
		_wait_timer -= delta
		if _wait_timer <= 0.0:
			_is_waiting = false
			_carrying_crate = not _carrying_crate
			if _carried_prop:
				_carried_prop.visible = _carrying_crate
			_current_waypoint_idx = (_current_waypoint_idx + 1) % waypoints.size()
			_play_walk_anim()
		velocity = Vector3.ZERO
		move_and_slide()
		return

	var target = waypoints[_current_waypoint_idx]
	var dir = (target - global_position)
	dir.y = 0.0
	
	if dir.length() < 0.6:
		# Arrived at waypoint
		_is_waiting = true
		_wait_timer = 2.4
		_play_work_anim()
		velocity = Vector3.ZERO
	else:
		var move_dir = dir.normalized()
		velocity = move_dir * walk_speed
		# Smooth look-at target
		var target_rot_y = atan2(-move_dir.x, -move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_rot_y, 8.0 * delta)
		move_and_slide()

func _play_walk_anim() -> void:
	if _anim_player:
		if _anim_player.has_animation("Walking_A"):
			_anim_player.play("Walking_A")
		elif _anim_player.has_animation("Walking_B"):
			_anim_player.play("Walking_B")

func _play_work_anim() -> void:
	if _anim_player:
		if _anim_player.has_animation("PickUp"):
			_anim_player.play("PickUp")
		elif _anim_player.has_animation("Interact"):
			_anim_player.play("Interact")
		elif _anim_player.has_animation("Idle"):
			_anim_player.play("Idle")

func interact(player: Node) -> void:
	var dialogues = [
		"Stevedore Thatch: 'Mind your step on the slipway, Captain! These rum casks won't haul themselves!'",
		"Stevedore Thatch: 'Master Owen has been hammering at the drydock since dawn — heard he's forging ram prows!'",
		"Stevedore Thatch: 'Keep an eye on the southern reef, mate. Two smuggler sloops cracked their hulls out there!'"
	]
	var text = dialogues[randi() % dialogues.size()]
	HUD.show_notification(text)
	AudioManager.play_sfx("ui_switch")

func _find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root
	for child in root.get_children():
		var found = _find_animation_player(child)
		if found:
			return found
	return null
