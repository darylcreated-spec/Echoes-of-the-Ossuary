extends Node3D
class_name InteractiveTarget3D

@export var target_name: String = "Archery Target"
@export var base_gold_reward: int = 2

var _target_mesh: Node3D = null
var _wobble_time: float = 0.0
var _wobble_amplitude: float = 0.0
var _hit_count: int = 0
var _spring_velocity: float = 0.0
var _current_tilt: float = 0.0

func _ready() -> void:
	add_to_group("archery_target")
	_build_target_mesh()
	_setup_hurtbox()

func _build_target_mesh() -> void:
	var model_path = "res://assets/overworld/target.gltf"
	if ResourceLoader.exists(model_path):
		var scn = load(model_path)
		if scn:
			_target_mesh = scn.instantiate()
			_target_mesh.scale = Vector3.ONE * 1.8
			add_child(_target_mesh)
	
	if not _target_mesh:
		# Procedural straw target fallback
		_target_mesh = Node3D.new()
		var disc = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 0.65
		cm.bottom_radius = 0.65
		cm.height = 0.15
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.85, 0.72, 0.45)
		cm.material = mat
		disc.mesh = cm
		disc.rotation_degrees.x = 90.0
		disc.position.y = 1.3
		_target_mesh.add_child(disc)
		add_child(_target_mesh)

func _setup_hurtbox() -> void:
	var hurtbox = Area3D.new()
	hurtbox.name = "Hurtbox3D"
	# Hurtbox layer 4 (Enemy/Target hurtbox), listens to Layer 8 (Player Hitbox) & Projectiles
	hurtbox.collision_layer = 4
	hurtbox.collision_mask = 8 | 16
	
	var HurtboxScript = load("res://src/combat/Hurtbox3D.gd")
	if HurtboxScript:
		hurtbox.set_script(HurtboxScript)
		hurtbox.set("owner_character", self)
		
	var cs = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(1.3, 1.8, 0.8)
	cs.shape = box
	cs.position.y = 1.1
	hurtbox.add_child(cs)
	add_child(hurtbox)
	
	if hurtbox.has_signal("damage_received"):
		hurtbox.damage_received.connect(_on_damage_received)

func _physics_process(delta: float) -> void:
	if _target_mesh and abs(_current_tilt) > 0.001 or abs(_spring_velocity) > 0.001:
		# Damped harmonic oscillator (spring physics wobble)
		var spring_k = 180.0
		var damping = 12.0
		var spring_force = -spring_k * _current_tilt
		var damping_force = -damping * _spring_velocity
		_spring_velocity += (spring_force + damping_force) * delta
		_current_tilt += _spring_velocity * delta
		_target_mesh.rotation_degrees.x = _current_tilt

func _on_damage_received(amount: float, knockback: Vector3, is_crit: bool, _source: Node3D) -> void:
	_hit_count += 1
	var impact_power = clamp(amount * 0.45, 12.0, 38.0)
	_spring_velocity -= impact_power * 10.0
	
	var height_ratio = randf()
	var score_str = "🎯 OUTER RING! +25 PTS"
	var text_col = Color(0.9, 0.9, 0.9)
	var pts = 25
	
	if is_crit or height_ratio > 0.7:
		score_str = "🎯 BULLSEYE! +100 PTS!"
		text_col = Color(1.0, 0.85, 0.2)
		pts = 100
		GameManager.add_gold(base_gold_reward + 2)
	elif height_ratio > 0.35:
		score_str = "🎯 INNER RING! +50 PTS"
		text_col = Color(0.3, 0.9, 1.0)
		pts = 50
		GameManager.add_gold(base_gold_reward)
	else:
		GameManager.add_gold(1)

	# Combat Juice feedback
	CombatJuice.show_popup_text(global_position + Vector3(0, 2.0, 0), score_str, text_col)
	CombatJuice.spawn_hit_spark(global_position + Vector3(0, 1.3, 0), Color(0.95, 0.80, 0.3))
	AudioManager.play_sfx("wood_chop", 0.08, 0.35)
	
	if pts == 100:
		AudioManager.play_sfx("gold_pickup", 0.06, 1.2)
