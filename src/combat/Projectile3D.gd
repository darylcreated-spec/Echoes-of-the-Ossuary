extends Area3D
class_name Projectile3D

const Hurtbox3DScript = preload("res://src/combat/Hurtbox3D.gd")

@export var speed: float = 18.0
@export var damage: float = 24.0
@export var lifetime: float = 3.0
@export var is_enemy: bool = false
@export var is_crit: bool = false
@export var source_node: Node3D = null

var direction: Vector3 = Vector3.FORWARD
var _timer: float = 0.0

func _ready() -> void:
	monitoring = true
	monitorable = true
	
	# Layer 4 is player attack, Layer 5 is enemy attack
	collision_layer = (1 << 4) if is_enemy else (1 << 3)
	# Collides with layer 1 (walls), and opposite hurtbox layers
	collision_mask = 1 | ((1 << 1) if is_enemy else (1 << 2))
	
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	_create_visuals()

func _create_visuals() -> void:
	# Core energy sphere
	var mesh_inst = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.4
	mesh_inst.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	var col = Color(0.9, 0.2, 0.1) if is_enemy else Color(0.2, 0.85, 1.0)
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 3.5
	mesh_inst.material_override = mat
	add_child(mesh_inst)
	
	# Light
	var light = OmniLight3D.new()
	light.light_color = col
	light.light_energy = 2.0
	light.omni_range = 3.5
	add_child(light)
	
	# Collision Shape
	var col_shape = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.35
	col_shape.shape = shape
	add_child(col_shape)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_timer += delta
	if _timer >= lifetime:
		_impact(false)

func _on_area_entered(area: Area3D) -> void:
	if area is Hurtbox3DScript or area.has_signal("damage_received"):
		var hurtbox = area
		var owner_char = hurtbox.owner_character if ("owner_character" in hurtbox) else null
		var invuln = hurtbox.is_invulnerable if ("is_invulnerable" in hurtbox) else false
		if owner_char != source_node and not invuln:
			var kb = direction * 6.0
			hurtbox.damage_received.emit(damage, kb, is_crit, source_node)
			_impact(true)

func _on_body_entered(body: Node3D) -> void:
	if body != source_node:
		_impact(true)

func _impact(hit: bool) -> void:
	if hit:
		CombatJuice.spawn_hit_spark(global_position, Color(1.0, 0.4, 0.2) if is_enemy else Color(0.3, 0.9, 1.0))
		AudioManager.play_sfx("hit_flesh" if is_enemy else "sword_swing", 0.15, -4.0)
	queue_free()
