extends Area3D
class_name Projectile3D

const Hurtbox3DScript = preload("res://src/combat/Hurtbox3D.gd")

enum ProjectileType { ENERGY_ORB, ARROW, CROSSBOW_BOLT }

@export var projectile_type: ProjectileType = ProjectileType.ENERGY_ORB
@export var speed: float = 18.0
@export var damage: float = 24.0
@export var lifetime: float = 3.0
@export var is_enemy: bool = false
@export var is_crit: bool = false
@export var source_node: Node3D = null
var damage_source: Node3D:
	get: return source_node
	set(v): source_node = v

var direction: Vector3 = Vector3.FORWARD
var _timer: float = 0.0
var _visual_root: Node3D = null

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
	
	if direction != Vector3.ZERO:
		look_at(global_position + direction, Vector3.UP)

func _create_visuals() -> void:
	_visual_root = Node3D.new()
	_visual_root.name = "Visuals"
	add_child(_visual_root)
	
	match projectile_type:
		ProjectileType.ARROW:
			_create_arrow_visuals()
		ProjectileType.CROSSBOW_BOLT:
			_create_crossbow_bolt_visuals()
		ProjectileType.ENERGY_ORB:
			_create_energy_orb_visuals()

	# Collision Shape
	var col_shape = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.32
	col_shape.shape = shape
	add_child(col_shape)

func _create_arrow_visuals() -> void:
	# 1. Wooden Arrow Shaft (Ash / Cedar timber, length 0.75m)
	var shaft_inst = MeshInstance3D.new()
	shaft_inst.name = "Shaft"
	var shaft_cyl = CylinderMesh.new()
	shaft_cyl.top_radius = 0.016
	shaft_cyl.bottom_radius = 0.016
	shaft_cyl.height = 0.72
	shaft_inst.mesh = shaft_cyl
	shaft_inst.rotation_degrees.x = 90.0
	shaft_inst.position.z = -0.04
	
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.48, 0.32, 0.18) # Warm medieval wood
	wood_mat.roughness = 0.85
	shaft_inst.material_override = wood_mat
	_visual_root.add_child(shaft_inst)

	# 2. Steel Bodkin / Broadhead Arrowhead (pointed forward at -Z)
	var head_inst = MeshInstance3D.new()
	head_inst.name = "Arrowhead"
	var head_cone = CylinderMesh.new()
	head_cone.top_radius = 0.001
	head_cone.bottom_radius = 0.042
	head_cone.height = 0.14
	head_inst.mesh = head_cone
	head_inst.rotation_degrees.x = -90.0
	head_inst.position.z = -0.45
	
	var steel_mat = StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.82, 0.85, 0.90) # Polished bodkin iron
	steel_mat.metallic = 0.92
	steel_mat.roughness = 0.22
	head_inst.material_override = steel_mat
	_visual_root.add_child(head_inst)

	# 3. Feathered Fletchings (3 aerodynamic radial vanes at tail +Z)
	var fletch_mat = StandardMaterial3D.new()
	fletch_mat.albedo_color = Color(0.96, 0.94, 0.90) # Swan/goose white fletch
	fletch_mat.roughness = 0.7
	
	for i in range(3):
		var fin = MeshInstance3D.new()
		fin.name = "Fletch_" + str(i)
		var box = BoxMesh.new()
		box.size = Vector3(0.006, 0.052, 0.14)
		fin.mesh = box
		fin.material_override = fletch_mat
		fin.position.z = 0.24
		fin.rotation_degrees.z = i * 120.0
		_visual_root.add_child(fin)

	# 4. Subtle Wind Vapor Trail
	var trail = GPUParticles3D.new()
	trail.name = "ArrowTrail"
	trail.amount = 14
	trail.lifetime = 0.18
	trail.position.z = 0.32
	
	var p_mat = ParticleProcessMaterial.new()
	p_mat.direction = Vector3(0, 0, 1)
	p_mat.spread = 5.0
	p_mat.initial_velocity_min = 0.8
	p_mat.initial_velocity_max = 1.6
	p_mat.scale_min = 0.04
	p_mat.scale_max = 0.08
	p_mat.color = Color(0.9, 0.95, 1.0, 0.45)
	trail.process_material = p_mat
	
	var t_mesh = SphereMesh.new()
	t_mesh.radius = 0.03
	t_mesh.height = 0.06
	var tm = StandardMaterial3D.new()
	tm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tm.albedo_color = Color(0.9, 0.95, 1.0, 0.35)
	t_mesh.material = tm
	trail.draw_pass_1 = t_mesh
	_visual_root.add_child(trail)

func _create_crossbow_bolt_visuals() -> void:
	# Heavy steel quarrel bolt
	var shaft_inst = MeshInstance3D.new()
	shaft_inst.name = "BoltShaft"
	var shaft_cyl = CylinderMesh.new()
	shaft_cyl.top_radius = 0.02
	shaft_cyl.bottom_radius = 0.02
	shaft_cyl.height = 0.45
	shaft_inst.mesh = shaft_cyl
	shaft_inst.rotation_degrees.x = 90.0
	
	var iron_mat = StandardMaterial3D.new()
	iron_mat.albedo_color = Color(0.42, 0.44, 0.48)
	iron_mat.metallic = 0.8
	iron_mat.roughness = 0.35
	shaft_inst.material_override = iron_mat
	_visual_root.add_child(shaft_inst)

	var head_inst = MeshInstance3D.new()
	head_inst.name = "BoltHead"
	var head_cone = CylinderMesh.new()
	head_cone.top_radius = 0.001
	head_cone.bottom_radius = 0.05
	head_cone.height = 0.12
	head_inst.mesh = head_cone
	head_inst.rotation_degrees.x = -90.0
	head_inst.position.z = -0.28
	head_inst.material_override = iron_mat
	_visual_root.add_child(head_inst)

func _create_energy_orb_visuals() -> void:
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
	_visual_root.add_child(mesh_inst)
	
	# Light
	var light = OmniLight3D.new()
	light.light_color = col
	light.light_energy = 2.0
	light.omni_range = 3.5
	_visual_root.add_child(light)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	if direction != Vector3.ZERO:
		look_at(global_position + direction, Vector3.UP)
	_timer += delta
	if _timer >= lifetime:
		_impact(false)

func _on_area_entered(area: Area3D) -> void:
	if area is Hurtbox3DScript or area.has_signal("damage_received"):
		var hurtbox = area
		var owner_char = hurtbox.owner_character if ("owner_character" in hurtbox) else null
		var invuln = hurtbox.is_invulnerable if ("is_invulnerable" in hurtbox) else false
		if owner_char != source_node and not invuln:
			var kb = direction * (7.0 if projectile_type == ProjectileType.ARROW else 6.0)
			hurtbox.damage_received.emit(damage, kb, is_crit, source_node)
			_impact(true)

func _on_body_entered(body: Node3D) -> void:
	if body != source_node:
		_impact(true)

func _impact(hit: bool) -> void:
	if hit:
		if projectile_type == ProjectileType.ARROW:
			AudioManager.play_sfx("arrow_impact", 0.12, -3.0)
			CombatJuice.spawn_hit_spark(global_position, Color(1.0, 0.85, 0.5))
		elif projectile_type == ProjectileType.CROSSBOW_BOLT:
			AudioManager.play_sfx("arrow_impact", 0.08, -2.5)
			CombatJuice.spawn_hit_spark(global_position, Color(0.9, 0.9, 0.95))
		else:
			CombatJuice.spawn_hit_spark(global_position, Color(1.0, 0.4, 0.2) if is_enemy else Color(0.3, 0.9, 1.0))
			AudioManager.play_sfx("hit_flesh" if is_enemy else "sword_swing", 0.15, -4.0)
	queue_free()
